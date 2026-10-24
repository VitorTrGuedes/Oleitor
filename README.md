# Oleitor

Aplicativo Flutter para organizar e ler mangás, acompanhado de uma API FastAPI.
O projeto está dividido em `frontend/` e `backend/`; a API é a única camada que
acessa o banco de dados.

## Requisitos

- Python 3.11 ou superior.
- Flutter stable e Android SDK para executar ou compilar o aplicativo Android.
- PostgreSQL/Neon é opcional em desenvolvimento: sem `DATABASE_URL`, a API usa
  SQLite local em `backend/oleitor.db`.

## Backend

No PowerShell:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
Copy-Item .env.example .env
python -m uvicorn app.main:app --reload
```

A API fica em `http://127.0.0.1:8000`; documentação interativa em
`http://127.0.0.1:8000/docs`. As tabelas locais são criadas ao iniciar. Para
popular a biblioteca com conteúdo demonstrativo original e imagens-placeholder,
execute em outro terminal, dentro de `backend/`:

```powershell
python -m app.seed_demo
```

Para Neon, defina `DATABASE_URL` no `backend/.env` com uma URL PostgreSQL que
use TLS. Não versione esse arquivo nem exponha credenciais.

## Frontend

O diretório contém o código Flutter e a plataforma Android gerada em
`frontend/android/`. Se precisar recriar os arquivos nativos, execute em
`frontend/`:

```powershell
flutter create --platforms=android --project-name oleitor .
```

Em seguida:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

O manifesto principal declara a permissão `INTERNET`. O manifesto de debug
permite HTTP sem TLS para a API local; builds release não habilitam cleartext.
Não habilite HTTP sem TLS em builds release.

No emulador Android, o endereço padrão da API é `http://10.0.2.2:8000`. Em um
dispositivo físico, informe o IP local do computador:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000
```

O backend precisa estar acessível na rede local para o dispositivo. Não use
HTTP em produção; publique a API com HTTPS.

## API implementada

- `GET /health`
- `GET /api/v1/sources`
- `GET /api/v1/sources/{source_id}/manga?search=...`
- `GET /api/v1/sources/{source_id}/manga/{manga_id}/chapters`
- `GET /api/v1/sources/{source_id}/chapters/{chapter_id}/pages`
- `GET /api/v1/manga?search=&skip=0&limit=20`
- `GET /api/v1/manga/{manga_id}`
- `GET /api/v1/manga/{manga_id}/chapters`
- `GET /api/v1/chapters/{chapter_id}/pages`
- `GET /api/v1/reading-progress`
- `PUT /api/v1/reading-progress`
- `POST /api/v1/reading-events`
- `GET /api/v1/popular-manga`
- `POST /api/v1/recommendations`

As rotas de progresso exigem `X-Device-Id` para separar os dados locais entre
instalações. Isso **não é autenticação**. Este MVP é para desenvolvimento
local: antes de expor a API a outros usuários, implemente autenticação,
autorização por recurso, HTTPS e controles de abuso. O aplicativo não contém
segredos de servidor.

O ranking registra uma leitura por obra e instalação quando o leitor abre o
primeiro capítulo. O backend mantém o identificador aleatório da instalação e
os dados básicos da obra para agregar esse ranking; não é uma contagem de
páginas lidas e, sem autenticação, pode ser manipulada. Para gerar sugestões,
o backend envia ao AniList os títulos de até cinco obras favoritas; nenhum
identificador da instalação é enviado nessa consulta.

## Testes

Na pasta `backend/`, com as dependências instaladas:

```powershell
python -m pytest
```

O Flutter não está incluído no repositório; a instalação do SDK e do Android
toolchain é necessária para executar `flutter analyze`, `flutter test` e gerar
o APK.

Consulte `backend/app/sources/README.md` para registrar novos provedores.
