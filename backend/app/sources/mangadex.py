from datetime import datetime
from typing import Any
from urllib.parse import quote

import httpx

from app.schemas import SourceChapterOut, SourceMangaOut, SourcePageOut
from app.sources.base import SourceError


class MangaDexProvider:
    source_id = "mangadex"
    name = "MangaDex"

    def __init__(self, client: httpx.Client | None = None) -> None:
        self._client = client or httpx.Client(
            base_url="https://api.mangadex.org",
            headers={"User-Agent": "Oleitor/0.1.0"},
            timeout=10.0,
        )

    def search(
        self,
        query: str,
        limit: int,
        offset: int,
        language: str | None,
    ) -> list[SourceMangaOut]:
        params: list[tuple[str, str]] = [
            ("title", query),
            ("limit", str(limit)),
            ("offset", str(offset)),
            ("includes[]", "author"),
            ("includes[]", "artist"),
            ("includes[]", "cover_art"),
            ("contentRating[]", "safe"),
            ("contentRating[]", "suggestive"),
        ]
        if language:
            params.append(("availableTranslatedLanguage[]", language))

        data = self._request("/manga", params)
        return [self._manga_from_item(item) for item in self._items(data)]

    def list_chapters(
        self,
        manga_id: str,
        limit: int,
        offset: int,
        language: str | None,
    ) -> list[SourceChapterOut]:
        params: list[tuple[str, str]] = [
            ("limit", str(limit)),
            ("offset", str(offset)),
            ("order[chapter]", "asc"),
            ("includes[]", "scanlation_group"),
        ]
        if language:
            params.append(("translatedLanguage[]", language))

        data = self._request(f"/manga/{manga_id}/feed", params)
        return [
            self._chapter_from_item(item, manga_id) for item in self._items(data)
        ]

    def get_pages(self, chapter_id: str) -> list[SourcePageOut]:
        data = self._request(f"/at-home/server/{chapter_id}")
        chapter = data.get("chapter")
        if not isinstance(chapter, dict):
            raise SourceError("Resposta inválida do MangaDex: capítulo ausente.")

        base_url = data.get("baseUrl")
        chapter_hash = chapter.get("hash")
        filenames = chapter.get("data")
        if (
            not isinstance(base_url, str)
            or not isinstance(chapter_hash, str)
            or not isinstance(filenames, list)
            or not filenames
            or not all(isinstance(filename, str) for filename in filenames)
        ):
            raise SourceError("Resposta inválida do MangaDex: páginas ausentes.")

        return [
            SourcePageOut(
                number=number,
                image_url=(
                    f"{base_url}/data/{quote(chapter_hash, safe='')}/"
                    f"{quote(filename, safe='')}"
                ),
            )
            for number, filename in enumerate(filenames, start=1)
        ]

    def _request(
        self,
        path: str,
        params: list[tuple[str, str]] | None = None,
    ) -> dict[str, Any]:
        try:
            response = self._client.get(path, params=params)
        except httpx.RequestError as exc:
            raise SourceError("Não foi possível conectar ao MangaDex.") from exc

        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise SourceError(
                f"O MangaDex respondeu com HTTP {exc.response.status_code}."
            ) from exc

        try:
            payload = response.json()
        except ValueError as exc:
            raise SourceError("O MangaDex retornou uma resposta inválida.") from exc

        if not isinstance(payload, dict):
            raise SourceError("O MangaDex retornou uma resposta inválida.")
        return payload

    @staticmethod
    def _items(payload: dict[str, Any]) -> list[dict[str, Any]]:
        items = payload.get("data")
        if not isinstance(items, list) or not all(
            isinstance(item, dict) for item in items
        ):
            raise SourceError("O MangaDex retornou uma lista inválida.")
        return items

    @classmethod
    def _manga_from_item(cls, item: dict[str, Any]) -> SourceMangaOut:
        manga_id = item.get("id")
        attributes = item.get("attributes")
        relationships = item.get("relationships", [])
        if (
            not isinstance(manga_id, str)
            or not isinstance(attributes, dict)
            or not isinstance(relationships, list)
        ):
            raise SourceError("O MangaDex retornou dados inválidos de mangá.")

        title = cls._localized_text(attributes.get("title"))
        if title is None:
            raise SourceError("O MangaDex retornou um mangá sem título.")
        description = cls._localized_text(attributes.get("description"))
        authors: list[str] = []
        cover_filename: str | None = None
        for relationship in relationships:
            if not isinstance(relationship, dict):
                continue
            related_attributes = relationship.get("attributes")
            if not isinstance(related_attributes, dict):
                continue
            if relationship.get("type") in {"author", "artist"}:
                author_name = related_attributes.get("name")
                if isinstance(author_name, str) and author_name not in authors:
                    authors.append(author_name)
            if relationship.get("type") == "cover_art":
                filename = related_attributes.get("fileName")
                if isinstance(filename, str):
                    cover_filename = filename

        cover_url = None
        if cover_filename:
            cover_url = (
                f"https://uploads.mangadex.org/covers/{quote(manga_id, safe='')}/"
                f"{quote(cover_filename, safe='')}.256.jpg"
            )

        return SourceMangaOut(
            source_id="mangadex",
            source_manga_id=manga_id,
            title=title,
            description=description,
            cover_url=cover_url,
            source_url=f"https://mangadex.org/title/{quote(manga_id, safe='')}",
            authors=authors,
            language=cls._optional_text(attributes.get("originalLanguage")),
            status=cls._optional_text(attributes.get("status")),
        )

    @classmethod
    def _chapter_from_item(
        cls,
        item: dict[str, Any],
        manga_id: str,
    ) -> SourceChapterOut:
        chapter_id = item.get("id")
        attributes = item.get("attributes")
        if not isinstance(chapter_id, str) or not isinstance(attributes, dict):
            raise SourceError("O MangaDex retornou dados inválidos de capítulo.")

        chapter_number = cls._optional_text(attributes.get("chapter"))
        title = cls._optional_text(attributes.get("title"))
        if not title:
            title = f"Capítulo {chapter_number}" if chapter_number else "Capítulo extra"
        page_count = attributes.get("pages")
        if isinstance(page_count, bool) or not isinstance(page_count, int) or page_count < 0:
            raise SourceError("O MangaDex retornou uma quantidade de páginas inválida.")

        return SourceChapterOut(
            source_id="mangadex",
            source_chapter_id=chapter_id,
            manga_id=manga_id,
            title=title,
            number=chapter_number,
            language=cls._optional_text(attributes.get("translatedLanguage")),
            page_count=page_count,
            published_at=cls._published_at(attributes.get("publishAt")),
            source_url=f"https://mangadex.org/chapter/{quote(chapter_id, safe='')}",
        )

    @staticmethod
    def _localized_text(value: Any) -> str | None:
        if not isinstance(value, dict):
            return None
        for language in ("pt-br", "pt", "en"):
            text = value.get(language)
            if isinstance(text, str) and text.strip():
                return text.strip()
        for text in value.values():
            if isinstance(text, str) and text.strip():
                return text.strip()
        return None

    @staticmethod
    def _optional_text(value: Any) -> str | None:
        return value if isinstance(value, str) and value else None

    @staticmethod
    def _published_at(value: Any) -> datetime | None:
        if value is None:
            return None
        if not isinstance(value, str):
            raise SourceError("O MangaDex retornou uma data inválida.")
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError as exc:
            raise SourceError("O MangaDex retornou uma data inválida.") from exc
