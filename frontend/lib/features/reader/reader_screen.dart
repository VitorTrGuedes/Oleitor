import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/local_progress_store.dart';
import '../../data/models.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.manga,
    required this.chapter,
    this.initialPage = 1,
  });

  final Manga manga;
  final Chapter chapter;
  final int initialPage;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final _api = ApiClient();
  late Future<List<MangaPage>> _pagesFuture;
  late final PageController _pageController;
  int _pageNumber = 1;
  bool _verticalMode = true;
  String? _saveError;
  bool _showSaveError = false;
  bool _initialProgressSaved = false;
  bool _initialPageAdjusted = false;
  bool _readEventRecorded = false;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _pageNumber = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _pagesFuture = _api.getPages(
      widget.chapter.id,
      sourceId: widget.manga.sourceId,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _api.close();
    super.dispose();
  }

  void _queueProgressSave(int pageNumber) {
    final progress = MangaProgress(
      mangaId: widget.manga.id,
      chapterId: widget.chapter.id,
      pageNumber: pageNumber,
    );
    _saveQueue = _saveQueue.then((_) async {
      try {
        final deviceId = await LocalProgressStore.getDeviceId();
        await LocalProgressStore.saveProgress(progress);
        if (!_readEventRecorded) {
          await _api.recordReadEvent(widget.manga);
          _readEventRecorded = true;
        }
        if (!widget.manga.isExternal) {
          await _api.saveProgress(
            deviceId: deviceId,
            mangaId: widget.manga.id,
            chapterId: widget.chapter.id,
            pageNumber: pageNumber,
          );
        }
        if (!mounted) return;
        setState(() {
          _saveError = null;
          _showSaveError = false;
        });
      } on Exception catch (error) {
        if (!mounted) return;
        setState(() {
          _saveError = error.toString();
          _showSaveError = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111014),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1D24),
        foregroundColor: Colors.white,
        title: Text(
          '${widget.manga.title} · ${widget.chapter.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: _verticalMode
                ? 'Mudar para leitura horizontal'
                : 'Mudar para leitura vertical',
            onPressed: () => setState(() => _verticalMode = !_verticalMode),
            icon: Icon(
              _verticalMode
                  ? Icons.swap_vert_rounded
                  : Icons.swap_horiz_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Repetir sincronização',
            onPressed: _saveError == null
                ? null
                : () => _queueProgressSave(_pageNumber),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: FutureBuilder<List<MangaPage>>(
        future: _pagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return _readerMessage(
              'Não foi possível carregar as páginas.',
              '${snapshot.error}',
              onRetry: () => setState(
                () => _pagesFuture = _api.getPages(
                  widget.chapter.id,
                  sourceId: widget.manga.sourceId,
                ),
              ),
            );
          }
          final pages = snapshot.data!;
          if (pages.isEmpty) {
            return _readerMessage('Este capítulo ainda não tem páginas.', null);
          }
          final safeInitialPage =
              widget.initialPage.clamp(1, pages.length).toInt();
          if (!_initialPageAdjusted &&
              _pageController.initialPage != safeInitialPage - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(safeInitialPage - 1);
              }
              _initialPageAdjusted = true;
            });
          } else {
            _initialPageAdjusted = true;
          }
          if (!_initialProgressSaved) {
            _initialProgressSaved = true;
            _pageNumber = pages[safeInitialPage - 1].number;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _queueProgressSave(pages[safeInitialPage - 1].number);
            });
          }
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection:
                    _verticalMode ? Axis.vertical : Axis.horizontal,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _pageNumber = pages[index].number);
                  _queueProgressSave(pages[index].number);
                },
                itemBuilder: (context, index) => InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      pages[index].imageUrl,
                      fit: _verticalMode ? BoxFit.fitWidth : BoxFit.contain,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                ),
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: Colors.white70, size: 48),
                            SizedBox(height: 12),
                            Text('Não foi possível carregar esta página.',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      child: Text(
                        '$_pageNumber / ${pages.length}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              if (_showSaveError && _saveError != null)
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Material(
                    color: Colors.deepOrange.shade800,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Progresso não sincronizado: $_saveError',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _readerMessage(String title, String? details,
      {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            if (details != null) ...[
              const SizedBox(height: 8),
              Text(details,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ],
        ),
      ),
    );
  }
}
