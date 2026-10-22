import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/local_progress_store.dart';
import '../../data/models.dart';
import '../manga/manga_detail_screen.dart';
import '../reader/reader_screen.dart';

const _background = Color(0xFF141318);
const _surface = Color(0xFF1E1D24);
const _surfaceBorder = Color(0xFF393741);
const _accent = Color(0xFFB18AF5);
const _text = Color(0xFFF4F1FA);
const _subtle = Color(0xFFA6A2AF);

class LibraryHomeScreen extends StatefulWidget {
  const LibraryHomeScreen({super.key, this.apiClient, required this.onExplore});

  final ApiClient? apiClient;
  final VoidCallback onExplore;

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Manga> _manga = [];
  Manga? _resumeManga;
  Chapter? _resumeChapter;
  int? _resumePage;
  int? _resumeTotalPages;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final manga = await _api.getManga(search: _searchController.text);
      Manga? resumeManga;
      Chapter? resumeChapter;
      int? resumePage;
      int? resumeTotalPages;
      if (_searchController.text.trim().isEmpty && manga.isNotEmpty) {
        final deviceId = await LocalProgressStore.getDeviceId();
        final progress = await _api.getProgress(deviceId);
        if (progress.isNotEmpty) {
          final latestProgress = progress.first;
          for (final item in manga) {
            if (item.id == latestProgress.mangaId) {
              final chapters = await _api.getChapters(item.id);
              for (final chapter in chapters) {
                if (chapter.id == latestProgress.chapterId) {
                  resumeManga = item;
                  resumeChapter = chapter;
                  resumePage = latestProgress.pageNumber;
                  resumeTotalPages ??= (await _api.getPages(chapter.id)).length;
                  break;
                }
              }
              break;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _manga = manga;
        _resumeManga = resumeManga;
        _resumeChapter = resumeChapter;
        _resumePage = resumePage;
        _resumeTotalPages = resumeTotalPages;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      _loadLibrary,
    );
  }

  void _openManga(Manga manga) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MangaDetailScreen(manga: manga),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _surface,
          onRefresh: _loadLibrary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2237),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _accent,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Text(
                      'Oleitor',
                      style: TextStyle(
                        color: _text,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: 'Explorar títulos',
                    onPressed: widget.onExplore,
                    style: IconButton.styleFrom(
                      backgroundColor: _surface,
                      foregroundColor: _text,
                      fixedSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 29),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Biblioteca',
                style: TextStyle(
                  color: _text,
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Boa noite. Que tal mais um capítulo?',
                style: TextStyle(color: _subtle, fontSize: 16),
              ),
              const SizedBox(height: 23),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _loadLibrary(),
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: _text),
                decoration: InputDecoration(
                  hintText: 'Buscar título ou autor',
                  hintStyle: const TextStyle(color: _subtle),
                  prefixIcon: const Icon(Icons.search_rounded, color: _subtle),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close_rounded, color: _subtle),
                        ),
                  filled: true,
                  fillColor: _surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              ),
              if (_resumeManga != null &&
                  _resumeChapter != null &&
                  _resumePage != null) ...[
                const SizedBox(height: 28),
                const Text(
                  'Continue sua jornada',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 13),
                _ContinueReadingCard(
                  manga: _resumeManga!,
                  chapter: _resumeChapter!,
                  page: _resumePage!,
                  totalPages: _resumeTotalPages,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReaderScreen(
                        manga: _resumeManga!,
                        chapter: _resumeChapter!,
                        initialPage: _resumePage!,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Suas obras',
                      style: TextStyle(
                        color: _text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_manga.length} títulos',
                    style: const TextStyle(color: _subtle, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildMangaGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMangaGrid() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_error != null) {
      return _HomeMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível carregar sua biblioteca',
        message: _error!,
        action: TextButton(
          onPressed: _loadLibrary,
          child: const Text('Tentar novamente'),
        ),
      );
    }
    if (_manga.isEmpty) {
      return _HomeMessage(
        icon: _searchController.text.trim().isEmpty
            ? Icons.auto_stories_outlined
            : Icons.search_off_rounded,
        title: _searchController.text.trim().isEmpty
            ? 'Sua biblioteca está vazia'
            : 'Nenhum título encontrado',
        message: _searchController.text.trim().isEmpty
            ? 'Adicione uma obra do catálogo para começar sua leitura.'
            : 'Experimente buscar por outro título.',
        action: _searchController.text.trim().isEmpty
            ? FilledButton.icon(
                onPressed: widget.onExplore,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Explorar títulos'),
              )
            : null,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 760
                ? 4
                : constraints.maxWidth >= 520
                    ? 3
                    : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _manga.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.59,
          ),
          itemBuilder: (context, index) => _LibraryMangaCard(
            manga: _manga[index],
            onTap: () => _openManga(_manga[index]),
          ),
        );
      },
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({
    required this.manga,
    required this.chapter,
    required this.page,
    required this.totalPages,
    required this.onTap,
  });

  final Manga manga;
  final Chapter chapter;
  final int page;
  final int? totalPages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: _surfaceBorder),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 82,
                    height: 124,
                    child: manga.coverUrl == null
                        ? const _DarkCoverPlaceholder()
                        : Image.network(
                            manga.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _DarkCoverPlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SUA ÚLTIMA LEITURA',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        manga.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cap. ${chapter.number} · ${chapter.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _subtle, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: totalPages == null || totalPages! <= 0
                            ? const SizedBox.shrink()
                            : LinearProgressIndicator(
                                value: (page / totalPages!).clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: const Color(0xFF393741),
                                color: _accent,
                              ),
                      ),
                      if (totalPages != null && totalPages! > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Pág. $page de $totalPages · ${(page * 100 / totalPages!).round()}% lido',
                          style: const TextStyle(color: _subtle, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  tooltip: 'Continuar leitura',
                  onPressed: onTap,
                  style: IconButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: const Color(0xFF21182E),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LibraryMangaCard extends StatelessWidget {
  const _LibraryMangaCard({required this.manga, required this.onTap});

  final Manga manga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: manga.coverUrl == null
                      ? const _DarkCoverPlaceholder()
                      : Image.network(
                          manga.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _DarkCoverPlaceholder(),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      manga.author ?? manga.language,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _subtle, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _DarkCoverPlaceholder extends StatelessWidget {
  const _DarkCoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF2B2932),
        child: Center(
          child: Icon(
            Icons.auto_stories_outlined,
            size: 38,
            color: _accent,
          ),
        ),
      );
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _surfaceBorder),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _subtle, fontSize: 13),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      );
}
