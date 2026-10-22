import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocalProgressStore {
  static const _deviceIdKey = 'oleitor_device_id';

  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final generated = List.generate(
      32,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  static Future<MangaProgress?> getProgress(String mangaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chapterId = prefs.getString('progress_${mangaId}_chapter');
    final pageNumber = prefs.getInt('progress_${mangaId}_page');
    if (chapterId == null || pageNumber == null) return null;
    return MangaProgress(
      mangaId: mangaId,
      chapterId: chapterId,
      pageNumber: pageNumber,
    );
  }

  static Future<void> saveProgress(MangaProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'progress_${progress.mangaId}_chapter',
      progress.chapterId,
    );
    await prefs.setInt(
      'progress_${progress.mangaId}_page',
      progress.pageNumber,
    );
  }
}
