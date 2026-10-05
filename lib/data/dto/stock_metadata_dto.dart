class StockMetadataDto {
  const StockMetadataDto({
    required this.symbol,
    required this.name,
    required this.market,
  });

  final String symbol;
  final String name;
  final String market;

  factory StockMetadataDto.fromJson(Map<String, dynamic> json) {
    return StockMetadataDto(
      symbol: json['symbolCode'] as String,
      name: json['stockName'] as String,
      market: json['stockExchangeNameKor'] as String,
    );
  }
}
