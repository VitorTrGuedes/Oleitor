from typing import Protocol

from app.schemas import SourceChapterOut, SourceMangaOut, SourcePageOut


class SourceError(RuntimeError):
    pass


class SourceProvider(Protocol):
    source_id: str
    name: str
    supports_reading: bool
    supports_language_filter: bool

    def search(
        self,
        query: str,
        limit: int,
        offset: int,
        language: str | None,
    ) -> list[SourceMangaOut]: ...

    def list_chapters(
        self,
        manga_id: str,
        limit: int,
        offset: int,
        language: str | None,
    ) -> list[SourceChapterOut]: ...

    def get_pages(self, chapter_id: str) -> list[SourcePageOut]: ...
