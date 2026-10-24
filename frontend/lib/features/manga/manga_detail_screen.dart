import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/local_progress_store.dart';
import '../../data/models.dart';
import '../reader/reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  const MangaDetailScreen({super.key, required this.manga});

  final Manga manga;

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  final _api = ApiClient();
  late Future<(Manga, List<Chapter>)> _detailsFuture;
  MangaProgress? _progress;
  String? _progressError;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
    _loadProgress();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<(Manga, List<Chapter>)> _loadDetails() async {
    if (widget.manga.isExternal) {
      if (!widget.manga.supportsReading) {
        return (widget.manga, const <Chapter>[]);
      }
      final chapters = await _api.getSourceChapters(
        sourceId: widget.manga.sourceId!,
        mangaId: widget.manga.id,
      );
      return (widget.manga, chapters);
    }
    final results = await Future.wait<Object>([
      _api.getMangaDetails(widget.manga.id),
      _api.getChapters(widget.manga.id),
    ]);
    return (results[0] as Manga, results[1] as List<Chapter>);
  }

  Future<void> _loadProgress() async {
    try {
      final localProgress =
          await LocalProgressStore.getProgress(widget.manga.id);
      if (localProgress != null && mounted) {
        setState(() => _progress = localProgress);
      }
      if (widget.manga.isExternal) return;
      final deviceId = await LocalProgressStore.getDeviceId();
      final progressList = await _api.getProgress(deviceId);
      if (!mounted) return;
      MangaProgress? remoteProgress;
      for (final progress in progressList) {
        if (progress.mangaId == widget.manga.id) remoteProgress = progress;
      }
      if (remoteProgress != null) {
        await LocalProgressStore.saveProgress(remoteProgress);
      }
      if (!mounted) return;
      final synchronizedProgress = remoteProgress;
      setState(() {
        if (synchronizedProgress != null) _progress = synchronizedProgress;
        _progressError = null;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _progressError = error.toString());
    }
  }

  void _openReader(Manga manga, Chapter chapter, {int initialPage = 1}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(
          manga: manga,
          chapter: chapter,
          initialPage: initialPage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141318),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A191F),
        title: Row(
          children: [
            const Text('Biblioteca'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 18),
            ),
            Expanded(
              child: Text(
                widget.manga.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<(Manga, List<Chapter>)>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Não foi possível carregar o título.\n${snapshot.error}',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _detailsFuture = _loadDetails()),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }
          final (manga, chapters) = snapshot.data!;
          final resumableChapter =
              chapters.where((chapter) => chapter.id == _progress?.chapterId);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 128,
                      height: 184,
                      child: manga.coverUrl == null
                          ? const ColoredBox(
                              color: Color(0xFF2B2932),
                              child:
                                  Icon(Icons.auto_stories_outlined, size: 44),
                            )
                          : Image.network(
                              manga.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                color: Color(0xFF2B2932),
                                child:
                                    Icon(Icons.broken_image_outlined, size: 44),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manga.sourceId == null
                              ? 'MANGÁ'
                              : manga.sourceId!.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFB18AF5),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          manga.title,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (manga.author != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            manga.author!,
                            style: const TextStyle(color: Color(0xFFA6A2AF)),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          manga.status?.toUpperCase() ?? manga.language,
                          style: const TextStyle(color: Color(0xFFA6A2AF)),
                        ),
                        if (manga.sourceId != null) ...[
                          const SizedBox(height: 10),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF30273F),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                manga.sourceId!.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFB18AF5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (manga.description != null) ...[
                const SizedBox(height: 20),
                Text(
                  manga.description!,
                  style: const TextStyle(
                    color: Color(0xFFD1CED8),
                    height: 1.5,
                  ),
                ),
              ],
              if (_progressError != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Não foi possível sincronizar o progresso: $_progressError',
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ],
              if (resumableChapter.isNotEmpty) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openReader(
                    manga,
                    resumableChapter.first,
                    initialPage: _progress!.pageNumber,
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text('Continuar da página ${_progress!.pageNumber}'),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Capítulos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${chapters.length}',
                    style: const TextStyle(color: Color(0xFFA6A2AF)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (chapters.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    manga.isExternal && !manga.supportsReading
                        ? 'Esta fonte oferece informações do título, mas não capítulos para leitura.'
                        : 'Nenhum capítulo disponível ainda.',
                  ),
                )
              else
                ...chapters.map(
                  (chapter) => Card(
                    child: ListTile(
                      title: Text(chapter.title),
                      subtitle: Text(
                        chapter.number.isEmpty
                            ? chapter.title
                            : 'Capítulo ${chapter.number}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openReader(manga, chapter),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
