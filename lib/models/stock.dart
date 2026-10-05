class Stock {
  const Stock({
    required this.id,
    required this.symbol,
    required this.name,
    required this.market,
    this.currentPrice,
    this.previousClose,
    this.openPrice,
    this.highPrice,
    this.lowPrice,
    this.accumulatedVolume,
    this.marketCap,
  });

  final String id;
  final String symbol;
  final String name;
  final String market;

  final int? currentPrice;
  final int? previousClose;
  final int? openPrice;
  final int? highPrice;
  final int? lowPrice;
  final int? accumulatedVolume;
  final int? marketCap;

  bool get hasQuote => currentPrice != null && previousClose != null;

  int? get change {
    if (!hasQuote) return null;
    return currentPrice! - previousClose!;
  }

  double? get changeRate {
    if (!hasQuote || previousClose == 0) return null;

    return (currentPrice! - previousClose!) / previousClose! * 100;
  }

  Stock copyWith({
    String? id,
    String? symbol,
    String? name,
    String? market,
    int? currentPrice,
    int? previousClose,
    int? openPrice,
    int? highPrice,
    int? lowPrice,
    int? accumulatedVolume,
    int? marketCap,
  }) {
    return Stock(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      market: market ?? this.market,
      currentPrice: currentPrice ?? this.currentPrice,
      previousClose: previousClose ?? this.previousClose,
      openPrice: openPrice ?? this.openPrice,
      highPrice: highPrice ?? this.highPrice,
      lowPrice: lowPrice ?? this.lowPrice,
      accumulatedVolume: accumulatedVolume ?? this.accumulatedVolume,
      marketCap: marketCap ?? this.marketCap,
    );
  }
}
