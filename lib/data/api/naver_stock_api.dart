import 'dart:convert';

import 'package:http/http.dart' as http;

class NaverStockApi {
  NaverStockApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _realtimeBaseUrl =
      'https://polling.finance.naver.com/api/realtime';

  static const String _metadataBaseUrl =
      'https://stock.naver.com/api/securityFe/api/fchart/domestic/stock';

  Future<Map<String, dynamic>> fetchRealtimeQuotes(List<String> symbols) async {
    final query = 'SERVICE_ITEM:${symbols.join(',')}';

    final uri = Uri.parse(
      _realtimeBaseUrl,
    ).replace(queryParameters: {'query': query});

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('실시간 시세 조회 실패: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('실시간 시세 응답 형식이 올바르지 않습니다.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> fetchStockMetadata(String symbol) async {
    final uri = Uri.parse('$_metadataBaseUrl/$symbol');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('종목 메타데이터 조회 실패: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('종목 메타데이터 응답 형식이 올바르지 않습니다.');
    }

    return decoded;
  }

  void dispose() {
    _client.close();
  }

  Future<Map<String, dynamic>> searchStocks(String query) async {
    final uri = Uri.parse('https://ac.stock.naver.com/ac').replace(
      queryParameters: {
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('종목 검색 실패: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('종목 검색 응답 형식이 올바르지 않습니다.');
    }

    return decoded;
  }

  Future<List<dynamic>> fetchDailyCandles({
    required String symbol,
    required String startDateTime,
    required String endDateTime,
  }) async {
    final uri =
        Uri.parse(
          'https://api.stock.naver.com/chart/domestic/item/$symbol/day',
        ).replace(
          queryParameters: {
            'startDateTime': startDateTime,
            'endDateTime': endDateTime,
          },
        );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('일봉 데이터 조회 실패: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! List) {
      throw const FormatException('일봉 응답 형식이 올바르지 않습니다.');
    }

    return decoded;
  }
}
