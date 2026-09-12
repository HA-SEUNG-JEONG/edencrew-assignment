import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/ui/common.dart';
import 'package:edencrew_assignment_starter/ui/detail_screen.dart';
import 'package:edencrew_assignment_starter/ui/search_screen.dart';
import 'package:edencrew_assignment_starter/ui/watchlist_screen.dart';

void main() {
  // 시세 조회가 실패해도 셸은 그려져야 한다
  StockRepository offlineRepository() => StockRepository(
    client: MockClient((http.Request _) async => http.Response('', 404)),
  );

  // 자동완성과 시세만 응답한다. 시세가 하나도 없으면 관심 화면이 전면 에러로 바뀌어
  // 목록 변화를 볼 수 없다
  StockRepository mockRepository() => StockRepository(
    client: MockClient((http.Request req) async {
      final String? file = switch (req.url.host) {
        'ac.stock.naver.com' => 'ac_samsung.json',
        'polling.finance.naver.com' => 'realtime_batch.json',
        _ => null,
      };
      if (file == null) return http.Response('', 404);
      return http.Response.bytes(
        File('assets/mock/$file').readAsBytesSync(),
        200,
      );
    }),
  );

  testWidgets('앱이 다크 테마의 하단 탭 셸로 시작한다', (WidgetTester tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: offlineRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WatchlistScreen), findsOneWidget);
    expect(find.text('검색'), findsOneWidget); // 하단 탭 라벨
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('정렬 기준을 바꾸면 목록 순서와 헤더 칩이 함께 바뀐다', (WidgetTester tester) async {
    // 시세 mock 은 005930(-4.37%) 과 000660(-4.10%) 두 종목만 응답한다.
    // 나머지 세 종목은 스켈레톤으로 남아 현재가순 / 등락률순 모두 아래로 밀린다
    await tester.pumpWidget(EdencrewAssignmentApp(repository: mockRepository()));
    await tester.pumpAndSettle();

    double rowTop(String name) => tester
        .getTopLeft(
          find.descendant(
            of: find.byType(WatchlistScreen),
            matching: find.text(name),
          ),
        )
        .dy;

    Future<void> pickSort(String from, String to) async {
      await tester.tap(find.text(from)); // 헤더 칩
      await tester.pumpAndSettle();
      await tester.tap(find.text(to)); // 바텀시트 항목
      await tester.pumpAndSettle();
    }

    // 기본값 가나다순 — 한글이 먼저, 영문으로 시작하는 종목명은 뒤
    expect(rowTop('삼성전자'), lessThan(rowTop('카카오')));
    expect(rowTop('카카오'), lessThan(rowTop('SK하이닉스')));

    await pickSort('가나다순', '현재가순');
    expect(find.text('현재가순'), findsOneWidget); // 칩 문구가 함께 바뀐다
    expect(rowTop('SK하이닉스'), lessThan(rowTop('삼성전자'))); // 1,777,000 > 257,250
    expect(rowTop('삼성전자'), lessThan(rowTop('카카오'))); // 시세 없는 행은 맨 아래

    // 이 mock 은 등락률 순서(-4.10% > -4.37%)가 현재가 순서와 같아 둘을 가르지는
    // 못한다. 가나다순(삼성전자 우선)과 달라진다는 것까지 확인한다
    await pickSort('현재가순', '등락률순');
    expect(find.text('등락률순'), findsOneWidget);
    expect(rowTop('SK하이닉스'), lessThan(rowTop('삼성전자')));
    expect(rowTop('삼성전자'), lessThan(rowTop('카카오')));
  });

  testWidgets('검색어를 지우면 결과 없음 상태에서 초기 상태로 돌아온다', (WidgetTester tester) async {
    await tester.pumpWidget(
      EdencrewAssignmentApp(
        repository: StockRepository(
          client: MockClient(
            (http.Request _) async => http.Response('{"items":[]}', 200),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350)); // 디바운스
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없습니다'), findsOneWidget);
    // 입력한 검색어가 안내 문구에 그대로 들어간다
    expect(find.textContaining("'zzz'와"), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close)); // 지우기 버튼
    await tester.pumpAndSettle();
    expect(find.text('종목을 검색해 보세요'), findsOneWidget);
  });

  testWidgets('검색에서 등록한 종목이 관심 목록에 나타나고 상세에서 해제하면 함께 사라진다', (
    WidgetTester tester,
  ) async {
    // 시드 5종목에 없는 종목이라야 등록·해제가 목록 변화로 드러난다
    const String subtitle = '009150 · 코스피'; // 삼성전기

    Finder inSearch(Finder finder) =>
        find.descendant(of: find.byType(SearchScreen), matching: finder);
    Finder inWatchlist(Finder finder) =>
        find.descendant(of: find.byType(WatchlistScreen), matching: finder);
    // IndexedStack 이 두 화면을 모두 살려 두므로 별 버튼도 화면으로 좁혀서 찾는다
    Finder searchStar() => find.descendant(
      of: find
          .ancestor(
            of: inSearch(find.text(subtitle)),
            matching: find.byType(InkWell),
          )
          .first,
      matching: find.byType(StarButton),
    );

    await tester.pumpWidget(
      EdencrewAssignmentApp(repository: mockRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pump(const Duration(milliseconds: 350)); // 디바운스
    await tester.pumpAndSettle();
    expect(inSearch(find.text(subtitle)), findsOneWidget);
    expect(inWatchlist(find.text(subtitle)), findsNothing);

    // 검색에서 등록
    await tester.tap(searchStar());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: searchStar(), matching: find.byType(Icon)),
          )
          .icon,
      Icons.star,
    );
    await tester.pumpAndSettle();

    // 관심 탭에 바로 나타난다
    await tester.tap(find.text('관심').last); // 화면 제목과 겹치지 않는 하단 탭 라벨
    await tester.pumpAndSettle();
    expect(inWatchlist(find.text(subtitle)), findsOneWidget);

    // 검색 행에서 상세로 들어가 해제
    await tester.tap(find.text('검색').last);
    await tester.pumpAndSettle();
    await tester.tap(inSearch(find.text(subtitle)));
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(DetailScreen),
        matching: find.byType(StarButton),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('관심이 해제되었습니다'), findsOneWidget);
    await tester.pumpAndSettle();

    // 뒤로 나오면 검색 행 별과 관심 목록이 함께 풀려 있다
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Icon>(
            find.descendant(of: searchStar(), matching: find.byType(Icon)),
          )
          .icon,
      Icons.star_border,
    );
    await tester.tap(find.text('관심').last);
    await tester.pumpAndSettle();
    expect(inWatchlist(find.text(subtitle)), findsNothing);
  });
}
