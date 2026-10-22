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
    assert client.get("/api/v1/manga").status_code == 200
    assert client.get("/api/v1/manga").json() == []


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
