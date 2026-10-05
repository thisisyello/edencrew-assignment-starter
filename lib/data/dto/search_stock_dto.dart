class SearchStockDto {
  const SearchStockDto({
    required this.symbol,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.nationCode,
    required this.category,
  });

  final String symbol;
  final String name;
  final String typeCode;
  final String typeName;
  final String url;
  final String nationCode;
  final String category;

  factory SearchStockDto.fromJson(Map<String, dynamic> json) {
    return SearchStockDto(
      symbol: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      typeCode: json['typeCode'] as String? ?? '',
      typeName: json['typeName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      nationCode: json['nationCode'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  bool get isDomesticStock {
    return nationCode == 'KOR' &&
        category == 'stock' &&
        RegExp(r'^\d{6}$').hasMatch(symbol);
  }

  String get id => 'domestic:$symbol';
}
