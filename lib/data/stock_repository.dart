import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/models.dart';
import 'codec/euc_kr.dart';
import 'daily_price_parser.dart';
import 'dto/naver_dto.dart';

/// Naver endpoint 4종 호출 + 일별 시세 페이지 캐시.
///
/// 앱에 인스턴스 하나만 두고 세 화면이 공유합니다. 응답은 항상 `bodyBytes` 로 받아
/// 인코딩을 직접 결정합니다 — `package:http` 의 `body` 는 모르는 charset 을 latin1 로
/// 조용히 처리하기 때문입니다.
class StockRepository {
  StockRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// finance.naver.com 은 브라우저 UA 가 없으면 네이버 홈을 돌려줍니다.
  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/128.0 Safari/537.36',
    'Referer': 'https://finance.naver.com/',
  };

  /// 종목별 일별 시세 캐시. page 번호 → 그 페이지의 행. lastPage 는 첫 응답에서 확정.
  final Map<String, _DailyCache> _daily = <String, _DailyCache>{};

  // ---------------------------------------------------------------- endpoints

  /// 1. 검색 자동완성. 국내 6자리 종목만 남깁니다.
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

  /// 2. 실시간 시세 — 관심 종목 전체를 요청 1번으로. 결과는 symbol 로 색인.
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

  /// 3. 종목 메타데이터 (종목명·거래소명).
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

  /// 4. 일별 시세 — [pages] 페이지분(1페이지 = 10거래일)을 최신순으로 돌려줍니다.
  ///
  /// 이미 받은 페이지는 재사용하고 부족한 페이지만 순서대로 추가 요청합니다.
  /// 예) 3개월(6p) 을 본 뒤 1년(25p) 으로 바꾸면 7~25 페이지만 새로 받습니다.
  /// 종목의 lastPage 를 넘는 페이지는 요청하지 않습니다 — Naver 는 넘는 페이지에
  /// 마지막 페이지 내용을 그대로 다시 주므로 중복 행이 생깁니다.
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

  // ------------------------------------------------------------------ helpers

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
