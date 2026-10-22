class Manga {
  const Manga({
    required this.id,
    required this.title,
    required this.language,
    this.author,
    this.description,
    this.coverUrl,
    this.sourceId,
    this.sourceUrl,
    this.status,
  });

  final String id;
  final String title;
  final String language;
  final String? author;
  final String? description;
  final String? coverUrl;
  final String? sourceId;
  final String? sourceUrl;
  final String? status;

  bool get isExternal => sourceId != null;

  factory Manga.fromJson(Map<String, dynamic> json) => Manga(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        description: json['description'] as String?,
        coverUrl: json['cover_url'] as String?,
        language: json['language'] as String? ?? 'pt-BR',
      );

  factory Manga.fromSourceJson(Map<String, dynamic> json) => Manga(
        id: json['source_manga_id'] as String,
        title: json['title'] as String,
        author:
            (json['authors'] as List<dynamic>?)?.whereType<String>().join(', '),
        description: json['description'] as String?,
        coverUrl: json['cover_url'] as String?,
        language: json['language'] as String? ?? 'ja',
        sourceId: json['source_id'] as String,
        sourceUrl: json['source_url'] as String?,
        status: json['status'] as String?,
      );
}

class Chapter {
  const Chapter({
    required this.id,
    required this.mangaId,
    required this.title,
    required this.number,
    this.pageCount,
  });

  final String id;
  final String mangaId;
  final String title;
  final String number;
  final int? pageCount;

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as String,
        mangaId: json['manga_id'] as String,
        title: json['title'] as String,
        number: json['number'].toString(),
        pageCount: json['page_count'] as int?,
      );

  factory Chapter.fromSourceJson(Map<String, dynamic> json) => Chapter(
        id: json['source_chapter_id'] as String,
        mangaId: json['manga_id'] as String,
        title: json['title'] as String,
        number: json['number'] as String? ?? '',
        pageCount: json['page_count'] as int?,
      );
}

class MangaProgress {
  const MangaProgress({
    required this.mangaId,
    required this.chapterId,
    required this.pageNumber,
  });

  final String mangaId;
  final String chapterId;
  final int pageNumber;

  factory MangaProgress.fromJson(Map<String, dynamic> json) => MangaProgress(
        mangaId: json['manga_id'] as String,
        chapterId: json['chapter_id'] as String,
        pageNumber: json['page_number'] as int,
      );
}

class MangaPage {
  const MangaPage({
    required this.number,
    required this.imageUrl,
  });

  final int number;
  final String imageUrl;

  factory MangaPage.fromJson(Map<String, dynamic> json) => MangaPage(
        number: json['number'] as int,
        imageUrl: json['image_url'] as String,
      );
}
