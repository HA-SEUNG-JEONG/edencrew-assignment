import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'codec/euc_kr.dart';
import 'daily_price_parser.dart';
import 'dto/naver_dto.dart';

// 네이버 API 호출 담당. 앱에서 인스턴스 하나만 만들어 공유.
// 응답은 bodyBytes 로 받아서 직접 디코딩 (http 패키지 body 는 EUC-KR 을 latin1 로 잘못 읽음)
class StockRepository {
  StockRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // 브라우저 UA 없으면 finance.naver.com 이 홈 화면을 돌려줌
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/128.0 Safari/537.36',
    'Referer': 'https://finance.naver.com/',
  };

  // 종목코드별 일별 시세 페이지 캐시
  final Map<String, _DailyCache> _daily = <String, _DailyCache>{};

  // 검색 자동완성. 국내 6자리 종목만 필터
  Future<List<Stock>> search(String query) async {
    final Map<String, dynamic> json = await _getJson(
      Uri.https('ac.stock.naver.com', '/ac', <String, String>{
        'q': query,
        'target': 'stock,ipo,index,marketindicator',
      }),
      utf8,
    );
    final List<dynamic> items =
        json['items'] as List<dynamic>? ?? const <dynamic>[];
    return <Stock>[
      for (final dynamic item in items)
        if (AcItemDto.fromJson(item as Map<String, dynamic>).isDomesticStock)
          AcItemDto.fromJson(item).toStock(),
    ];
  }

  // 실시간 시세. 여러 종목을 한 번에 요청, 결과는 종목코드로 맵핑
  Future<Map<String, Quote>> fetchQuotes(Iterable<String> symbols) async {
    if (symbols.isEmpty) return const <String, Quote>{};
    final Map<String, dynamic> json = await _getJson(
      Uri.https('polling.finance.naver.com', '/api/realtime', <String, String>{
        'query': 'SERVICE_ITEM:${symbols.join(',')}',
      }),
      eucKr,
    );
    return <String, Quote>{
      for (final RealtimeItemDto d in RealtimeItemDto.listFromResponse(json))
        d.cd: d.toQuote(),
    };
  }

  // 종목명, 거래소명 조회
  Future<Stock> fetchMeta(String symbol) async {
    final Map<String, dynamic> json = await _getJson(
      Uri.https(
        'stock.naver.com',
        '/api/securityFe/api/fchart/domestic/stock/$symbol',
      ),
      utf8,
    );
    return StockMetaDto.fromJson(json).toStock();
  }

  // 일별 시세. 1페이지 = 10거래일, 최신순.
  // 이미 받은 페이지는 재사용하고 부족한 페이지만 추가 요청.
  // lastPage 넘는 페이지는 네이버가 마지막 페이지를 그대로 다시 주기 때문에 요청 안 함.
  Future<List<DailyPrice>> dailyPrices(String symbol, int pages) async {
    final _DailyCache cache = _daily.putIfAbsent(symbol, _DailyCache.new);

    for (int page = 1; page <= min(pages, cache.lastPage ?? pages); page++) {
      if (cache.pages.containsKey(page)) continue;
      final DailyPage fetched = await _fetchDailyPage(symbol, page);
      cache.pages[page] = fetched.rows;
      cache.lastPage = fetched.lastPage;
    }

    final int available = min(pages, cache.lastPage ?? pages);
    return <DailyPrice>[
      for (int page = 1; page <= available; page++) ...?cache.pages[page],
    ];
  }

  Future<DailyPage> _fetchDailyPage(String symbol, int page) async {
    final Uint8List bytes = await _getBytes(
      Uri.https('finance.naver.com', '/item/sise_day.naver', <String, String>{
        'code': symbol,
        'page': '$page',
      }),
    );
    return parseDailyPage(eucKr.decode(bytes), requestedPage: page);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri, Encoding encoding) async =>
      jsonDecode(encoding.decode(await _getBytes(uri))) as Map<String, dynamic>;

  Future<Uint8List> _getBytes(Uri uri) async {
    debugPrint('GET $uri');
    final http.Response res = await _client.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw HttpException('HTTP ${res.statusCode}', uri: uri);
    }
    return res.bodyBytes;
  }
}

class _DailyCache {
  final Map<int, List<DailyPrice>> pages = <int, List<DailyPrice>>{};
  int? lastPage;
}
