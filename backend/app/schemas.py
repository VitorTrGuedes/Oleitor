from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class MangaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    author: str | None
    description: str | None
    cover_url: str | None
    language: str
    created_at: datetime
    updated_at: datetime


class ChapterOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    manga_id: str
    title: str
    number: int
    created_at: datetime
    updated_at: datetime


class PageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    chapter_id: str
    number: int
    image_url: str


class ProgressUpdate(BaseModel):
    manga_id: UUID
    chapter_id: UUID
    page_number: int = Field(ge=1)


class ProgressOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    manga_id: str
    chapter_id: str
    page_number: int
    updated_at: datetime


class ReadEventCreate(BaseModel):
    source_id: str = Field(min_length=1, max_length=50)
    manga_id: str = Field(min_length=1, max_length=128)
    title: str = Field(min_length=1, max_length=200)
    author: str | None = Field(default=None, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    cover_url: HttpUrl | None = None
    source_url: HttpUrl | None = None
    language: str = Field(default="pt-BR", max_length=16)
    supports_reading: bool = True


class ReadEventResult(BaseModel):
    recorded: bool


class PopularMangaOut(BaseModel):
    id: str
    title: str
    author: str | None
    description: str | None
    cover_url: HttpUrl | None
    language: str
    source_id: str | None
    source_manga_id: str | None
    source_url: HttpUrl | None
    supports_reading: bool
    read_count: int


class RecommendationRequest(BaseModel):
    favorite_titles: list[Annotated[str, Field(min_length=1, max_length=200)]] = (
        Field(min_length=1, max_length=5)
    )


class SourceOut(BaseModel):
    id: str
    name: str
    supports_reading: bool
    supports_language_filter: bool


class SourceMangaOut(BaseModel):
    source_id: str
    source_manga_id: str
    supports_reading: bool
    title: str
    description: str | None
    cover_url: str | None
    source_url: HttpUrl
    authors: list[str]
    language: str | None
    status: str | None


class SourceChapterOut(BaseModel):
    source_id: str
    source_chapter_id: str
    manga_id: str
    title: str
    number: str | None
    language: str | None
    page_count: int
    published_at: datetime | None
    source_url: HttpUrl


class SourcePageOut(BaseModel):
    number: int
    image_url: HttpUrl


class DemoPage(BaseModel):
    number: int = Field(ge=1)
    image_url: HttpUrl


class DemoChapter(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    number: int = Field(ge=1)
    pages: list[DemoPage] = Field(min_length=1)


class DemoManga(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    author: str | None = Field(default=None, max_length=200)
    description: str | None = Field(default=None, max_length=4000)
    cover_url: HttpUrl | None = None
    language: str = Field(default="pt-BR", max_length=16)
    chapters: list[DemoChapter] = Field(min_length=1)
