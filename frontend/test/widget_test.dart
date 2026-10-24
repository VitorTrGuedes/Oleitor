import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oleitor/app.dart';
import 'package:oleitor/data/api_client.dart';
import 'package:oleitor/data/favorite_store.dart';
import 'package:oleitor/data/models.dart';
import 'package:oleitor/features/manga/manga_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('exibe a navegação e a tela inicial do aplicativo',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final apiClient = ApiClient(
      client: MockClient((_) async => http.Response('[]', 200)),
    );
    await tester.pumpWidget(OleitorApp(apiClient: apiClient));
    await tester.pumpAndSettle();
    expect(find.text('Oleitor'), findsNWidgets(2));
    expect(find.text('Biblioteca'), findsNWidgets(2));
    expect(find.text('Mais lidas no Oleitor'), findsOneWidget);
    expect(find.text('Recomendadas para você'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Suas obras'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Suas obras'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Encontre sua próxima leitura'), findsOneWidget);
  });

  testWidgets('exibe populares e recomendações na home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await FavoriteStore.toggle(
      const Manga(
        id: 'favorite-1',
        title: 'Minha favorita',
        language: 'ja',
        sourceId: 'mangadex',
      ),
    );
    final apiClient = ApiClient(
      client: MockClient((request) async {
        if (request.url.path == '/api/v1/popular-manga') {
          return http.Response(
            '[{"id":"popular-1","title":"Popular do Oleitor",'
            '"language":"ja","source_id":"mangadex",'
            '"source_manga_id":"popular-1","supports_reading":true,'
            '"read_count":4}]',
            200,
          );
        }
        if (request.url.path == '/api/v1/recommendations') {
          return http.Response(
            '[{"source_id":"anilist","source_manga_id":"suggested-1",'
            '"title":"Sugestão personalizada","authors":[],'
            '"source_url":"https://anilist.co/manga/123",'
            '"supports_reading":false}]',
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );

    await tester.pumpWidget(OleitorApp(apiClient: apiClient));
    await tester.pumpAndSettle();

    expect(find.text('Popular do Oleitor'), findsOneWidget);
    expect(find.text('4 instalações'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sugestão personalizada'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Sugestão personalizada'), findsOneWidget);
  });

  testWidgets('informa quando a fonte oferece apenas catálogo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: MangaDetailScreen(
          manga: const Manga(
            id: '123',
            title: 'Solo Leveling',
            language: 'ko',
            sourceId: 'anilist',
            supportsReading: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Esta fonte oferece informações do título, mas não capítulos para leitura.',
      ),
      findsOneWidget,
    );
  });
}
