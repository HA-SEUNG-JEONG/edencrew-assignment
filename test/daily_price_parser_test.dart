import 'dart:io';

import 'package:edencrew_assignment_starter/data/codec/euc_kr.dart';
import 'package:edencrew_assignment_starter/data/daily_price_parser.dart';
import 'package:edencrew_assignment_starter/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

String _mock(String name) =>
    eucKr.decode(File('assets/mock/$name').readAsBytesSync());

void main() {
  test('삼성전자 1페이지: 10행, lastPage=756, 컬럼·부호 정확', () {
    final DailyPage page = parseDailyPage(
      _mock('sise_day_005930_p1.html'),
      requestedPage: 1,
    );

    expect(page.rows, hasLength(10));
    expect(page.lastPage, 756);

    final DailyPrice first = page.rows.first;
    expect(first.date, '20260911');
    expect(first.close, 257250);
    expect(first.change, -11750); // bu_pdn → 음수
    expect(first.open, 258000);
    expect(first.high, 261000);
    expect(first.low, 256500);
    expect(first.volume, 8428081);

    // 최신 날짜가 먼저
    expect(page.rows[1].date, '20260910');
  });

  test('상승 행은 양수, 보합 행은 0', () {
    final List<DailyPrice> rows = <DailyPrice>[
      ...parseDailyPage(
        _mock('sise_day_005930_p1.html'),
        requestedPage: 1,
      ).rows,
      ...parseDailyPage(
        _mock('sise_day_005930_p2.html'),
        requestedPage: 2,
      ).rows,
      ...parseDailyPage(
        _mock('sise_day_491000_p1.html'),
        requestedPage: 1,
      ).rows,
      ...parseDailyPage(
        _mock('sise_day_491000_p18.html'),
        requestedPage: 18,
      ).rows,
    ];
    expect(rows.where((DailyPrice r) => r.change > 0), isNotEmpty);
    expect(rows.where((DailyPrice r) => r.change < 0), isNotEmpty);
    expect(rows.where((DailyPrice r) => r.change == 0), isNotEmpty);
  });

  test('마지막 페이지: pgRR 없음 → 페이지 링크 최댓값이 lastPage, 5행', () {
    final DailyPage page = parseDailyPage(
      _mock('sise_day_491000_p18.html'),
      requestedPage: 18,
    );
    expect(page.rows, hasLength(5));
    expect(page.lastPage, 18);
  });

  test('미상장 코드: 0행, 네비게이션 링크 page=1 → lastPage=1', () {
    final DailyPage page = parseDailyPage(
      _mock('sise_day_unlisted_p1.html'),
      requestedPage: 1,
    );
    expect(page.rows, isEmpty);
    expect(page.lastPage, 1);
  });

  test('네비게이션이 전혀 없으면 요청 페이지를 lastPage로 둔다', () {
    final DailyPage page = parseDailyPage('<html></html>', requestedPage: 3);
    expect(page.rows, isEmpty);
    expect(page.lastPage, 3);
  });
}
