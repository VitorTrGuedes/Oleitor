import logging
from typing import Annotated
from uuid import UUID

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import settings
from app.database import Base, engine, get_db
from app.models import Chapter, Manga, Page, ReadingEvent, ReadingProgress
from app.schemas import (
    ChapterOut,
    MangaOut,
    PageOut,
    PopularMangaOut,
    ProgressOut,
    ProgressUpdate,
    ReadEventCreate,
    ReadEventResult,
    RecommendationRequest,
    SourceChapterOut,
    SourceMangaOut,
    SourceOut,
    SourcePageOut,
)
from app.sources import source_registry
from app.sources.anilist import AniListProvider
from app.sources.base import SourceError, SourceProvider

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Oleitor API", version="0.1.0")
if settings.environment == "development":
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_methods=["*"],
        allow_headers=["*"],
    )
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
        SourceOut(
            id=provider.source_id,
            name=provider.name,
            supports_reading=provider.supports_reading,
            supports_language_filter=provider.supports_language_filter,
        )
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


def ensure_source_supports_reading(provider: SourceProvider) -> None:
    if not provider.supports_reading:
        raise HTTPException(
            status_code=409,
            detail=f"A fonte {provider.name} oferece catálogo, mas não capítulos para leitura.",
        )


@app.get(
    "/api/v1/sources/{source_id}/manga/{manga_id}/chapters",
    response_model=list[SourceChapterOut],
)
def list_source_chapters(
    provider: Source,
    manga_id: str,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=100)] = 100,
    language: Annotated[str | None, Query(min_length=2, max_length=10)] = "pt-br",
) -> list[SourceChapterOut]:
    ensure_source_supports_reading(provider)
    try:
        return provider.list_chapters(manga_id, limit, skip, language)
    except SourceError as exc:
        raise source_failure(provider, exc) from exc


@app.get(
    "/api/v1/sources/{source_id}/chapters/{chapter_id}/pages",
    response_model=list[SourcePageOut],
)
def list_source_pages(
    provider: Source,
    chapter_id: str,
) -> list[SourcePageOut]:
    ensure_source_supports_reading(provider)
    try:
        return provider.get_pages(chapter_id)
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


@app.post("/api/v1/reading-events", response_model=ReadEventResult)
def record_read_event(
    event: ReadEventCreate,
    device_id: DeviceId,
    db: DbSession,
) -> ReadEventResult:
    if event.source_id == "library":
        manga = db.get(Manga, event.manga_id)
        if manga is None:
            raise HTTPException(status_code=404, detail="Mangá não encontrado")
        source_id = "library"
        manga_id = manga.id
        values = {
            "title": manga.title,
            "author": manga.author,
            "description": manga.description,
            "cover_url": manga.cover_url,
            "source_url": None,
            "language": manga.language,
            "supports_reading": True,
        }
    else:
        try:
            provider = source_registry.get(event.source_id)
        except KeyError as exc:
            raise HTTPException(status_code=404, detail="Fonte não encontrada") from exc
        if not provider.supports_reading:
            raise HTTPException(
                status_code=409,
                detail=f"A fonte {provider.name} não oferece leitura.",
            )
        source_id = provider.source_id
        manga_id = event.manga_id
        values = {
            "title": event.title,
            "author": event.author,
            "description": event.description,
            "cover_url": str(event.cover_url) if event.cover_url else None,
            "source_url": str(event.source_url) if event.source_url else None,
            "language": event.language,
            "supports_reading": provider.supports_reading,
        }

    existing = db.scalar(
        select(ReadingEvent.id).where(
            ReadingEvent.device_id == device_id,
            ReadingEvent.source_id == source_id,
            ReadingEvent.manga_id == manga_id,
        )
    )
    if existing is not None:
        return ReadEventResult(recorded=False)

    try:
        db.add(
            ReadingEvent(
                device_id=device_id,
                source_id=source_id,
                manga_id=manga_id,
                **values,
            )
        )
        db.commit()
    except IntegrityError:
        db.rollback()
        existing = db.scalar(
            select(ReadingEvent.id).where(
                ReadingEvent.device_id == device_id,
                ReadingEvent.source_id == source_id,
                ReadingEvent.manga_id == manga_id,
            )
        )
        if existing is None:
            raise
        return ReadEventResult(recorded=False)
    return ReadEventResult(recorded=True)


@app.get("/api/v1/popular-manga", response_model=list[PopularMangaOut])
def list_popular_manga(
    db: DbSession,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> list[PopularMangaOut]:
    read_count = func.count(ReadingEvent.id)
    statement = (
        select(
            ReadingEvent.source_id,
            ReadingEvent.manga_id,
            func.min(ReadingEvent.title).label("title"),
            func.min(ReadingEvent.author).label("author"),
            func.min(ReadingEvent.description).label("description"),
            func.min(ReadingEvent.cover_url).label("cover_url"),
            func.min(ReadingEvent.source_url).label("source_url"),
            func.min(ReadingEvent.language).label("language"),
            func.min(ReadingEvent.supports_reading).label("supports_reading"),
            read_count.label("read_count"),
        )
        .group_by(ReadingEvent.source_id, ReadingEvent.manga_id)
        .order_by(read_count.desc(), func.min(ReadingEvent.title))
        .limit(limit)
    )
    results = []
    for row in db.execute(statement):
        is_library_manga = row.source_id == "library"
        results.append(
            PopularMangaOut(
                id=row.manga_id,
                title=row.title,
                author=row.author,
                description=row.description,
                cover_url=row.cover_url,
                language=row.language,
                source_id=None if is_library_manga else row.source_id,
                source_manga_id=None if is_library_manga else row.manga_id,
                source_url=row.source_url,
                supports_reading=row.supports_reading,
                read_count=row.read_count,
            )
        )
    return results


@app.post("/api/v1/recommendations", response_model=list[SourceMangaOut])
def list_recommendations(
    request: RecommendationRequest,
) -> list[SourceMangaOut]:
    provider = source_registry.get("anilist")
    if not isinstance(provider, AniListProvider):
        raise HTTPException(
            status_code=503,
            detail="O serviço de recomendações não está disponível.",
        )
    try:
        return provider.recommendations(request.favorite_titles, limit=20)
    except SourceError as exc:
        raise source_failure(provider, exc) from exc


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
