import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oleitor/app.dart';
import 'package:oleitor/data/api_client.dart';
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
    expect(find.text('Suas obras'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Encontre sua próxima leitura'), findsOneWidget);
  });

  testWidgets('informa quando a fonte oferece apenas catálogo',
      (tester) async {
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
