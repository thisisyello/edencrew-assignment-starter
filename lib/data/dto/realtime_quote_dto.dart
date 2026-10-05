class RealtimeQuoteDto {
  const RealtimeQuoteDto({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.accumulatedVolume,
    required this.countOfListedStock,
  });

  final String symbol;
  final int currentPrice;
  final int previousClose;
  final int openPrice;
  final int highPrice;
  final int lowPrice;
  final int accumulatedVolume;
  final int countOfListedStock;

  factory RealtimeQuoteDto.fromJson(Map<String, dynamic> json) {
    return RealtimeQuoteDto(
      symbol: json['cd'] as String,
      currentPrice: _toInt(json['nv']),
      previousClose: _toInt(json['pcv']),
      openPrice: _toInt(json['ov']),
      highPrice: _toInt(json['hv']),
      lowPrice: _toInt(json['lv']),
      accumulatedVolume: _toInt(json['aq']),
      countOfListedStock: _toInt(json['countOfListedStock']),
    );
  }

  int get change => currentPrice - previousClose;

  double get changeRate {
    if (previousClose == 0) return 0;

    return (currentPrice - previousClose) / previousClose * 100;
  }

  int get marketCap => currentPrice * countOfListedStock;

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return double.parse(value).toInt();
    }

    throw FormatException('숫자로 변환할 수 없는 값입니다: $value');
  }
}
