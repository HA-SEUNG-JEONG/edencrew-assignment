import 'dart:io';

import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// 요청 URL 기록하고 mock 파일 돌려주는 가짜 클라이언트
class _FakeNaver {
  final List<Uri> requests = <Uri>[];

  http.Client get client => MockClient((http.Request req) async {
    requests.add(req.url);
    expect(req.headers['User-Agent'], contains('Mozilla'));
    final String? file = _fileFor(req.url);
    if (file == null) return http.Response('', 404);
    return http.Response.bytes(
      File('assets/mock/$file').readAsBytesSync(),
      200,
    );
  });

  String? _fileFor(Uri url) {
    switch (url.host) {
      case 'ac.stock.naver.com':
        return 'ac_samsung.json';
      case 'polling.finance.naver.com':
        return url.queryParameters['query']!.contains(',')
            ? 'realtime_batch.json'
            : 'realtime_491000.json';
      case 'stock.naver.com':
        return 'meta_${url.pathSegments.last}.json';
      case 'finance.naver.com':
        final String code = url.queryParameters['code']!;
        final int page = int.parse(url.queryParameters['page']!);
        if (code == '005930') {
          // 756 페이지짜리 종목. 2페이지 이후는 p2 를 재사용해 lastPage 만 확인.
          return page == 1
              ? 'sise_day_005930_p1.html'
              : 'sise_day_005930_p2.html';
        }
        if (code == '491000') {
          // lastPage=18. 18 을 넘는 요청이 오면 테스트 실패로 드러나도록 404.
          if (page > 18) return null;
          return page == 18
              ? 'sise_day_491000_p18.html'
              : 'sise_day_491000_p1.html';
        }
        return 'sise_day_unlisted_p1.html';
    }
    return null;
  }

  int dailyRequests(String code) => requests
      .where(
        (Uri u) =>
            u.host == 'finance.naver.com' && u.queryParameters['code'] == code,
      )
      .length;
}

void main() {
  late _FakeNaver server;
  late StockRepository repo;

  setUp(() {
    server = _FakeNaver();
    repo = StockRepository(client: server.client);
  });

  test('search: 국내 종목만, 요청 파라미터 확인', () async {
    final List<Stock> result = await repo.search('삼성');
    expect(result.first.name, '삼성전자');
    expect(server.requests.single.queryParameters['q'], '삼성');
  });

  test('fetchQuotes: 여러 종목을 요청 1번으로, symbol 색인', () async {
    final Map<String, Quote> quotes = await repo.fetchQuotes(<String>[
      '005930',
      '000660',
      '035420',
    ]);
    expect(server.requests, hasLength(1));
    expect(
      server.requests.single.queryParameters['query'],
      'SERVICE_ITEM:005930,000660,035420',
    );
    expect(quotes.keys, containsAll(<String>['005930', '000660', '035420']));
    expect(quotes['005930']!.change, -11750);
  });

  test('fetchQuotes: 빈 목록이면 요청하지 않음', () async {
    expect(await repo.fetchQuotes(const <String>[]), isEmpty);
    expect(server.requests, isEmpty);
  });

  test('fetchMeta', () async {
    final Stock s = await repo.fetchMeta('491000');
    expect(s.subtitle, '491000 · 코스닥');
  });

  test('dailyPrices: 기간 확장 시 부족한 페이지만 추가 요청, 축소 시 요청 0', () async {
    await repo.dailyPrices('005930', Period.month1.pages); // 1,2
    expect(server.dailyRequests('005930'), 2);

    await repo.dailyPrices('005930', Period.month3.pages); // 3..6 만 추가
    expect(server.dailyRequests('005930'), 6);

    final List<DailyPrice> year = await repo.dailyPrices(
      '005930',
      Period.year1.pages,
    );
    expect(server.dailyRequests('005930'), 25); // 7..25 만 추가
    expect(year, hasLength(250));

    await repo.dailyPrices('005930', Period.month1.pages);
    expect(server.dailyRequests('005930'), 25); // 캐시 재사용, 요청 없음

    // 요청 page 는 1..25 를 각각 정확히 한 번
    final List<int> pages = server.requests
        .where((Uri u) => u.host == 'finance.naver.com')
        .map((Uri u) => int.parse(u.queryParameters['page']!))
        .toList();
    expect(pages, List<int>.generate(25, (int i) => i + 1));
  });

  test('dailyPrices: lastPage(18) 를 넘는 페이지는 요청하지 않음', () async {
    final List<DailyPrice> rows = await repo.dailyPrices(
      '491000',
      Period.year1.pages,
    );
    expect(server.dailyRequests('491000'), 18);
    expect(rows, hasLength(17 * 10 + 5));
  });

  test('dailyPrices: 미상장 코드는 1페이지만 요청, 0행', () async {
    final List<DailyPrice> rows = await repo.dailyPrices(
      '000000',
      Period.year1.pages,
    );
    expect(server.dailyRequests('000000'), 1);
    expect(rows, isEmpty);
  });

  test('HTTP 200 이 아니면 예외', () async {
    final StockRepository failing = StockRepository(
      client: MockClient((_) async => http.Response('', 503)),
    );
    expect(failing.search('x'), throwsA(isA<HttpException>()));
  });
}
