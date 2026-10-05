import 'package:flutter/material.dart';

import '../theme/theme.dart';

enum AppBottomTab { watchlist, search }

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onWatchlistTap,
    required this.onSearchTap,
  });

  final AppBottomTab currentTab;
  final VoidCallback onWatchlistTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      padding: EdgeInsets.symmetric(vertical: dimens.space2),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        border: Border(
          top: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.star,
              label: '관심',
              active: currentTab == AppBottomTab.watchlist,
              onTap: onWatchlistTap,
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.search,
              label: '검색',
              active: currentTab == AppBottomTab.search,
              onTap: onSearchTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final color = active ? colors.navActive : colors.navInactive;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimens.space1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.regular,
                fontSize: 11,
                height: 14 / 11,
                letterSpacing: 0,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
