import logging
from typing import Annotated
from uuid import UUID

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import Base, engine, get_db
from app.models import Chapter, Manga, Page, ReadingProgress
from app.schemas import (
    ChapterOut,
    MangaOut,
    PageOut,
    ProgressOut,
    ProgressUpdate,
    SourceChapterOut,
    SourceMangaOut,
    SourceOut,
    SourcePageOut,
)
from app.sources import source_registry
from app.sources.base import SourceError, SourceProvider

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Oleitor API", version="0.1.0")
DbSession = Annotated[Session, Depends(get_db)]
DeviceId = Annotated[str, Header(alias="X-Device-Id", min_length=1, max_length=128)]
logger = logging.getLogger(__name__)


def get_source_provider(source_id: str) -> SourceProvider:
    try:
        return source_registry.get(source_id)
    except KeyError as exc:
        raise HTTPException(status_code=404, detail="Fonte não encontrada") from exc


Source = Annotated[SourceProvider, Depends(get_source_provider)]


def source_failure(provider: SourceProvider, error: SourceError) -> HTTPException:
    logger.warning("Falha ao consultar a fonte %s: %s", provider.source_id, error)
    return HTTPException(
        status_code=502,
        detail=f"A fonte {provider.name} está indisponível no momento.",
    )


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/v1/sources", response_model=list[SourceOut])
def list_sources() -> list[SourceOut]:
    return [
        SourceOut(id=provider.source_id, name=provider.name)
        for provider in source_registry.list()
    ]


@app.get(
    "/api/v1/sources/{source_id}/manga",
    response_model=list[SourceMangaOut],
)
def search_source_manga(
    provider: Source,
    search: Annotated[str, Query(min_length=1, max_length=200)],
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    language: Annotated[str | None, Query(min_length=2, max_length=10)] = None,
) -> list[SourceMangaOut]:
    query = search.strip()
    if not query:
        return []
    try:
        return provider.search(query, limit, skip, language)
    except SourceError as exc:
        raise source_failure(provider, exc) from exc


@app.get(
    "/api/v1/sources/{source_id}/manga/{manga_id}/chapters",
    response_model=list[SourceChapterOut],
)
def list_source_chapters(
    provider: Source,
    manga_id: UUID,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 100,
    language: Annotated[str | None, Query(min_length=2, max_length=10)] = "pt-br",
) -> list[SourceChapterOut]:
    try:
        return provider.list_chapters(str(manga_id), limit, skip, language)
    except SourceError as exc:
        raise source_failure(provider, exc) from exc


@app.get(
    "/api/v1/sources/{source_id}/chapters/{chapter_id}/pages",
    response_model=list[SourcePageOut],
)
def list_source_pages(
    provider: Source,
    chapter_id: UUID,
) -> list[SourcePageOut]:
    try:
        return provider.get_pages(str(chapter_id))
    except SourceError as exc:
        raise source_failure(provider, exc) from exc


@app.get("/api/v1/manga", response_model=list[MangaOut])
def list_manga(
    db: DbSession,
    search: Annotated[str | None, Query(max_length=200)] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> list[Manga]:
    statement = select(Manga).order_by(Manga.title).offset(skip).limit(limit)
    if search and search.strip():
        statement = statement.where(Manga.title.ilike(f"%{search.strip()}%"))
    return list(db.scalars(statement))


@app.get("/api/v1/manga/{manga_id}", response_model=MangaOut)
def get_manga(manga_id: UUID, db: DbSession) -> Manga:
    manga = db.get(Manga, str(manga_id))
    if manga is None:
        raise HTTPException(status_code=404, detail="Mangá não encontrado")
    return manga


@app.get("/api/v1/manga/{manga_id}/chapters", response_model=list[ChapterOut])
def list_chapters(manga_id: UUID, db: DbSession) -> list[Chapter]:
    manga_id = str(manga_id)
    if db.get(Manga, manga_id) is None:
        raise HTTPException(status_code=404, detail="Mangá não encontrado")
    statement = select(Chapter).where(Chapter.manga_id == manga_id).order_by(Chapter.number)
    return list(db.scalars(statement))


@app.get("/api/v1/chapters/{chapter_id}/pages", response_model=list[PageOut])
def list_pages(chapter_id: UUID, db: DbSession) -> list[Page]:
    chapter_id = str(chapter_id)
    if db.get(Chapter, chapter_id) is None:
        raise HTTPException(status_code=404, detail="Capítulo não encontrado")
    statement = select(Page).where(Page.chapter_id == chapter_id).order_by(Page.number)
    return list(db.scalars(statement))


@app.get("/api/v1/reading-progress", response_model=list[ProgressOut])
def list_progress(device_id: DeviceId, db: DbSession) -> list[ReadingProgress]:
    statement = (
        select(ReadingProgress)
        .where(ReadingProgress.device_id == device_id)
        .order_by(ReadingProgress.updated_at.desc())
    )
    return list(db.scalars(statement))


@app.put("/api/v1/reading-progress", response_model=ProgressOut)
def save_progress(
    progress: ProgressUpdate,
    device_id: DeviceId,
    db: DbSession,
) -> ReadingProgress:
    manga_id = str(progress.manga_id)
    chapter_id = str(progress.chapter_id)
    manga = db.get(Manga, manga_id)
    chapter = db.get(Chapter, chapter_id)
    if manga is None or chapter is None or chapter.manga_id != manga_id:
        raise HTTPException(status_code=404, detail="Mangá ou capítulo não encontrado")
    page_exists = db.scalar(
        select(Page.id).where(
            Page.chapter_id == chapter_id,
            Page.number == progress.page_number,
        )
    )
    if page_exists is None:
        raise HTTPException(status_code=422, detail="A página não existe neste capítulo")

    statement = select(ReadingProgress).where(
        ReadingProgress.device_id == device_id,
        ReadingProgress.manga_id == manga_id,
    )
    stored = db.scalar(statement)
    if stored is None:
        stored = ReadingProgress(device_id=device_id, manga_id=manga_id)
        db.add(stored)
    stored.chapter_id = chapter_id
    stored.page_number = progress.page_number
    db.commit()
    db.refresh(stored)
    return stored
