import '../data/dto/daily_candle_dto.dart';

class DailyCandleCache {
  DateTime? _start;
  DateTime? _end;

  List<DailyCandleDto> _items = [];

  bool covers({required DateTime start, required DateTime end}) {
    if (_start == null || _end == null) {
      return false;
    }

    return !_start!.isAfter(start) && !_end!.isBefore(end);
  }

  void replace({
    required DateTime start,
    required DateTime end,
    required List<DailyCandleDto> items,
  }) {
    _start = start;
    _end = end;
    _items = items;
  }

  List<DailyCandleDto> slice({required DateTime start, required DateTime end}) {
    return _items.where((item) {
      final date = item.date;

      final afterStart = date.isAtSameMomentAs(start) || date.isAfter(start);

      final beforeEnd = date.isAtSameMomentAs(end) || date.isBefore(end);

      return afterStart && beforeEnd;
    }).toList();
  }
}
