import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client})
      : _client = client ?? http.Client(),
        _baseUri = Uri.parse(AppConfig.apiBaseUrl);

  final http.Client _client;
  final Uri _baseUri;
  bool _closed = false;

  Uri _uri(String path, [Map<String, String>? query]) =>
      _baseUri.replace(path: path, queryParameters: query);

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query));
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Falha na comunicação com a API (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        message = body['detail']?.toString() ?? message;
      } on FormatException {
        // Preserve the HTTP status message when the server returns non-JSON.
      }
      throw ApiException(message);
    }
    return jsonDecode(response.body);
  }

  Future<List<Manga>> getManga({String search = ''}) async {
    final query = <String, String>{'skip': '0', 'limit': '100'};
    if (search.trim().isNotEmpty) query['search'] = search.trim();
    final result = await _get('/api/v1/manga', query: query) as List<dynamic>;
    return result
        .map((item) => Manga.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSources() async {
    final result = await _get('/api/v1/sources') as List<dynamic>;
    return result.cast<Map<String, dynamic>>();
  }

  Future<List<Manga>> searchSourceManga({
    required String sourceId,
    required String search,
    String? language,
    int skip = 0,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'search': search,
      'skip': '$skip',
      'limit': '$limit',
    };
    if (language != null) query['language'] = language;
    final result = await _get(
      '/api/v1/sources/$sourceId/manga',
      query: query,
    ) as List<dynamic>;
    return result
        .map(
          (item) => Manga.fromSourceJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<Chapter>> getSourceChapters({
    required String sourceId,
    required String mangaId,
    String? language,
    int skip = 0,
    int limit = 100,
  }) async {
    final query = <String, String>{'skip': '$skip', 'limit': '$limit'};
    if (language != null) query['language'] = language;
    final result = await _get(
      '/api/v1/sources/$sourceId/manga/$mangaId/chapters',
      query: query,
    ) as List<dynamic>;
    return result
        .map(
          (item) => Chapter.fromSourceJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<Manga> getMangaDetails(String mangaId) async {
    final result = await _get('/api/v1/manga/$mangaId');
    return Manga.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Chapter>> getChapters(String mangaId) async {
    final result = await _get('/api/v1/manga/$mangaId/chapters') as List<dynamic>;
    return result
        .map((item) => Chapter.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MangaPage>> getPages(
    String chapterId, {
    String? sourceId,
  }) async {
    final path = sourceId == null
        ? '/api/v1/chapters/$chapterId/pages'
        : '/api/v1/sources/$sourceId/chapters/$chapterId/pages';
    final result = await _get(path) as List<dynamic>;
    return result
        .map((item) => MangaPage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MangaProgress>> getProgress(String deviceId) async {
    final response = await _client.get(
      _uri('/api/v1/reading-progress'),
      headers: {'X-Device-Id': deviceId},
    );
    final result = _decode(response) as List<dynamic>;
    return result
        .map((item) => MangaProgress.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProgress({
    required String deviceId,
    required String mangaId,
    required String chapterId,
    required int pageNumber,
  }) async {
    final response = await _client.put(
      _uri('/api/v1/reading-progress'),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId,
      },
      body: jsonEncode({
        'manga_id': mangaId,
        'chapter_id': chapterId,
        'page_number': pageNumber,
      }),
    );
    _decode(response);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _client.close();
  }
}
