def create_demo_manga(db_session):
    from app.models import Chapter, Manga, Page

    manga = Manga(title="Título de teste")
    chapter = Chapter(title="Capítulo 1", number=1, manga=manga)
    chapter.pages = [
        Page(number=2, image_url="https://example.com/page-2.jpg"),
        Page(number=1, image_url="https://example.com/page-1.jpg"),
    ]
    db_session.add(manga)
    db_session.commit()
    db_session.refresh(manga)
    db_session.refresh(chapter)
    return manga.id, chapter.id


def test_health_and_empty_library(client):
    assert client.get("/health").json() == {"status": "ok"}
    manga_response = client.get(
        "/api/v1/manga",
        headers={"Origin": "http://localhost:53000"},
    )
    assert manga_response.status_code == 200
    assert manga_response.json() == []
    assert manga_response.headers["access-control-allow-origin"] == (
        "http://localhost:53000"
    )


def test_development_cors_preflight_for_device_header(client):
    response = client.options(
        "/api/v1/reading-progress",
        headers={
            "Origin": "http://localhost:53000",
            "Access-Control-Request-Method": "GET",
            "Access-Control-Request-Headers": "x-device-id",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == (
        "http://localhost:53000"
    )


def test_library_chapters_pages_and_search(client, db_session):
    manga_id, chapter_id = create_demo_manga(db_session)

    assert client.get("/api/v1/manga?search=teste").json()[0]["id"] == manga_id
    assert client.get(f"/api/v1/manga/{manga_id}/chapters").json()[0]["id"] == chapter_id
    pages = client.get(f"/api/v1/chapters/{chapter_id}/pages").json()
    assert [page["number"] for page in pages] == [1, 2]
    assert client.get("/api/v1/manga/not-a-uuid").status_code == 422


def test_progress_is_device_scoped_and_validated(client, db_session):
    manga_id, chapter_id = create_demo_manga(db_session)
    headers = {"X-Device-Id": "installation-a"}
    payload = {"manga_id": manga_id, "chapter_id": chapter_id, "page_number": 2}

    saved = client.put("/api/v1/reading-progress", json=payload, headers=headers)
    assert saved.status_code == 200
    assert saved.json()["page_number"] == 2
    assert len(client.get("/api/v1/reading-progress", headers=headers).json()) == 1
    updated = client.put(
        "/api/v1/reading-progress",
        json={**payload, "page_number": 1},
        headers=headers,
    )
    assert updated.status_code == 200
    assert updated.json()["page_number"] == 1
    assert len(client.get("/api/v1/reading-progress", headers=headers).json()) == 1
    assert client.get(
        "/api/v1/reading-progress", headers={"X-Device-Id": "installation-b"}
    ).json() == []
    assert client.put(
        "/api/v1/reading-progress",
        json={**payload, "page_number": 3},
        headers=headers,
    ).status_code == 422
    assert client.get("/api/v1/reading-progress").status_code == 422


def test_read_events_are_counted_once_per_device_and_ranked(client):
    payload = {
        "source_id": "mangadex",
        "manga_id": "manga-one",
        "title": "Obra popular",
        "author": "Autora",
        "cover_url": "https://example.com/cover.jpg",
        "source_url": "https://mangadex.org/title/manga-one",
        "language": "ja",
    }

    first = client.post(
        "/api/v1/reading-events",
        json=payload,
        headers={"X-Device-Id": "installation-a"},
    )
    duplicate = client.post(
        "/api/v1/reading-events",
        json=payload,
        headers={"X-Device-Id": "installation-a"},
    )
    second = client.post(
        "/api/v1/reading-events",
        json=payload,
        headers={"X-Device-Id": "installation-b"},
    )

    assert first.json() == {"recorded": True}
    assert duplicate.json() == {"recorded": False}
    assert second.json() == {"recorded": True}
    assert client.get("/api/v1/popular-manga").json() == [
        {
            "id": "manga-one",
            "title": "Obra popular",
            "author": "Autora",
            "description": None,
            "cover_url": "https://example.com/cover.jpg",
            "language": "ja",
            "source_id": "mangadex",
            "source_manga_id": "manga-one",
            "source_url": "https://mangadex.org/title/manga-one",
            "supports_reading": True,
            "read_count": 2,
        }
    ]


def test_read_events_require_a_readable_known_source(client):
    headers = {"X-Device-Id": "installation-a"}
    payload = {
        "source_id": "anilist",
        "manga_id": "123",
        "title": "Catalog-only work",
    }

    assert client.post("/api/v1/reading-events", json=payload, headers=headers).status_code == 409
    assert client.post(
        "/api/v1/reading-events",
        json={**payload, "source_id": "unknown"},
        headers=headers,
    ).status_code == 404
    assert client.get("/api/v1/popular-manga?limit=0").status_code == 422


def test_read_event_uses_library_metadata_for_internal_manga(client, db_session):
    manga_id, _ = create_demo_manga(db_session)

    response = client.post(
        "/api/v1/reading-events",
        headers={"X-Device-Id": "installation-a"},
        json={
            "source_id": "library",
            "manga_id": manga_id,
            "title": "Untrusted title",
        },
    )

    assert response.status_code == 200
    popular = client.get("/api/v1/popular-manga").json()
    assert popular[0]["id"] == manga_id
    assert popular[0]["title"] == "Título de teste"
    assert popular[0]["source_id"] is None
    assert popular[0]["read_count"] == 1
