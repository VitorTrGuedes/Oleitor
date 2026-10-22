from httpx import Client, MockTransport, Response

from app.main import app
from app.sources import source_registry
from app.sources.mangadex import MangaDexProvider

MANGA_ID = "00000000-0000-4000-8000-000000000001"
CHAPTER_ID = "00000000-0000-4000-8000-000000000002"


def make_provider(handler):
    client = Client(
        base_url="https://api.mangadex.org",
        transport=MockTransport(handler),
    )
    return MangaDexProvider(client)


def test_mangadex_search_chapters_and_pages(client, monkeypatch):
    def handler(request):
        if request.url.path == "/manga":
            return Response(
                200,
                json={
                    "data": [
                        {
                            "id": MANGA_ID,
                            "attributes": {
                                "title": {"en": "Example", "pt-br": "Exemplo"},
                                "description": {"en": "Description"},
                                "originalLanguage": "ja",
                                "status": "ongoing",
                            },
                            "relationships": [
                                {
                                    "type": "author",
                                    "attributes": {"name": "Author"},
                                },
                                {
                                    "type": "cover_art",
                                    "attributes": {"fileName": "cover.jpg"},
                                },
                            ],
                        }
                    ]
                },
            )
        if request.url.path == f"/manga/{MANGA_ID}/feed":
            return Response(
                200,
                json={
                    "data": [
                        {
                            "id": CHAPTER_ID,
                            "attributes": {
                                "chapter": "1",
                                "title": "First chapter",
                                "translatedLanguage": "pt-br",
                                "pages": 2,
                                "publishAt": "2025-01-01T00:00:00Z",
                            },
                        }
                    ]
                },
            )
        if request.url.path == f"/at-home/server/{CHAPTER_ID}":
            return Response(
                200,
                json={
                    "baseUrl": "https://uploads.mangadex.org",
                    "chapter": {"hash": "hash", "data": ["1.jpg", "2.jpg"]},
                },
            )
        return Response(404)

    provider = make_provider(handler)
    monkeypatch.setitem(source_registry._providers, "mangadex", provider)

    sources = client.get("/api/v1/sources")
    assert sources.json() == [{"id": "mangadex", "name": "MangaDex"}]

    mangas = client.get(
        "/api/v1/sources/mangadex/manga",
        params={"search": "example"},
    )
    assert mangas.status_code == 200
    assert mangas.json()[0]["title"] == "Exemplo"
    assert mangas.json()[0]["authors"] == ["Author"]
    assert mangas.json()[0]["cover_url"].endswith("/cover.jpg.256.jpg")

    chapters = client.get(
        f"/api/v1/sources/mangadex/manga/{MANGA_ID}/chapters",
    )
    assert chapters.status_code == 200
    assert chapters.json()[0]["number"] == "1"

    pages = client.get(
        f"/api/v1/sources/mangadex/chapters/{CHAPTER_ID}/pages",
    )
    assert pages.status_code == 200
    assert [page["number"] for page in pages.json()] == [1, 2]
    assert pages.json()[0]["image_url"] == (
        "https://uploads.mangadex.org/data/hash/1.jpg"
    )


def test_source_errors_are_reported(client, monkeypatch):
    provider = make_provider(lambda request: Response(503))
    monkeypatch.setitem(source_registry._providers, "mangadex", provider)

    response = client.get(
        "/api/v1/sources/mangadex/manga",
        params={"search": "example"},
    )
    assert response.status_code == 502
    assert response.json()["detail"] == "A fonte MangaDex está indisponível no momento."


def test_unknown_source_returns_not_found(client):
    response = client.get(
        "/api/v1/sources/unknown/manga",
        params={"search": "example"},
    )
    assert response.status_code == 404
