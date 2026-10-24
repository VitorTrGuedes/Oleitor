import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'features/home/catalog_screens.dart';
import 'features/home/library_home_screen.dart';

const _appBackground = Color(0xFF141318);
const _appSurface = Color(0xFF1E1D24);
const _appAccent = Color(0xFFB18AF5);
const _appText = Color(0xFFF4F1FA);
const _appMuted = Color(0xFFA6A2AF);

class OleitorApp extends StatelessWidget {
  const OleitorApp({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oleitor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: _appAccent,
          primary: _appAccent,
          surface: _appSurface,
        ),
        scaffoldBackgroundColor: _appBackground,
        cardTheme: CardThemeData(
          color: _appSurface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF393741)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _appSurface,
          hintStyle: const TextStyle(color: _appMuted),
          prefixIconColor: _appMuted,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF393741)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _appAccent),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _appBackground,
          foregroundColor: _appText,
          centerTitle: false,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: _appSurface,
          indicatorColor: const Color(0xFF342A45),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? _appAccent
                  : _appMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        dividerColor: const Color(0xFF393741),
        useMaterial3: true,
      ),
      home: _AppShell(apiClient: apiClient),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({this.apiClient});

  final ApiClient? apiClient;

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      LibraryHomeScreen(
        apiClient: widget.apiClient,
        onExplore: () => setState(() => _selectedIndex = 1),
        isActive: _selectedIndex == 0,
      ),
      DiscoverScreen(apiClient: widget.apiClient),
      const FavoritesScreen(),
      ProfileScreen(apiClient: widget.apiClient),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideLayout = constraints.maxWidth >= 760;
        return Scaffold(
          body: Row(
            children: [
              if (wideLayout)
                _DesktopSidebar(
                  selectedIndex: _selectedIndex,
                  onSelected: (index) => setState(() => _selectedIndex = index),
                ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: screens,
                ),
              ),
            ],
          ),
          bottomNavigationBar: wideLayout
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: 'Biblioteca',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.search_rounded),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: 'Favoritos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Perfil',
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'Biblioteca'),
      (Icons.search_rounded, Icons.search_rounded, 'Explorar'),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoritos'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
    ];
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1A191F),
        border: Border(right: BorderSide(color: Color(0xFF302E36))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 18, 34),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF30273F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _appAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Oleitor',
                      style: TextStyle(
                        color: _appText,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (var index = 0; index < destinations.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: _SidebarItem(
                  icon: selectedIndex == index
                      ? destinations[index].$2
                      : destinations[index].$1,
                  label: destinations[index].$3,
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? _appAccent : _appMuted;
    return Material(
      color: selected ? const Color(0xFF30273F) : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 23),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
