import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class FavoriteStore {
  static const _key = 'oleitor_favorite_manga';

  static Future<List<Manga>> getFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_key) ?? const [];
    return entries
        .map((entry) => Manga.fromSourceJson(
              jsonDecode(entry) as Map<String, dynamic>,
            ))
        .toList();
  }

  static Future<bool> contains(Manga manga) async {
    final favorites = await getFavorites();
    return favorites.any(
      (favorite) =>
          favorite.sourceId == manga.sourceId && favorite.id == manga.id,
    );
  }

  static Future<void> toggle(Manga manga) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_key) ?? <String>[];
    final favoriteIndex = entries.indexWhere((entry) {
      final json = jsonDecode(entry) as Map<String, dynamic>;
      return json['source_id'] == manga.sourceId &&
          json['source_manga_id'] == manga.id;
    });

    if (favoriteIndex >= 0) {
      entries.removeAt(favoriteIndex);
    } else {
      entries.add(
        jsonEncode({
          'source_id': manga.sourceId,
          'source_manga_id': manga.id,
          'title': manga.title,
          'authors': manga.author?.split(', ') ?? <String>[],
          'description': manga.description,
          'cover_url': manga.coverUrl,
          'source_url': manga.sourceUrl,
          'language': manga.language,
          'status': manga.status,
        }),
      );
    }
    await preferences.setStringList(_key, entries);
  }
}
