CREATE TABLE manga (
    id UUID PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    author VARCHAR(200),
    description VARCHAR(4000),
    cover_url VARCHAR(2048),
    language VARCHAR(16) NOT NULL DEFAULT 'pt-BR',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX ix_manga_title ON manga (title);

CREATE TABLE chapter (
    id UUID PRIMARY KEY,
    manga_id UUID NOT NULL REFERENCES manga(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    number INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_chapter_manga_number UNIQUE (manga_id, number)
);
CREATE INDEX ix_chapter_manga_id ON chapter (manga_id);

CREATE TABLE page (
    id UUID PRIMARY KEY,
    chapter_id UUID NOT NULL REFERENCES chapter(id) ON DELETE CASCADE,
    number INTEGER NOT NULL,
    image_url VARCHAR(2048) NOT NULL,
    CONSTRAINT uq_page_chapter_number UNIQUE (chapter_id, number)
);
CREATE INDEX ix_page_chapter_id ON page (chapter_id);

CREATE TABLE reading_progress (
    id UUID PRIMARY KEY,
    device_id VARCHAR(128) NOT NULL,
    manga_id UUID NOT NULL REFERENCES manga(id) ON DELETE CASCADE,
    chapter_id UUID NOT NULL REFERENCES chapter(id) ON DELETE CASCADE,
    page_number INTEGER NOT NULL CHECK (page_number >= 1),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_progress_device_manga UNIQUE (device_id, manga_id)
);
CREATE INDEX ix_reading_progress_device_id ON reading_progress (device_id);
