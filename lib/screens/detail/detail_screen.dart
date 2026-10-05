import 'package:flutter/material.dart';

import '../../data/dto/daily_candle_dto.dart';
import '../../data/repository/stock_repository.dart';
import '../../models/daily_candle_cache.dart';
import '../../models/favorite_store.dart';
import '../../models/stock.dart';
import '../../theme/theme.dart';
import 'detail_period.dart';
import 'widgets/candlestick_chart.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.symbol,
    required this.favoriteStore,
  });

  final String symbol;
  final FavoriteStore favoriteStore;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final StockRepository _repository = StockRepository();
  final DailyCandleCache _cache = DailyCandleCache();

  Stock? _stock;
  List<DailyCandleDto> _candles = [];

  List<DailyCandleDto> _calculationCandles = [];

  DetailPeriod _period = DetailPeriod.oneMonth;

  bool _isLoadingStock = true;
  bool _isLoadingCandles = true;

  @override
  void initState() {
    super.initState();

    widget.favoriteStore.addListener(_handleFavoriteChanged);

    _loadInitialData();
  }

  @override
  void dispose() {
    widget.favoriteStore.removeListener(_handleFavoriteChanged);

    _repository.dispose();

    super.dispose();
  }

  void _handleFavoriteChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadStock(), _loadPeriod(_period)]);
  }

  Future<void> _loadStock() async {
    try {
      final stock = await _repository.fetchStock(widget.symbol);

      if (!mounted) return;

      setState(() {
        _stock = stock;
        _isLoadingStock = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingStock = false;
      });
    }
  }

  Future<void> _loadPeriod(DetailPeriod period) async {
    setState(() {
      _period = period;
      _isLoadingCandles = true;
    });

    final end = DateTime.now();
    final displayStart = period.startDate(end);
    final requestStart = displayStart.subtract(const Duration(days: 7));

    try {
      if (!_cache.covers(start: requestStart, end: end)) {
        final candles = await _repository.fetchDailyCandles(
          symbol: widget.symbol,
          start: requestStart,
          end: end,
        );

        _cache.replace(start: requestStart, end: end, items: candles);
      }

      final visible = _cache.slice(start: displayStart, end: end);

      final calculationCandles = _cache.slice(start: requestStart, end: end);

      if (!mounted) return;

      setState(() {
        _candles = visible;
        _calculationCandles = calculationCandles;
        _isLoadingCandles = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingCandles = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoadingStock && _stock == null) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      );
    }

    if (_stock == null) {
      return Center(
        child: Text(
          '종목 정보를 불러오지 못했습니다.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
      );
    }

    final stock = _stock!;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _DetailHeader(
            stock: stock,
            isFavorite: widget.favoriteStore.contains(stock.symbol),
            onBack: () => Navigator.pop(context),
            onFavoriteTap: () {
              widget.favoriteStore.toggle(stock.symbol);
            },
          ),
        ),

        SliverToBoxAdapter(child: _CurrentPriceSection(stock: stock)),

        SliverToBoxAdapter(
          child: _PeriodTabs(selected: _period, onSelected: _loadPeriod),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              context.dimens.space4,
              context.dimens.space4,
              context.dimens.space4,
              context.dimens.space4,
            ),
            child: _isLoadingCandles
                ? SizedBox(
                    height: 230,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colors.accentDefault,
                      ),
                    ),
                  )
                : CandlestickChart(candles: _candles),
          ),
        ),

        SliverToBoxAdapter(child: _SummaryCard(stock: stock)),

        SliverToBoxAdapter(child: SizedBox(height: context.dimens.space6)),
        
        SliverToBoxAdapter(
          child: _DailyPriceTable(
            candles: _candles,
            calculationCandles: _calculationCandles,
          )
        ),

        SliverToBoxAdapter(child: SizedBox(height: context.dimens.space6)),

      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.stock,
    required this.isFavorite,
    required this.onBack,
    required this.onFavoriteTap,
  });

  final Stock stock;
  final bool isFavorite;
  final VoidCallback onBack;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        dimens.space2,
        dimens.space3,
        dimens.space3,
        dimens.space2,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                SizedBox(height: dimens.space1),
                Text(
                  '${stock.symbol} · ${stock.market}',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 12,
                    fontWeight: AppTypography.regular,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onFavoriteTap,
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite
                  ? colors.favoriteActive
                  : colors.favoriteInactive,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPriceSection extends StatelessWidget {
  const _CurrentPriceSection({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final price = stock.currentPrice;
    final change = stock.change ?? 0;
    final rate = stock.changeRate ?? 0;

    final Color changeColor;
    final String arrow;
    final String prefix;

    if (change > 0) {
      changeColor = colors.priceUpText;
      arrow = '▲';
      prefix = '+';
    } else if (change < 0) {
      changeColor = colors.priceDownText;
      arrow = '▼';
      prefix = '';
    } else {
      changeColor = colors.priceFlatText;
      arrow = '';
      prefix = '';
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price == null ? '-' : _formatNumber(price),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 32,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(width: dimens.space3),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '$arrow$prefix${_formatNumber(change)} '
              '($prefix${rate.toStringAsFixed(2)}%)',
              style: TextStyle(
                color: changeColor,
                fontSize: 14,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.selected, required this.onSelected});

  final DetailPeriod selected;
  final ValueChanged<DetailPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Row(
        children: DetailPeriod.values.map((period) {
          final isSelected = period == selected;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: dimens.space1),
              child: InkWell(
                borderRadius: BorderRadius.circular(dimens.radiusMd),
                onTap: () => onSelected(period),
                child: Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accentBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(dimens.radiusMd),
                  ),
                  child: Text(
                    period.label,
                    style: TextStyle(
                      color: isSelected
                          ? colors.accentDefault
                          : colors.textTertiary,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? AppTypography.bold
                          : AppTypography.medium,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stock});

  final Stock stock;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: dimens.space4),
      padding: EdgeInsets.all(dimens.space4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '시가',
                  value: _formatNullable(stock.openPrice),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: '고가',
                  value: _formatNullable(stock.highPrice),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: '저가',
                  value: _formatNullable(stock.lowPrice),
                ),
              ),
            ],
          ),

          SizedBox(height: dimens.space5),

          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '거래량',
                  value: _formatVolume(stock.accumulatedVolume),
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  label: '시가총액',
                  value: _formatMarketCap(stock.marketCap),
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 12,
            fontWeight: AppTypography.regular,
          ),
        ),
        SizedBox(height: dimens.space1),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: AppTypography.medium,
          ),
        ),
      ],
    );
  }
}

String _formatNullable(int? value) {
  if (value == null) return '-';

  return _formatNumber(value);
}

String _formatVolume(int? value) {
  if (value == null) return '-';

  return '${_formatNumber(value ~/ 1000)}천';
}

String _formatMarketCap(int? value) {
  if (value == null) return '-';

  return '${_formatNumber(value ~/ 1000000000000)}조';
}

String _formatNumber(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);

    final remaining = digits.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  return negative ? '-$buffer' : buffer.toString();
}

class _DailyPriceTable extends StatelessWidget {
  const _DailyPriceTable({
    required this.candles,
    required this.calculationCandles,
  });

  final List<DailyCandleDto> candles;
  final List<DailyCandleDto> calculationCandles;
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    if (candles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '일별 시세',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: AppTypography.bold,
            ),
          ),
          SizedBox(height: dimens.space4),

          Row(
            children: const [
              Expanded(child: _TableHeader('날짜')),
              Expanded(child: _TableHeader('종가', align: TextAlign.right)),
              Expanded(child: _TableHeader('등락', align: TextAlign.right)),
              Expanded(child: _TableHeader('거래량', align: TextAlign.right)),
            ],
          ),

          SizedBox(height: dimens.space2),

          ...List.generate(candles.length, (index) {
            final reversedIndex = candles.length - 1 - index;

            final candle = candles[reversedIndex];

            int? change;

            final calculationIndex = calculationCandles.indexWhere(
              (item) => item.date == candle.date,
            );

            if (calculationIndex > 0) {
              final previous = calculationCandles[calculationIndex - 1];

              change = candle.close - previous.close;
            }

            return _DailyPriceRow(candle: candle, change: change);
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text, {this.align = TextAlign.left});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        color: context.colors.textTertiary,
        fontSize: 12,
        fontWeight: AppTypography.regular,
      ),
    );
  }
}

class _DailyPriceRow extends StatelessWidget {
  const _DailyPriceRow({required this.candle, required this.change});

  final DailyCandleDto candle;
  final int? change;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;

    final Color changeColor;

    if (change == null || change == 0) {
      changeColor = colors.priceFlatText;
    } else if (change! > 0) {
      changeColor = colors.priceUpText;
    } else {
      changeColor = colors.priceDownText;
    }

    final prefix = change != null && change! > 0 ? '+' : '';

    return Container(
      padding: EdgeInsets.symmetric(vertical: dimens.space3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.borderSubtle,
            width: dimens.borderHairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDate(candle.date),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              _formatNumber(candle.close),
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              change == null ? '-' : '$prefix${_formatNumber(change!)}',
              textAlign: TextAlign.right,
              style: TextStyle(color: changeColor, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              _formatNumber(candle.volume),
              textAlign: TextAlign.right,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$month.$day';
}
