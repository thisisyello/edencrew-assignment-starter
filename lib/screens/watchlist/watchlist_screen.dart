import 'package:flutter/material.dart';

import '../../data/repository/stock_repository.dart';
import '../../models/favorite_store.dart';
import '../../models/stock.dart';
import '../detail/detail_screen.dart';
import '../../widgets/stock_list_row.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../theme/theme.dart';

enum WatchlistSort { price, changeRate, name }

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    super.key,
    required this.favoriteStore,
    required this.onSearchTap,
  });

  final FavoriteStore favoriteStore;
  final VoidCallback onSearchTap;

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final StockRepository _repository = StockRepository();

  WatchlistSort _sort = WatchlistSort.name;

  List<Stock> _stocks = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<String> get _watchlistSymbols => widget.favoriteStore.symbols.toList();

  @override
  void initState() {
    super.initState();
    widget.favoriteStore.addListener(_handleFavoriteChanged);
    _loadWatchlist();
  }

  void _handleFavoriteChanged() {
    _loadWatchlist();
  }

  @override
  void dispose() {
    widget.favoriteStore.removeListener(_handleFavoriteChanged);

    _repository.dispose();

    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stocks = await _repository.fetchWatchlist(_watchlistSymbols);

      if (!mounted) return;

      setState(() {
        _stocks = stocks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Stock> get _sortedStocks {
    final stocks = [..._stocks];

    switch (_sort) {
      case WatchlistSort.price:
        stocks.sort((a, b) {
          if (a.currentPrice == null) return 1;
          if (b.currentPrice == null) return -1;

          return b.currentPrice!.compareTo(a.currentPrice!);
        });

      case WatchlistSort.changeRate:
        stocks.sort((a, b) {
          if (a.changeRate == null) return 1;
          if (b.changeRate == null) return -1;

          return b.changeRate!.compareTo(a.changeRate!);
        });

      case WatchlistSort.name:
        stocks.sort((a, b) => a.name.compareTo(b.name));
    }

    return stocks;
  }

  String get _sortLabel {
    switch (_sort) {
      case WatchlistSort.price:
        return '현재가순';
      case WatchlistSort.changeRate:
        return '등락률순';
      case WatchlistSort.name:
        return '가나다순';
    }
  }

  Future<void> _openSortSheet() async {
    final selected = await showModalBottomSheet<WatchlistSort>(
      context: context,
      backgroundColor: context.colors.surfaceOverlay,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (context) {
        return _SortBottomSheet(
          selected: _sort,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _sort = selected;
    });
  }

  Future<void> _refresh() async {
    await _loadWatchlist();
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
              padding: EdgeInsets.symmetric(
                horizontal: dimens.space4, // 16
                vertical: dimens.space3, // 12
              ),
              child: Row(
                children: [
                  Text(
                    '관심',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontWeight: AppTypography.bold,
                      fontSize: 19,
                      height: 22 / 19,
                      letterSpacing: -0.2,
                      color: colors.textPrimary,
                    ),
                  ),

                  const Spacer(),

                  InkWell(
                    onTap: _openSortSheet,
                    borderRadius: BorderRadius.circular(dimens.radiusSm),
                    child: Padding(
                      padding: EdgeInsets.all(
                        dimens.space1, // 4
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortLabel,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontWeight: AppTypography.medium,
                              fontSize: 15,
                              height: 20 / 15,
                              letterSpacing: -0.1,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_downward,
                            size: dimens.iconMd, // 20
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    width: dimens.space4, // 16
                  ),

                  InkWell(
                    onTap: _refresh,
                    child: Icon(
                      Icons.refresh,
                      size: dimens.iconMd, // 20
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: _buildBody()),

            AppBottomNavigation(
              currentTab: AppBottomTab.watchlist,
              onWatchlistTap: () {},
              onSearchTap: widget.onSearchTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _stocks.isEmpty) {
      return ListView.separated(
        itemCount: _watchlistSymbols.length,
        separatorBuilder: (_, _) => Divider(
          height: context.dimens.borderHairline,
          thickness: context.dimens.borderHairline,
          color: context.colors.borderSubtle,
        ),
        itemBuilder: (_, index) {
          return _LoadingWatchlistRow(symbol: _watchlistSymbols[index]);
        },
      );
    }

    if (_errorMessage != null && _stocks.isEmpty) {
      return Center(
        child: Text(
          '데이터를 불러오지 못했습니다.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    if (_stocks.isEmpty) {
      return const _WatchlistEmpty();
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _sortedStocks.length,
      separatorBuilder: (_, _) => Divider(
        height: context.dimens.borderHairline,
        thickness: context.dimens.borderHairline,
        color: context.colors.borderSubtle,
      ),
      itemBuilder: (context, index) {
        final stock = _sortedStocks[index];
        return _WatchlistRow(
          stock: stock,
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

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.stock, required this.onTap});

  final Stock stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return StockListRow(
      name: stock.name,
      symbol: stock.symbol,
      market: stock.market,
      onTap: onTap,
      trailing: stock.hasQuote
          ? _PriceInfo(stock: stock)
          : const _PriceSkeleton(),
    );
  }
}

class _PriceInfo extends StatelessWidget {
  const _PriceInfo({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final change = stock.change ?? 0;
    final changeRate = stock.changeRate ?? 0;

    final Color changeColor;

    if (change > 0) {
      changeColor = colors.priceUpText;
    } else if (change < 0) {
      changeColor = colors.priceDownText;
    } else {
      changeColor = colors.priceFlatText;
    }

    final changePrefix = change > 0 ? '+' : '';
    final ratePrefix = changeRate > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _formatNumber(stock.currentPrice!),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.medium,
            fontSize: 15,
            height: 20 / 15,
            letterSpacing: -0.1,
            color: colors.textPrimary,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          '$changePrefix${_formatNumber(change)} '
          '($ratePrefix${changeRate.toStringAsFixed(2)}%)',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: 11,
            height: 14 / 11,
            letterSpacing: 0,
            color: changeColor,
          ),
        ),
      ],
    );
  }
}

class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 64,
          height: 16,
          decoration: BoxDecoration(
            color: colors.feedbackSkeleton,
            borderRadius: BorderRadius.circular(
              dimens.radiusSm, // 4
            ),
          ),
        ),

        const SizedBox(height: 2),

        Container(
          width: 48,
          height: 12,
          decoration: BoxDecoration(
            color: colors.feedbackSkeleton,
            borderRadius: BorderRadius.circular(dimens.radiusSm),
          ),
        ),
      ],
    );
  }
}

class _LoadingWatchlistRow extends StatelessWidget {
  const _LoadingWatchlistRow({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              symbol,
              style: TextStyle(color: colors.textTertiary, fontSize: 12),
            ),
          ),
          const _PriceSkeleton(),
        ],
      ),
    );
  }
}

class _WatchlistEmpty extends StatelessWidget {
  const _WatchlistEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 40, color: colors.textTertiary),

            SizedBox(
              height: dimens.space3, // 12
            ),

            Text(
              '관심 종목이 없습니다',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: AppTypography.bold,
                fontSize: 19,
                height: 22 / 19,
                letterSpacing: -0.2,
                color: colors.textSecondary,
              ),
            ),

            SizedBox(
              height: dimens.space3, // 12
            ),

            Text(
              '검색 탭에서 종목을 찾아\n별 아이콘을 눌러 추가해 주세요.',
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
      ),
    );
  }
}

class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet({required this.selected});

  final WatchlistSort selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 1),

        SizedBox(
          height: 64,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space6, // 24
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '정렬',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: AppTypography.bold,
                  fontSize: 19,
                  height: 22 / 19,
                  letterSpacing: -0.2,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),

        _SortOption(
          label: '현재가순',
          value: WatchlistSort.price,
          selected: selected,
        ),

        _SortOption(
          label: '등락률순',
          value: WatchlistSort.changeRate,
          selected: selected,
        ),

        _SortOption(
          label: '가나다순',
          value: WatchlistSort.name,
          selected: selected,
        ),

        const SizedBox(height: 34),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.value,
    required this.selected,
  });

  final String label;
  final WatchlistSort value;
  final WatchlistSort selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final isSelected = value == selected;

    return InkWell(
      onTap: () => Navigator.pop(context, value),
      child: SizedBox(
        height: dimens.rowMinHeight, // 56
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space6, // 24
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontWeight: AppTypography.medium,
                    fontSize: 15,
                    height: 20 / 15,
                    letterSpacing: -0.1,
                    color: colors.textPrimary,
                  ),
                ),
              ),

              if (isSelected)
                Icon(Icons.check, size: 24, color: colors.textPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final position = digits.length - i;

    buffer.write(digits[i]);

    if (position > 1 && position % 3 == 1) {
      buffer.write(',');
    }
  }

  return '${value < 0 ? '-' : ''}$buffer';
}
