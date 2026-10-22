from sqlalchemy import select

from app.database import Base, SessionLocal, engine
from app.models import Chapter, Manga, Page


def seed_demo() -> None:
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        exists = db.scalar(select(Manga.id).where(Manga.title == "A Cidade das Estrelas"))
        if exists:
            print("O conteúdo demonstrativo já existe.")
            return

        manga = Manga(
            title="A Cidade das Estrelas",
            author="Equipe Oleitor",
            description=(
                "Uma história original de demonstração. As páginas abaixo são "
                "imagens-placeholder e não representam conteúdo publicado."
            ),
            cover_url="https://placehold.co/600x900/172554/f8fafc?text=Oleitor",
            language="pt-BR",
        )
        chapter = Chapter(title="O começo", number=1, manga=manga)
        chapter.pages = [
            Page(
                number=number,
                image_url=(
                    f"https://placehold.co/900x1400/0f172a/e2e8f0"
                    f"?text=Pagina+{number}"
                ),
            )
            for number in range(1, 4)
        ]
        db.add(manga)
        db.commit()
    print("Conteúdo demonstrativo criado.")


if __name__ == "__main__":
    seed_demo()
