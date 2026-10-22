# Oleitor — documentação do projeto

> Documento-base para planejar, desenvolver, testar e distribuir o aplicativo **Oleitor**. O projeto ainda está em fase de planejamento; exemplos de rotas, estrutura e banco abaixo são propostas iniciais, não funcionalidades já implementadas.

## 1. Visão geral

O **Oleitor** será um aplicativo mobile para organizar e ler mangás, com foco inicial em Android. O app será desenvolvido em Flutter no Visual Studio Code; a API será feita em Python com FastAPI; os dados relacionais ficarão em PostgreSQL hospedado no Neon; Git e GitHub serão usados para versionamento.

### Objetivos do MVP

- Exibir uma biblioteca de títulos e permitir encontrar um título por nome.
- Exibir detalhes do título e sua lista de capítulos.
- Abrir um capítulo em uma interface de leitura adequada a imagens.
- Salvar e restaurar o progresso de leitura.
- Consultar e alterar dados por uma API HTTPS, sem conectar o aplicativo diretamente ao PostgreSQL.
- Gerar um APK Android instalável para testes.

### Fora do escopo inicial

- Publicar na Play Store ou na App Store.
- Hospedar ou distribuir conteúdo protegido por direitos autorais sem autorização.
- Criar um serviço próprio de armazenamento de imagens.
- Sincronização multiusuário, login social ou assinatura/pagamento.

## 2. Decisões e pendências

| Tema | Decisão inicial |
|---|---|
| Nome do app | Oleitor |
| App mobile | Flutter/Dart |
| Editor | Visual Studio Code |
| API | Python + FastAPI |
| Banco | PostgreSQL no Neon |
| Versionamento | Git + GitHub |
| Plataforma inicial | Android |
| Design | Arquivo Figma indicado abaixo; precisa ser validado visualmente antes da implementação das telas |
| Imagens de capas/páginas | Provedor/forma de armazenamento ainda a escolher; banco guarda metadados e referências, não arquivos grandes |
| Autenticação | Pendente; necessária antes de expor endpoints de leitura/escrita na internet para outros usuários |

**Design de referência:** [Arquivo do Oleitor no Figma](https://www.figma.com/design/57UFu1yCMTnPaIFpoiRwsi/Sem-t%C3%ADtulo?node-id=0-1&t=gbKsv3ULcaGyyLsO-1). Se o arquivo não abrir para a equipe, exportar as telas em PNG/PDF ou ajustar o compartilhamento.

## 3. Arquitetura

```text
┌────────────────────┐     HTTPS/JSON     ┌──────────────────────┐
│ Flutter (Android)  │ ─────────────────▶ │ FastAPI (Python)     │
│ telas e leitor     │ ◀───────────────── │ validação e regras   │
└────────────────────┘                    └──────────┬───────────┘
                                                     │ TLS / PostgreSQL
                                          ┌──────────▼───────────┐
                                          │ Neon PostgreSQL      │
                                          │ títulos, capítulos,  │
                                          │ páginas e progresso  │
                                          └──────────────────────┘
```

- O Flutter conhece somente a URL pública da API; **não** recebe a senha/connection string do Neon.
- A API valida os parâmetros, aplica as regras e acessa o banco usando credenciais armazenadas no ambiente do servidor.
- Capas e páginas são arquivos. Armazená-los em um serviço de arquivos compatível ou localmente no aparelho; no PostgreSQL ficam URLs/caminhos e metadados.
- Para desenvolvimento, API e app podem rodar na máquina local. Um emulador Android pode exigir `10.0.2.2` para acessar o `localhost` do computador; em aparelho físico, usar o IP local do computador e a mesma rede Wi-Fi.
- Um serviço hospedado publicamente deve usar HTTPS e autenticação/autorização antes de permitir operações privadas. Não embutir um token compartilhado no APK como se fosse segredo.

## 4. Estrutura sugerida do repositório

```text
leitor/
├── mobile/                  # aplicativo Flutter
│   ├── lib/
│   │   ├── app/             # tema, navegação e configuração
│   │   ├── features/        # biblioteca, detalhes, leitor e progresso
│   │   ├── data/            # clientes HTTP e repositórios
│   │   └── main.dart
│   └── test/
├── api/                     # serviço Python/FastAPI
│   ├── app/
│   │   ├── main.py
│   │   ├── api/             # endpoints e schemas
│   │   ├── models/          # modelos de persistência
│   │   ├── services/        # regras de negócio
│   │   └── db.py
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example
├── database/
│   └── migrations/          # migrações SQL/Alembic versionadas
├── docs/                    # decisões e documentação adicional
├── .gitignore
└── README.md
```

Manter a API e o app separados evita misturar dependências e permite executar testes específicos. A estrutura pode ser simplificada se o MVP começar menor, sem eliminar a separação entre cliente, API e banco.

## 5. Requisitos e preparação do ambiente

### Ferramentas

- Git e uma conta no GitHub.
- Flutter SDK estável e extensões **Flutter** e **Dart** no VS Code.
- Android SDK e, opcionalmente, emulador instalado pelo Android Studio.
- Python 3.11+ recomendado para a API.
- Acesso à internet para instalar dependências e acessar o Neon.

No PowerShell, verificar as instalações:

```powershell
flutter doctor
flutter --version
git --version
python --version
```

Resolver os itens relevantes do `flutter doctor` para Android antes de tentar compilar o APK.

### Criar a estrutura inicial

Na pasta onde o projeto será criado:

```powershell
mkdir leitor
cd leitor
git init
flutter create mobile
mkdir api, database, docs
```

Abrir no VS Code:

```powershell
code .
```

Testar o app padrão antes de começar a alterar as telas:

```powershell
cd mobile
flutter run
```

## 6. Desenvolvimento do aplicativo Flutter

### Telas previstas

1. **Biblioteca:** lista ou grade de capas, busca e estados de carregamento/vazio/erro.
2. **Detalhes:** capa, título, descrição e capítulos.
3. **Oleitor:** exibe páginas, navegação vertical ou por página conforme o Figma, controle de zoom e retorno ao capítulo.
4. **Progresso:** reabre no capítulo e página salvos.

Implementar a navegação e o tema conforme o Figma depois que os frames estiverem acessíveis. Manter chamadas HTTP fora dos widgets de tela, usando serviços/repositórios para facilitar testes e tratamento de erro.

### Dependências possíveis

Adicionar pacotes apenas quando a funcionalidade correspondente for implementada. Exemplos: cliente HTTP (`dio` ou `http`), roteamento (`go_router`), gerenciamento de estado (Riverpod ou solução já adotada pelo projeto), armazenamento local para preferências/progresso offline e visualização ampliável de imagens (`photo_view`). Conferir versões compatíveis e manutenção dos pacotes no pub.dev.

### Comandos

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Se uma funcionalidade depender de rede, mostrar estados de carregamento e erro e preservar a experiência local apropriada quando a conexão não estiver disponível.

## 7. API Python (FastAPI)

### Responsabilidades

- Expor JSON por HTTPS.
- Validar entrada e saída com modelos tipados.
- Aplicar regras de negócio e autorização.
- Acessar Neon; não devolver credenciais ou detalhes internos do banco.
- Registrar erros úteis sem gravar senhas, tokens ou dados sensíveis nos logs.

### Rotas iniciais propostas

| Método e rota | Finalidade |
|---|---|
| `GET /health` | Verificar se o serviço está ativo; não revelar segredos nem dados do banco |
| `GET /api/v1/manga` | Listar títulos; aceitar paginação e busca opcional |
| `GET /api/v1/manga/{manga_id}` | Obter detalhes de um título |
| `GET /api/v1/manga/{manga_id}/chapters` | Listar capítulos de um título |
| `GET /api/v1/chapters/{chapter_id}/pages` | Obter páginas ordenadas de um capítulo |
| `GET /api/v1/reading-progress` | Consultar progresso do usuário autenticado/dispositivo autorizado |
| `PUT /api/v1/reading-progress` | Criar ou atualizar o progresso |

Usar paginação, limites de tamanho e respostas consistentes. Retornar códigos HTTP apropriados (por exemplo, `404` para recurso inexistente e `422` para entrada inválida). A documentação interativa do FastAPI fica disponível em `/docs` durante desenvolvimento; avaliar se deve ser pública em produção.

Exemplo conceitual de resposta de capítulo:

```json
{
  "id": "uuid",
  "title": "Capítulo 1",
  "pages": [
    { "number": 1, "image_url": "https://..." },
    { "number": 2, "image_url": "https://..." }
  ]
}
```

### Ambiente local da API

Criar e ativar um ambiente virtual no PowerShell:

```powershell
cd api
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Instalar dependências definidas pelo projeto (FastAPI, Uvicorn, driver PostgreSQL, ORM/migrações e configuração por ambiente). Executar em desenvolvimento, quando `app.main:app` estiver criado:

```powershell
python -m uvicorn app.main:app --reload
```

O endereço local padrão é `http://127.0.0.1:8000`. A API hospedada deve usar HTTPS.

## 8. PostgreSQL no Neon

### Modelo de dados inicial

- **manga:** id, título, autor opcional, descrição opcional, capa opcional, idioma, timestamps.
- **chapter:** id, manga_id, título, número/ordem, timestamps.
- **page:** id, chapter_id, número/ordem, image_url/caminho do arquivo.
- **reading_progress:** id, manga_id, chapter_id, página atual, updated_at e identificador do proprietário/dispositivo autorizado.

Usar chaves UUID, chaves estrangeiras e índices para relações e ordenação. Definir unicidade para a ordem do capítulo dentro de um mangá e para a ordem da página dentro de um capítulo. O desenho final deve refletir as telas e as decisões de autenticação/sincronização; não salvar conteúdo binário de páginas como grandes blobs no banco sem uma necessidade concreta.

### Segurança e conexão

1. Criar projeto e banco no Neon.
2. Copiar a connection string de PostgreSQL para um arquivo `.env` local da **API** ou variável secreta do serviço de hospedagem.
3. Manter `.env` no `.gitignore`; versionar somente `.env.example` com nomes de variáveis e valores fictícios.
4. Usar TLS e o formato de conexão recomendado pelo Neon. Para serviços serverless/muitas conexões curtas, avaliar a connection string pooled do Neon.
5. Aplicar alterações do esquema por migrações versionadas. Não alterar produção manualmente sem registrar uma migração correspondente.

Exemplo de `.env.example` (sem credenciais reais):

```dotenv
DATABASE_URL=postgresql+psycopg://USER:PASSWORD@HOST/DB?sslmode=require
ENVIRONMENT=development
```

Verificar a compatibilidade do prefixo da URL com o driver/ORM escolhido. Se uma credencial for exposta, revogá-la/rotacioná-la no Neon; apagar o arquivo do commit mais recente não desfaz a exposição no histórico.

## 9. Git e GitHub

1. Criar no GitHub um repositório vazio chamado `leitor`.
2. Confirmar que `.gitignore` exclui `.env`, `.venv/`, `__pycache__/`, `.dart_tool/`, `build/`, caches e arquivos locais do editor que não devam ser compartilhados.
3. Criar commits pequenos e descritivos.

```powershell
git status
git add .
git commit -m "Cria estrutura inicial do projeto"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/leitor.git
git push -u origin main
```

Antes de cada `git add`, verificar `git status` e revisar arquivos novos. Nunca versionar connection strings, tokens, keystores, senhas, dados de usuários ou material de conteúdo sem autorização. Usar branches `feature/...` para mudanças maiores e abrir pull request para revisar antes de integrar a `main`.

## 10. Testes e critérios de aceite do MVP

- O app inicia no emulador ou aparelho Android suportado.
- A biblioteca trata estados de carregamento, vazio e erro da API.
- Detalhes exibem capítulos do mangá correto e em ordem.
- Oleitor apresenta páginas na ordem correta e comunica falhas de carregamento.
- Progresso salvo é recuperado após fechar e abrir o app.
- API valida entradas, retorna respostas HTTP apropriadas e não expõe segredos.
- Migrações criam as tabelas e relações esperadas em um banco de teste.
- APK release instala em um dispositivo Android de teste.

Testes sugeridos: testes unitários/widget do Flutter; testes de API para respostas e validação; testes de integração com PostgreSQL de desenvolvimento/teste. Evitar usar dados reais ou produção nos testes automatizados.

## 11. Build e instalação Android

Para gerar APK de release:

```powershell
cd mobile
flutter build apk --release
```

O resultado normalmente fica em:

```text
mobile\build\app\outputs\flutter-apk\app-release.apk
```

Instalar em dispositivo de teste com `adb install -r <caminho-do-apk>` ou transferir o APK para o aparelho. Para distribuição fora do uso local, configurar assinatura release. Guardar keystore e senhas fora do Git e manter cópia segura: a chave é necessária para publicar atualizações compatíveis. Para a Play Store, verificar os requisitos atuais de assinatura e formato (geralmente Android App Bundle).

## 12. Hospedagem e custos

- Flutter, VS Code, Git e GitHub podem ser usados sem custo nos fluxos básicos.
- Neon e provedores de API podem oferecer níveis gratuitos sujeitos a limites, suspensão, quotas e alteração de termos. Confirmar os preços/limites vigentes antes de depender deles.
- Um backend público precisa de HTTPS, configuração segura de variáveis e estratégia de autenticação. Não assumir que um plano gratuito é adequado para produção.
- O app local e o APK de teste podem ser desenvolvidos sem publicar em loja. Publicação em lojas pode exigir cadastro pago e requisitos adicionais.

## 13. Privacidade, segurança e direitos autorais

- Coletar apenas dados necessários; documentar finalidade e retenção antes de adicionar contas ou telemetria.
- Usar autenticação/autorização antes de sincronizar dados privados. Validar autorização por recurso, não somente se o usuário está logado.
- Não embutir segredos de servidor no app, não registrar credenciais em logs e usar TLS.
- Limitar requisições e uploads; validar tamanho e tipo de arquivos se houver upload.
- Utilizar apenas obras, imagens e fontes de conteúdo que o usuário tenha direito de acessar. O app de leitura não concede direitos de distribuição. Priorizar fontes oficiais e respeitar termos de serviço e legislação aplicável.

## 14. Roadmap proposto

1. Confirmar/exportar o Figma e fechar telas e comportamento do leitor.
2. Criar repositório GitHub, projeto Flutter e estrutura inicial.
3. Implementar navegação e telas com dados locais de exemplo.
4. Definir migração inicial do PostgreSQL e modelos da API.
5. Criar endpoints e testes; validar acesso seguro ao Neon.
6. Integrar Flutter à API e tratar estados offline/erro.
7. Implementar salvamento de progresso e armazenamento de imagens autorizado.
8. Validar experiência em Android real, gerar APK assinado e documentar instalação.
9. Se necessário, planejar autenticação multiusuário e publicação.

## 15. Referências

- Flutter: https://docs.flutter.dev/
- FastAPI: https://fastapi.tiangolo.com/
- Neon: https://neon.tech/docs
- PostgreSQL: https://www.postgresql.org/docs/
- Git: https://git-scm.com/doc
- GitHub Docs: https://docs.github.com/
- Layout: https://www.figma.com/design/57UFu1yCMTnPaIFpoiRwsi/Sem-t%C3%ADtulo?node-id=0-1&t=gbKsv3ULcaGyyLsO-1
