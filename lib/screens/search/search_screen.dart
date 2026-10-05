import 'package:flutter/material.dart';

import '../../data/dto/search_stock_dto.dart';
import '../../data/repository/stock_repository.dart';
import '../../models/favorite_store.dart';
import '../detail/detail_screen.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/stock_list_row.dart';
import '../../theme/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.favoriteStore,
    required this.onWatchlistTap,
  });

  final FavoriteStore favoriteStore;
  final VoidCallback onWatchlistTap;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final StockRepository _repository = StockRepository();
  final TextEditingController _controller = TextEditingController();

  List<SearchStockDto> _results = [];

  String _query = '';
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    widget.favoriteStore.addListener(_handleFavoriteChanged);
  }

  @override
  void dispose() {
    widget.favoriteStore.removeListener(_handleFavoriteChanged);

    _controller.dispose();
    _repository.dispose();

    super.dispose();
  }

  void _handleFavoriteChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _search(String value) async {
    final query = value.trim();

    setState(() {
      _query = query;
      _errorMessage = null;
    });

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });

      return;
    }

    setState(() {
      _isSearching = true;
    });

    // 검색 도중 사용자가 다른 문자를 입력했을 때
    // 오래된 응답으로 화면이 덮이는 것을 방지
    final requestedQuery = query;

    try {
      final results = await _repository.searchStocks(query);

      if (!mounted) return;

      if (_controller.text.trim() != requestedQuery) {
        return;
      }

      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      if (_controller.text.trim() != requestedQuery) {
        return;
      }

      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _clearSearch() {
    _controller.clear();

    setState(() {
      _query = '';
      _results = [];
      _isSearching = false;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();
  }

  void _toggleFavorite(SearchStockDto stock) {
    final wasFavorite = widget.favoriteStore.contains(stock.symbol);

    widget.favoriteStore.toggle(stock.symbol);

    _showFavoriteToast(added: !wasFavorite,);
  }

  void _showFavoriteToast({required bool added}) {
    final colors = context.colors;
    final dimens = context.dimens;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,

          margin: EdgeInsets.only(
            left: dimens.space4, // 16
            right: dimens.space4, // 16
            bottom: 88,
          ),

          padding: EdgeInsets.zero,

          content: Container(
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: dimens.space4, // 16
            ),
            decoration: BoxDecoration(
              color: colors.surfaceOverlay,
              borderRadius: BorderRadius.circular(
                dimens.radiusLg, // 12
              ),
              border: Border.all(
                color: colors.borderSubtle,
                width: dimens.borderHairline, // 1
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  added ? Icons.star : Icons.star_border,
                  size: 18,
                  color: added ? colors.favoriteActive : colors.textSecondary,
                ),

                SizedBox(
                  width: dimens.space2, // 8
                ),

                Expanded(
                  child: Text(
                    added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.bold,
                      fontSize: 13,
                      height: 18 / 13,
                      letterSpacing: 0,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                dimens.space4, // left 16
                dimens.space2, // top 8
                dimens.space4, // right 16
                dimens.space3, // bottom 12
              ),
              child: _SearchField(
                controller: _controller,
                onChanged: _search,
                onClear: _clearSearch,
              ),
            ),

            Expanded(child: _buildBody()),

            AppBottomNavigation(
              currentTab: AppBottomTab.search,
              onWatchlistTap: widget.onWatchlistTap,
              onSearchTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return const _InitialSearchState();
    }

    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          '검색 중 오류가 발생했습니다.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
      );
    }

    if (_results.isEmpty) {
      return _NoSearchResult(query: _query);
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, _) => Divider(
        height: context.dimens.borderHairline,
        thickness: context.dimens.borderHairline,
        color: context.colors.borderSubtle,
      ),
      itemBuilder: (context, index) {
        final stock = _results[index];

        return _SearchResultRow(
          stock: stock,
          query: _query,
          isFavorite: widget.favoriteStore.contains(stock.symbol),
          onFavoriteTap: () {
            _toggleFavorite(stock);
          },
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailScreen(
                  symbol: stock.symbol,
                  favoriteStore: widget.favoriteStore,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: dimens.iconSm, color: colors.textTertiary),

          SizedBox(width: dimens.space2),

          Expanded(
            child: SizedBox(
              height: 20,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLines: 1,
                cursorColor: colors.textPrimary,
                cursorHeight: 18,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: AppTypography.medium,
                  fontSize: 15,
                  height: 20 / 15,
                  letterSpacing: -0.1,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '종목명 또는 종목코드',
                  hintStyle: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: AppTypography.medium,
                    fontSize: 15,
                    height: 20 / 15,
                    letterSpacing: -0.1,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          if (controller.text.isNotEmpty) ...[
            SizedBox(width: dimens.space2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Icon(
                Icons.close,
                size: dimens.iconSm,
                color: colors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InitialSearchState extends StatelessWidget {
  const _InitialSearchState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 40, color: colors.textTertiary),

          SizedBox(height: dimens.space3), // 12

          Text(
            '종목을 검색해 보세요',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.bold,
              fontSize: 19,
              height: 22 / 19,
              letterSpacing: -0.2,
              color: colors.textSecondary,
            ),
          ),

          SizedBox(height: dimens.space3), // 12

          Text(
            '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.regular,
              fontSize: 11,
              height: 14 / 11,
              letterSpacing: 0,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchResult extends StatelessWidget {
  const _NoSearchResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: colors.textTertiary),

          SizedBox(height: dimens.space3),

          Text(
            '검색 결과가 없습니다',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.bold,
              fontSize: 19,
              height: 22 / 19,
              letterSpacing: -0.2,
              color: colors.textSecondary,
            ),
          ),

          SizedBox(height: dimens.space3),

          Text(
            '\'$query\'와 일치하는 검색 결과를\n찾지 못했습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontWeight: AppTypography.regular,
              fontSize: 11,
              height: 14 / 11,
              letterSpacing: 0,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.stock,
    required this.query,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  final SearchStockDto stock;
  final String query;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return StockListRow(
      name: stock.name,
      symbol: stock.symbol,
      market: stock.typeName,
      highlightQuery: query,
      onTap: onTap,
      trailing: InkWell(
        onTap: onFavoriteTap,
        child: Icon(
          isFavorite ? Icons.star : Icons.star_border,
          size: 22,
          color: isFavorite ? colors.favoriteActive : colors.favoriteInactive,
        ),
      ),
    );
  }
}
