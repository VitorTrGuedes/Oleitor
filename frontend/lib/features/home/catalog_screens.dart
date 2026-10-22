import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/favorite_store.dart';
import '../../data/models.dart';
import '../manga/manga_detail_screen.dart';

const _accent = Color(0xFFB18AF5);
const _ink = Color(0xFFF4F1FA);
const _muted = Color(0xFFA6A2AF);
const _surface = Color(0xFF1E1D24);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onExplore,
    required this.onFavorites,
    required this.onLibrary,
    this.apiClient,
  });

  final VoidCallback onExplore;
  final VoidCallback onFavorites;
  final VoidCallback onLibrary;
  final ApiClient? apiClient;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  List<Manga> _favorites = [];
  List<Map<String, dynamic>> _sources = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _loadHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final favorites = await FavoriteStore.getFavorites();
      List<Map<String, dynamic>> sources = [];
      String? sourceError;
      try {
        sources = await _api.getSources();
      } on Exception catch (error) {
        sourceError = error.toString();
      }
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _sources = sources;
        _error = sourceError;
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

  Future<void> _refreshFavorites() async {
    final favorites = await FavoriteStore.getFavorites();
    if (mounted) setState(() => _favorites = favorites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141318),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHome,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OLEITOR',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Seu universo de histórias',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar início',
                    onPressed: _loadHome,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF262332), Color(0xFF4A233A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Stack(
                  children: [
                    const Positioned(
                      right: -2,
                      bottom: -6,
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Color(0x33FFFFFF),
                        size: 112,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LEIA NO SEU RITMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 240,
                          child: Text(
                            'Uma nova história espera por você.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _sources.isEmpty
                              ? 'Explore sua biblioteca e organize suas leituras.'
                              : 'Descubra títulos em ${_sources.length} fonte${_sources.length == 1 ? '' : 's'}.',
                          style: const TextStyle(
                            color: Color(0xFFD8D5DF),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: widget.onExplore,
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Explorar catálogo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Acesse rápido',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onExplore,
                    child: const Text('Ver catálogo'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Descobrir',
                      color: const Color(0xFFFFF0F2),
                      iconColor: _accent,
                      onTap: widget.onExplore,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Favoritos',
                      color: const Color(0xFFFFF4E6),
                      iconColor: const Color(0xFFEB8B18),
                      onTap: widget.onFavorites,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.library_books_rounded,
                      label: 'Biblioteca',
                      color: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF5367C5),
                      onTap: widget.onLibrary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sua lista de leitura',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_favorites.isNotEmpty)
                    TextButton(
                      onPressed: widget.onFavorites,
                      child: const Text('Ver todos'),
                    ),
                ],
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_favorites.isEmpty)
                _EmptyPanel(
                  icon: Icons.bookmark_add_outlined,
                  title: 'Monte sua lista',
                  message:
                      'Toque no coração de um título para guardar aqui e continuar depois.',
                  action: TextButton(
                    onPressed: widget.onExplore,
                    child: const Text('Encontrar histórias'),
                  ),
                )
              else
                SizedBox(
                  height: 218,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _favorites.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _FavoritePreview(
                      manga: _favorites[index],
                      onChanged: _refreshFavorites,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, color: _accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Fontes conectadas',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!_loading && _error == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sources
                        .map(
                          (source) => Chip(
                            avatar: const Icon(
                              Icons.bolt_rounded,
                              color: _accent,
                              size: 16,
                            ),
                            label: Text(source['name'] as String),
                            backgroundColor: _surface,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                )
              else if (!_loading && _error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Não foi possível carregar as fontes: $_error',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _sources = [];
  List<Manga> _results = [];
  String _sourceId = 'mangadex';
  String _language = 'pt-br';
  bool _loading = false;
  String? _error;
  bool _searched = false;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  Future<void> _loadSources() async {
    try {
      final sources = await _api.getSources();
      if (!mounted) return;
      setState(() {
        _sources = sources;
        if (sources.isNotEmpty &&
            !sources.any((source) => source['id'] == _sourceId)) {
          _sourceId = sources.first['id'] as String;
        }
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final generation = ++_searchGeneration;
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
        _searched = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => _search(generation: generation),
    );
  }

  Future<void> _search({int? generation}) async {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    final requestGeneration = generation ?? ++_searchGeneration;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await _api.searchSourceManga(
        sourceId: _sourceId,
        search: query,
        language: _language,
      );
      if (!mounted || requestGeneration != _searchGeneration) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted || requestGeneration != _searchGeneration) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceNames = {
      for (final source in _sources)
        source['id'] as String: source['name'] as String,
    };
    return Scaffold(
      backgroundColor: const Color(0xFF141318),
      appBar: AppBar(
        title: const Text(
          'Explorar',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF141318),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            onPressed: _search,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Título, mangá, manhwa...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar busca',
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<String>(
                        value: _sources.any(
                          (source) => source['id'] == _sourceId,
                        )
                            ? _sourceId
                            : null,
                        hint: 'Fonte',
                        items: sourceNames,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sourceId = value);
                          if (_searchController.text.trim().isNotEmpty) {
                            _search();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FilterDropdown<String>(
                        value: _language,
                        hint: 'Idioma',
                        items: const {
                          'pt-br': 'Português',
                          'en': 'Inglês',
                          'es': 'Espanhol',
                        },
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _language = value);
                          if (_searchController.text.trim().isNotEmpty) {
                            _search();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultados',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_results.isNotEmpty)
                  Text(
                    '${_results.length} títulos',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_error != null) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível buscar agora',
        message: _error!,
        action: FilledButton(
          onPressed: _search,
          child: const Text('Tentar novamente'),
        ),
      );
    }
    if (_results.isEmpty) {
      return _MessageState(
        icon: _searched ? Icons.search_off_rounded : Icons.explore_outlined,
        title: _searched
            ? 'Nenhum título encontrado'
            : 'Encontre sua próxima leitura',
        message: _searched
            ? 'Tente outro título ou ajuste o idioma da busca.'
            : 'Pesquise no catálogo conectado para descobrir novas histórias.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.61,
      ),
      itemBuilder: (context, index) => MangaCatalogCard(
        manga: _results[index],
        onChanged: () => setState(() {}),
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Manga> _favorites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final favorites = await FavoriteStore.getFavorites();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141318),
      appBar: AppBar(
        title: const Text(
          'Favoritos',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF141318),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _favorites.isEmpty
              ? const _MessageState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Sua lista está esperando',
                  message:
                      'Guarde os títulos que chamaram sua atenção tocando no coração.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: _favorites.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.61,
                    ),
                    itemBuilder: (context, index) => MangaCatalogCard(
                      manga: _favorites[index],
                      onChanged: _load,
                    ),
                  ),
                ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late Future<List<Map<String, dynamic>>> _sources = _api.getSources();

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141318),
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w900),
        ),
        backgroundColor: const Color(0xFF141318),
        actions: [
          IconButton(
            tooltip: 'Atualizar fontes',
            onPressed: () => setState(() => _sources = _api.getSources()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF30273F),
                  child: Icon(Icons.person_rounded, color: _accent, size: 30),
                ),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leitor Oleitor',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Sua experiência de leitura',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'FONTES DE CONTEÚDO',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _sources,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _InlineError(
                  message: '${snapshot.error}',
                  onRetry: () => setState(() => _sources = _api.getSources()),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.data!.isEmpty) {
                return const _EmptyPanel(
                  icon: Icons.cloud_off_outlined,
                  title: 'Nenhuma fonte conectada',
                  message: 'As fontes disponíveis aparecerão aqui.',
                );
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (source) => Card(
                        color: _surface,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF30273F),
                            child: Icon(Icons.bolt_rounded, color: _accent),
                          ),
                          title: Text(source['name'] as String),
                          subtitle: Text(source['id'] as String),
                          trailing: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF73D2A0),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'SOBRE',
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Card(
            color: _surface,
            child: ListTile(
              leading: Icon(Icons.auto_stories_rounded, color: _accent),
              title: Text('Oleitor'),
              subtitle: Text('Versão 0.1.0'),
            ),
          ),
          const Card(
            color: _surface,
            child: ListTile(
              leading: Icon(Icons.sync_rounded, color: _accent),
              title: Text('Progresso de leitura'),
              subtitle: Text(
                'O progresso fica salvo neste dispositivo e sincroniza quando disponível.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MangaCatalogCard extends StatefulWidget {
  const MangaCatalogCard({
    super.key,
    required this.manga,
    this.onChanged,
  });

  final Manga manga;
  final VoidCallback? onChanged;

  @override
  State<MangaCatalogCard> createState() => _MangaCatalogCardState();
}

class _MangaCatalogCardState extends State<MangaCatalogCard> {
  bool _favorite = false;
  bool _checkedFavorite = false;

  @override
  void didUpdateWidget(covariant MangaCatalogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.manga.id != widget.manga.id ||
        oldWidget.manga.sourceId != widget.manga.sourceId) {
      _checkedFavorite = false;
      _loadFavorite();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedFavorite) {
      _checkedFavorite = true;
      _loadFavorite();
    }
  }

  Future<void> _loadFavorite() async {
    final favorite = await FavoriteStore.contains(widget.manga);
    if (mounted) setState(() => _favorite = favorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoriteStore.toggle(widget.manga);
    if (!mounted) return;
    setState(() => _favorite = !_favorite);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final manga = widget.manga;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MangaDetailScreen(manga: manga),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  manga.coverUrl == null
                      ? const _CoverPlaceholder()
                      : Image.network(
                          manga.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _CoverPlaceholder(),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _toggleFavorite,
                        tooltip: _favorite
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                        icon: Icon(
                          _favorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _favorite ? _accent : Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                  if (manga.status != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _statusLabel(manga.status!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      color: _ink,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    manga.author?.isNotEmpty == true
                        ? manga.author!
                        : manga.sourceId ?? manga.language,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ongoing':
        return 'EM PUBLICAÇÃO';
      case 'completed':
        return 'CONCLUÍDO';
      case 'hiatus':
        return 'PAUSADO';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }
}

class _FavoritePreview extends StatelessWidget {
  const _FavoritePreview({required this.manga, required this.onChanged});

  final Manga manga;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: MangaCatalogCard(manga: manga, onChanged: onChanged),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 7),
            child: Column(
              children: [
                Icon(icon, color: iconColor, size: 23),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            hint: Text(hint),
            borderRadius: BorderRadius.circular(14),
            items: items.entries
                .map(
                  (entry) => DropdownMenuItem<T>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: items.isEmpty ? null : onChanged,
          ),
        ),
      );
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFF2B2932),
        child: Center(
          child: Icon(
            Icons.auto_stories_rounded,
            size: 42,
            color: Color(0xFFA6A2AF),
          ),
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
              Icon(icon, size: 48, color: const Color(0xFF9A9BA6)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _EmptyPanel(
        icon: Icons.cloud_off_outlined,
        title: 'Não foi possível atualizar',
        message: message,
        action: TextButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
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
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            if (action != null) action!,
          ],
        ),
      );
}
