# Oleitor

Aplicativo Flutter para descobrir, organizar e ler mangás, inspirado no
protótipo do Figma com tema escuro, destaque lilás e navegação adaptada para
celulares e telas largas.

## Funcionalidades

- Biblioteca com títulos salvos e retomada da leitura.
- Navegação lateral em telas largas e barra inferior em celulares.
- Busca ao vivo em fontes registradas na API.
- Detalhes, capítulos e leitor paginado para títulos do MangaDex.
- Favoritos e progresso de leitura salvos no dispositivo.
- Biblioteca local mantida pela API do Oleitor.

## Executar

Inicie a API do Oleitor e rode o app no emulador Android:

```sh
flutter pub get
flutter run
```

Por padrão, o app usa `http://10.0.2.2:8000`, endereço do host visto pelo
emulador Android. Em um dispositivo físico, use o IP do computador na rede
local:

```sh
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
```

O manifesto permite acesso à internet. Para compilações de produção, configure
uma URL HTTPS; tráfego HTTP sem TLS fica permitido apenas na configuração de
desenvolvimento do Android.

A busca e a leitura de fontes externas dependem das rotas `/api/v1/sources`
disponíveis no backend. Para registrar novas fontes, consulte
[app/sources/README.md](../backend/app/sources/README.md).
