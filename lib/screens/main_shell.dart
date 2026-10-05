import 'package:flutter/material.dart';

import '../models/favorite_store.dart';
import 'search/search_screen.dart';
import 'watchlist/watchlist_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final FavoriteStore _favoriteStore = FavoriteStore();

  int _currentIndex = 0;

  @override
  void dispose() {
    _favoriteStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      WatchlistScreen(
        favoriteStore: _favoriteStore,
        onSearchTap: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      SearchScreen(
        favoriteStore: _favoriteStore,
        onWatchlistTap: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    return screens[_currentIndex];
  }
}
