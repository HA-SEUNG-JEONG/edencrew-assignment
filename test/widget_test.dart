import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/main.dart';
import 'package:edencrew_assignment_starter/ui/watchlist_screen.dart';

void main() {
  // 시세 조회가 실패해도 셸은 그려져야 한다
  StockRepository offlineRepository() => StockRepository(
    client: MockClient((http.Request _) async => http.Response('', 404)),
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
}
