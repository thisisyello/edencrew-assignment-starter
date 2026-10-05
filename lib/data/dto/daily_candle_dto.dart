class DailyCandleDto {
  const DailyCandleDto({
    required this.date,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  final DateTime date;
  final int close;
  final int open;
  final int high;
  final int low;
  final int volume;

  factory DailyCandleDto.fromJson(Map<String, dynamic> json) {
    final localDate = json['localDate'] as String;

    return DailyCandleDto(
      date: DateTime(
        int.parse(localDate.substring(0, 4)),
        int.parse(localDate.substring(4, 6)),
        int.parse(localDate.substring(6, 8)),
      ),
      close: _toInt(json['closePrice']),
      open: _toInt(json['openPrice']),
      high: _toInt(json['highPrice']),
      low: _toInt(json['lowPrice']),
      volume: _toInt(json['accumulatedTradingVolume']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.parse(value.replaceAll(',', ''));
    }

    throw FormatException('숫자로 변환할 수 없는 값입니다: $value');
  }
}
