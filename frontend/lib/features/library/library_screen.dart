import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/models.dart';
import '../manga/manga_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ApiClient _api;
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Manga> _manga = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _loadManga();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _loadManga() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.getManga(search: _searchController.text);
      if (!mounted) return;
      setState(() {
        _manga = items;
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), _loadManga);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Minha biblioteca',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar biblioteca',
            onPressed: _loadManga,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'Sua próxima história começa aqui.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar na sua biblioteca',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Seus títulos',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível carregar a biblioteca',
        message: _error!,
        action: FilledButton.icon(
          onPressed: _loadManga,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      );
    }
    if (_manga.isEmpty) {
      return _MessageState(
        icon: Icons.auto_stories_outlined,
        title: _searchController.text.isEmpty
            ? 'Sua biblioteca está vazia'
            : 'Nenhum título encontrado',
        message: _searchController.text.isEmpty
            ? 'Inicie a API e adicione títulos para começar a leitura.'
            : 'Experimente buscar por outro nome.',
        action: _searchController.text.isEmpty
            ? TextButton.icon(
                onPressed: _loadManga,
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar'),
              )
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadManga,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: _manga.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.61,
        ),
        itemBuilder: (context, index) {
          final manga = _manga[index];
          return _MangaCard(
            manga: manga,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MangaDetailScreen(manga: manga),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  const _MangaCard({required this.manga, required this.onTap});

  final Manga manga;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir ${manga.title}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: manga.coverUrl == null
                      ? const _CoverPlaceholder()
                      : Image.network(
                          manga.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const _CoverPlaceholder(),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manga.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      manga.author ?? manga.language,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFE2E8F0),
        child: Center(
          child: Icon(Icons.auto_stories_outlined, size: 42, color: Color(0xFF64748B)),
        ),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: const Color(0xFF64748B)),
              const SizedBox(height: 16),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}
