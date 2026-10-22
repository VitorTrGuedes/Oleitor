import uuid
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, String, UniqueConstraint, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


def new_id() -> str:
    return str(uuid.uuid4())


class Manga(Base):
    __tablename__ = "manga"

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    title: Mapped[str] = mapped_column(String(200), nullable=False, index=True)
    author: Mapped[str | None] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(String(4000))
    cover_url: Mapped[str | None] = mapped_column(String(2048))
    language: Mapped[str] = mapped_column(String(16), nullable=False, default="pt-BR")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    chapters: Mapped[list["Chapter"]] = relationship(
        back_populates="manga", cascade="all, delete-orphan", order_by="Chapter.number"
    )


class Chapter(Base):
    __tablename__ = "chapter"
    __table_args__ = (UniqueConstraint("manga_id", "number", name="uq_chapter_manga_number"),)

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    manga_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False), ForeignKey("manga.id", ondelete="CASCADE"), nullable=False, index=True
    )
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    manga: Mapped[Manga] = relationship(back_populates="chapters")
    pages: Mapped[list["Page"]] = relationship(
        back_populates="chapter", cascade="all, delete-orphan", order_by="Page.number"
    )


class Page(Base):
    __tablename__ = "page"
    __table_args__ = (UniqueConstraint("chapter_id", "number", name="uq_page_chapter_number"),)

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    chapter_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False), ForeignKey("chapter.id", ondelete="CASCADE"), nullable=False, index=True
    )
    number: Mapped[int] = mapped_column(Integer, nullable=False)
    image_url: Mapped[str] = mapped_column(String(2048), nullable=False)

    chapter: Mapped[Chapter] = relationship(back_populates="pages")


class ReadingProgress(Base):
    __tablename__ = "reading_progress"
    __table_args__ = (
        UniqueConstraint("device_id", "manga_id", name="uq_progress_device_manga"),
        CheckConstraint("page_number >= 1", name="ck_progress_page_number"),
    )

    id: Mapped[str] = mapped_column(Uuid(as_uuid=False), primary_key=True, default=new_id)
    device_id: Mapped[str] = mapped_column(String(128), nullable=False, index=True)
    manga_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False), ForeignKey("manga.id", ondelete="CASCADE"), nullable=False
    )
    chapter_id: Mapped[str] = mapped_column(
        Uuid(as_uuid=False), ForeignKey("chapter.id", ondelete="CASCADE"), nullable=False
    )
    page_number: Mapped[int] = mapped_column(Integer, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
