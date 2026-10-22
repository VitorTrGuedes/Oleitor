from app.sources.base import SourceProvider
from app.sources.mangadex import MangaDexProvider


class SourceRegistry:
    def __init__(self) -> None:
        self._providers: dict[str, SourceProvider] = {}

    def register(self, provider: SourceProvider) -> None:
        if provider.source_id in self._providers:
            raise ValueError(f"Fonte já registrada: {provider.source_id}")
        self._providers[provider.source_id] = provider

    def get(self, source_id: str) -> SourceProvider:
        return self._providers[source_id]

    def list(self) -> list[SourceProvider]:
        return list(self._providers.values())


source_registry = SourceRegistry()


def register_source(provider: SourceProvider) -> None:
    source_registry.register(provider)


register_source(MangaDexProvider())
