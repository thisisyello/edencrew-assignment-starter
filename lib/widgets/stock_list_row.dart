import 'package:flutter/material.dart';

import '../theme/theme.dart';

class StockListRow extends StatelessWidget {
  const StockListRow({
    super.key,
    required this.name,
    required this.symbol,
    required this.market,
    required this.trailing,
    required this.onTap,
    this.highlightQuery,
  });

  final String name;
  final String symbol;
  final String market;
  final Widget trailing;
  final VoidCallback onTap;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: dimens.space4,
            vertical: dimens.space3,
          ),
          child: Row(
            children: [
              Expanded(
                child: _StockIdentity(
                  name: name,
                  symbol: symbol,
                  market: market,
                  highlightQuery: highlightQuery,
                ),
              ),
              SizedBox(width: dimens.space3),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _StockIdentity extends StatelessWidget {
  const _StockIdentity({
    required this.name,
    required this.symbol,
    required this.market,
    this.highlightQuery,
  });

  final String name;
  final String symbol;
  final String market;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StockName(name: name, highlightQuery: highlightQuery),
        const SizedBox(height: 2),
        Text(
          '$symbol · $market',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontWeight: AppTypography.regular,
            fontSize: 11,
            height: 14 / 11,
            letterSpacing: 0,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StockName extends StatelessWidget {
  const _StockName({required this.name, this.highlightQuery});

  final String name;
  final String? highlightQuery;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final baseStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontWeight: AppTypography.medium,
      fontSize: 15,
      height: 20 / 15,
      letterSpacing: -0.1,
      color: colors.textPrimary,
    );

    final query = highlightQuery?.trim() ?? '';

    if (query.isEmpty) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final lowerName = name.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerName.indexOf(lowerQuery);

    if (index < 0) {
      return Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseStyle,
      );
    }

    final before = name.substring(0, index);
    final matched = name.substring(index, index + query.length);
    final after = name.substring(index + query.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: matched,
            style: TextStyle(color: colors.searchHighlight),
          ),
          TextSpan(text: after),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
