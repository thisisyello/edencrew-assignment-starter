import '../api/naver_stock_api.dart';
import '../dto/realtime_quote_dto.dart';
import '../dto/stock_metadata_dto.dart';
import '../dto/search_stock_dto.dart';
import '../dto/daily_candle_dto.dart';
import '../../models/stock.dart';

class StockRepository {
  StockRepository({NaverStockApi? api}) : _api = api ?? NaverStockApi();

  final NaverStockApi _api;

  Future<List<Stock>> fetchWatchlist(List<String> symbols) async {
    if (symbols.isEmpty) {
      return [];
    }

    // 1. 메타데이터 조회
    final metadataList = await Future.wait(symbols.map(_fetchMetadata));

    // 2. 실시간 시세 원본 응답
    final realtimeJson = await _api.fetchRealtimeQuotes(symbols);

    // 실제 응답 구조 확인 후 여기 파싱 로직 확정
    final quotes = _parseRealtimeQuotes(realtimeJson);

    final quoteMap = <String, RealtimeQuoteDto>{
      for (final quote in quotes) quote.symbol: quote,
    };

    // 3. metadata + quote 결합
    return metadataList.map((metadata) {
      final quote = quoteMap[metadata.symbol];

      return Stock(
        id: 'domestic:${metadata.symbol}',
        symbol: metadata.symbol,
        name: metadata.name,
        market: metadata.market,
        currentPrice: quote?.currentPrice,
        previousClose: quote?.previousClose,
        openPrice: quote?.openPrice,
        highPrice: quote?.highPrice,
        lowPrice: quote?.lowPrice,
        accumulatedVolume: quote?.accumulatedVolume,
        marketCap: quote?.marketCap,
      );
    }).toList();
  }

  Future<StockMetadataDto> _fetchMetadata(String symbol) async {
    final json = await _api.fetchStockMetadata(symbol);

    return StockMetadataDto.fromJson(json);
  }

  List<RealtimeQuoteDto> _parseRealtimeQuotes(Map<String, dynamic> json) {
    final result = json['result'];

    if (result is! Map<String, dynamic>) {
      throw const FormatException('실시간 시세 result가 없습니다.');
    }

    final areas = result['areas'];

    if (areas is! List) {
      throw const FormatException('실시간 시세 areas가 없습니다.');
    }

    for (final area in areas) {
      if (area is! Map<String, dynamic>) {
        continue;
      }

      if (area['name'] != 'SERVICE_ITEM') {
        continue;
      }

      final datas = area['datas'];

      if (datas is! List) {
        throw const FormatException('SERVICE_ITEM datas가 없습니다.');
      }

      return datas
          .whereType<Map<String, dynamic>>()
          .map(RealtimeQuoteDto.fromJson)
          .toList();
    }

    return [];
  }

  void dispose() {
    _api.dispose();
  }

  Future<List<SearchStockDto>> searchStocks(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      return [];
    }

    final json = await _api.searchStocks(trimmedQuery);

    final items = json['items'];

    if (items is! List) {
      throw const FormatException('검색 결과 items가 없습니다.');
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(SearchStockDto.fromJson)
        .where((stock) => stock.isDomesticStock)
        .toList();
  }

  Future<List<DailyCandleDto>> fetchDailyCandles({
    required String symbol,
    required DateTime start,
    required DateTime end,
  }) async {
    final json = await _api.fetchDailyCandles(
      symbol: symbol,
      startDateTime: _formatDateTime(start),
      endDateTime: _formatDateTime(end),
    );

    return json
        .whereType<Map<String, dynamic>>()
        .map(DailyCandleDto.fromJson)
        .toList();
  }

  String _formatDateTime(DateTime date) {
    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${date.year}'
        '${twoDigits(date.month)}'
        '${twoDigits(date.day)}'
        '${twoDigits(date.hour)}'
        '${twoDigits(date.minute)}';
  }

  Future<Stock> fetchStock(String symbol) async {
    final stocks = await fetchWatchlist([symbol]);

    if (stocks.isEmpty) {
      throw StateError('종목 정보를 찾을 수 없습니다: $symbol');
    }

    return stocks.first;
  }
}

