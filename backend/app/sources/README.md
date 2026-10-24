# Fontes externas

A busca ao vivo é servida por provedores que implementam `SourceProvider`, em
`base.py`. O MangaDex fornece títulos, capítulos e páginas de leitura. O AniList
amplia a descoberta com dados de catálogo, mas não fornece capítulos ou páginas.
As capacidades de cada fonte são informadas por `GET /api/v1/sources`.

Rotas disponíveis:

- `GET /api/v1/sources`: lista os provedores registrados.
- `GET /api/v1/sources/{source_id}/manga?search=...`: busca títulos.
- `GET /api/v1/sources/{source_id}/manga/{manga_id}/chapters`: lista capítulos.
- `GET /api/v1/sources/{source_id}/chapters/{chapter_id}/pages`: lista imagens.

As rotas de capítulos e páginas respondem HTTP 409 quando usadas com uma fonte
somente de catálogo. A busca do AniList não aplica filtro de idioma porque a API
não oferece esse filtro para resultados de mangá.

Para adicionar uma fonte, crie um provedor com os métodos `search`,
`list_chapters` e `get_pages`, retornando os modelos de `app.schemas`. Depois,
importe a classe em `registry.py` e registre uma instância única com
`register_source(MeuProvedor())`. Use um `source_id` estável e único. Falhas de
conexão ou respostas inválidas devem ser lançadas como `SourceError`; a API as
converte em HTTP 502.
