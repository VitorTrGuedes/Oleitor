import html
import re
from typing import Any

import httpx

from app.schemas import SourceChapterOut, SourceMangaOut, SourcePageOut
from app.sources.base import SourceError


_SEARCH_QUERY = """
query ($search: String!, $page: Int!, $perPage: Int!) {
  Page(page: $page, perPage: $perPage) {
    media(search: $search, type: MANGA, isAdult: false) {
      id
      title {
        english
        romaji
        native
      }
      description(asHtml: false)
      coverImage {
        extraLarge
        large
      }
      siteUrl
      countryOfOrigin
      status
    }
  }
}
"""

_RECOMMENDATIONS_QUERY = """
query ($search: String!, $perPage: Int!) {
  Page(page: 1, perPage: 1) {
    media(search: $search, type: MANGA, isAdult: false) {
      recommendations(perPage: $perPage, sort: RATING_DESC) {
        nodes {
          mediaRecommendation {
            id
            title {
              english
              romaji
              native
            }
            description(asHtml: false)
            coverImage {
              extraLarge
              large
            }
            siteUrl
            countryOfOrigin
            status
          }
        }
      }
    }
  }
}
"""


class AniListProvider:
    source_id = "anilist"
    name = "AniList (catálogo)"
    supports_reading = False
    supports_language_filter = False

    def __init__(self, client: httpx.Client | None = None) -> None:
        self._client = client or httpx.Client(
            base_url="https://graphql.anilist.co",
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
        page_size = min(limit, 50)
        payload = self._request(
            {
                "query": _SEARCH_QUERY,
                "variables": {
                    "search": query,
                    "page": offset // page_size + 1,
                    "perPage": page_size,
                },
            }
        )
        data = payload.get("data")
        page = data.get("Page") if isinstance(data, dict) else None
        media = page.get("media") if isinstance(page, dict) else None
        if not isinstance(media, list) or not all(
            isinstance(item, dict) for item in media
        ):
            raise SourceError("O AniList retornou uma lista de títulos inválida.")
        return [self._manga_from_item(item) for item in media]

    def recommendations(
        self,
        favorite_titles: list[str],
        limit: int,
    ) -> list[SourceMangaOut]:
        results: list[SourceMangaOut] = []
        seen_ids: set[str] = set()
        for title in favorite_titles:
            remaining = limit - len(results)
            if remaining <= 0:
                break
            payload = self._request(
                {
                    "query": _RECOMMENDATIONS_QUERY,
                    "variables": {
                        "search": title,
                        "perPage": min(remaining, 10),
                    },
                }
            )
            data = payload.get("data")
            page = data.get("Page") if isinstance(data, dict) else None
            media = page.get("media") if isinstance(page, dict) else None
            if not isinstance(media, list) or not all(
                isinstance(item, dict) for item in media
            ):
                raise SourceError("O AniList retornou recomendações inválidas.")
            if not media:
                continue
            recommendations = media[0].get("recommendations")
            if not isinstance(recommendations, dict):
                continue
            nodes = recommendations.get("nodes")
            if not isinstance(nodes, list):
                raise SourceError("O AniList retornou recomendações inválidas.")
            for node in nodes:
                recommendation = (
                    node.get("mediaRecommendation")
                    if isinstance(node, dict)
                    else None
                )
                if not isinstance(recommendation, dict):
                    continue
                manga = self._manga_from_item(recommendation)
                if manga.source_manga_id in seen_ids:
                    continue
                seen_ids.add(manga.source_manga_id)
                results.append(manga)
                if len(results) >= limit:
                    break
        return results

    def list_chapters(
        self,
        manga_id: str,
        limit: int,
        offset: int,
        language: str | None,
    ) -> list[SourceChapterOut]:
        raise SourceError("O AniList disponibiliza apenas dados de catálogo.")

    def get_pages(self, chapter_id: str) -> list[SourcePageOut]:
        raise SourceError("O AniList não disponibiliza páginas para leitura.")

    def _request(self, body: dict[str, Any]) -> dict[str, Any]:
        try:
            response = self._client.post("/", json=body)
        except httpx.RequestError as exc:
            raise SourceError("Não foi possível conectar ao AniList.") from exc

        try:
            response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            raise SourceError(
                f"O AniList respondeu com HTTP {exc.response.status_code}."
            ) from exc

        try:
            payload = response.json()
        except ValueError as exc:
            raise SourceError("O AniList retornou uma resposta inválida.") from exc

        if not isinstance(payload, dict):
            raise SourceError("O AniList retornou uma resposta inválida.")
        if payload.get("errors"):
            raise SourceError("O AniList retornou um erro na consulta.")
        return payload

    @classmethod
    def _manga_from_item(cls, item: dict[str, Any]) -> SourceMangaOut:
        manga_id = item.get("id")
        title_data = item.get("title")
        if (
            isinstance(manga_id, bool)
            or not isinstance(manga_id, (str, int))
            or not isinstance(title_data, dict)
        ):
            raise SourceError("O AniList retornou dados inválidos de título.")

        title = cls._first_text(
            title_data.get("english"),
            title_data.get("romaji"),
            title_data.get("native"),
        )
        if title is None:
            raise SourceError("O AniList retornou um título sem nome.")

        cover = item.get("coverImage")
        cover_url = None
        if isinstance(cover, dict):
            cover_url = cls._first_text(
                cover.get("extraLarge"),
                cover.get("large"),
            )

        identifier = str(manga_id)
        source_url = item.get("siteUrl")
        if not isinstance(source_url, str):
            source_url = f"https://anilist.co/manga/{identifier}"

        return SourceMangaOut(
            source_id=cls.source_id,
            source_manga_id=identifier,
            supports_reading=cls.supports_reading,
            title=title,
            description=cls._clean_description(item.get("description")),
            cover_url=cover_url,
            source_url=source_url,
            authors=[],
            language=cls._language_from_country(item.get("countryOfOrigin")),
            status=cls._optional_text(item.get("status")),
        )

    @staticmethod
    def _first_text(*values: Any) -> str | None:
        return next(
            (
                value.strip()
                for value in values
                if isinstance(value, str) and value.strip()
            ),
            None,
        )

    @classmethod
    def _clean_description(cls, value: Any) -> str | None:
        if not isinstance(value, str) or not value.strip():
            return None
        plain_text = re.sub(r"<[^>]*>", " ", value)
        return html.unescape(re.sub(r"\s+", " ", plain_text)).strip() or None

    @staticmethod
    def _language_from_country(value: Any) -> str | None:
        return {"JP": "ja", "KR": "ko", "CN": "zh"}.get(value)

    @staticmethod
    def _optional_text(value: Any) -> str | None:
        return value if isinstance(value, str) and value else None
