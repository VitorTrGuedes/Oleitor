# Fontes externas

A busca ao vivo é servida por provedores que implementam `SourceProvider`, em
`base.py`. O MangaDex já está registrado em `registry.py`.

Rotas disponíveis:

- `GET /api/v1/sources`: lista os provedores registrados.
- `GET /api/v1/sources/{source_id}/manga?search=...`: busca títulos.
- `GET /api/v1/sources/{source_id}/manga/{manga_id}/chapters`: lista capítulos.
- `GET /api/v1/sources/{source_id}/chapters/{chapter_id}/pages`: lista imagens.

Para adicionar uma fonte, crie um provedor com os métodos `search`,
`list_chapters` e `get_pages`, retornando os modelos de `app.schemas`. Depois,
importe a classe em `registry.py` e registre uma instância única com
`register_source(MeuProvedor())`. Use um `source_id` estável e único. Falhas de
conexão ou respostas inválidas devem ser lançadas como `SourceError`; a API as
converte em HTTP 502.
