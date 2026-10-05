enum DetailPeriod { oneMonth, threeMonths, sixMonths, oneYear }

extension DetailPeriodExtension on DetailPeriod {
  String get label {
    switch (this) {
      case DetailPeriod.oneMonth:
        return '1개월';
      case DetailPeriod.threeMonths:
        return '3개월';
      case DetailPeriod.sixMonths:
        return '6개월';
      case DetailPeriod.oneYear:
        return '1년';
    }
  }

  DateTime startDate(DateTime end) {
    switch (this) {
      case DetailPeriod.oneMonth:
        return DateTime(end.year, end.month - 1, end.day);

      case DetailPeriod.threeMonths:
        return DateTime(end.year, end.month - 3, end.day);

      case DetailPeriod.sixMonths:
        return DateTime(end.year, end.month - 6, end.day);

      case DetailPeriod.oneYear:
        return DateTime(end.year - 1, end.month, end.day);
    }
  }
}
