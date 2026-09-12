import 'package:flutter/material.dart';

import 'data/stock_repository.dart';
import 'domain/models.dart';

// 세 화면이 공유하는 상태. 관심 목록·시세·정렬만 담고 나머지는 각 화면이 갖는다.
class AppState extends ChangeNotifier {
  AppState(this.repo);

  // 일별 시세 페이지 캐시가 저장소 인스턴스 필드라 상세 화면도 이 인스턴스를 써야 한다
  final StockRepository repo;

  // 시안 관심 프레임과 같은 5종목. 첫 실행에서 스켈레톤 해제와 정렬을 바로 확인할 수 있다
  static const List<Stock> _seed = <Stock>[
    Stock(symbol: '005930', name: '삼성전자', market: '코스피'),
    Stock(symbol: '000660', name: 'SK하이닉스', market: '코스피'),
    Stock(symbol: '035720', name: '카카오', market: '코스피'),
    Stock(symbol: '247540', name: '에코프로비엠', market: '코스닥'),
    Stock(symbol: '373220', name: 'LG에너지솔루션', market: '코스피'),
  ];

  final List<Stock> _favorites = List<Stock>.of(_seed); // 등록 순서 유지
  final Map<String, Quote> _quotes = <String, Quote>{}; // 항목 없음 = 그 행 스켈레톤
  SortKey _sortKey = SortKey.name;
  bool _refreshing = false;
  bool _failed = false;

  SortKey get sortKey => _sortKey;

  bool get refreshing => _refreshing;

  // 보여줄 시세가 하나도 없는데 실패한 경우만 전면 에러로 바꾼다
  bool get blankError =>
      _failed &&
      _favorites.isNotEmpty &&
      !_favorites.any((Stock s) => _quotes.containsKey(s.symbol));

  List<Stock> get favorites => _sorted();

  Quote? quoteOf(String symbol) => _quotes[symbol];

  bool isFavorite(String symbol) =>
      _favorites.any((Stock s) => s.symbol == symbol);

  void setSortKey(SortKey key) {
    if (key == _sortKey) return;
    _sortKey = key;
    notifyListeners();
  }

  // 반환값은 등록됐는지 여부. 토스트 문구를 고르는 데 쓴다
  bool toggleFavorite(Stock stock) {
    final bool added = !isFavorite(stock.symbol);
    if (added) {
      _favorites.add(stock);
      fetchQuote(stock.symbol);
    } else {
      _favorites.removeWhere((Stock s) => s.symbol == stock.symbol);
    }
    notifyListeners();
    return added;
  }

  void removeFavorite(String symbol) {
    _favorites.removeWhere((Stock s) => s.symbol == symbol);
    notifyListeners();
  }

  // 관심 목록 전체 재조회. 실패해도 이미 받은 시세는 지우지 않는다
  Future<void> refreshQuotes() async {
    if (_refreshing || _favorites.isEmpty) return;
    _refreshing = true;
    notifyListeners();
    try {
      _quotes.addAll(
        await repo.fetchQuotes(_favorites.map((Stock s) => s.symbol)),
      );
      _failed = false;
    } catch (_) {
      // 실기기 실패는 HttpException 만이 아니라 Socket/Client/Format 으로도 온다
      _failed = true;
    }
    _refreshing = false;
    notifyListeners();
  }

  // 아직 시세가 없는 1종목만. 관심 등록과 상세 진입에서 호출한다
  Future<void> fetchQuote(String symbol) async {
    if (_quotes.containsKey(symbol)) return;
    try {
      _quotes.addAll(await repo.fetchQuotes(<String>[symbol]));
      notifyListeners();
    } catch (_) {
      // 1건 실패는 그 행을 스켈레톤으로 두는 것으로 충분하다
    }
  }

  List<Stock> _sorted() {
    final List<Stock> list = List<Stock>.of(_favorites);
    if (_sortKey == SortKey.name) {
      // 이름은 시세 없이도 알고 있어서 전부 정렬된다
      list.sort(
        (Stock a, Stock b) => _nameKey(a.name).compareTo(_nameKey(b.name)),
      );
      return list;
    }
    // 시세 없는 행에 0을 가정하면 하락 종목보다 위로 올라간다. 비교에서 빼고 맨 아래로
    final List<Stock> known = <Stock>[];
    final List<Stock> unknown = <Stock>[];
    for (final Stock stock in list) {
      (_quotes.containsKey(stock.symbol) ? known : unknown).add(stock);
    }
    known.sort((Stock a, Stock b) {
      final Quote x = _quotes[a.symbol]!;
      final Quote y = _quotes[b.symbol]!;
      return _sortKey == SortKey.price
          ? y.price.compareTo(x.price)
          : y.changeRate.compareTo(x.changeRate);
    });
    return known..addAll(unknown);
  }

  // 'LG에너지솔루션'은 코드포인트가 한글보다 작아 그냥 비교하면 가나다순 맨 위로 온다.
  // 국어사전 관행대로 한글을 앞세우고 영문·숫자를 뒤로 보낸다
  static String _nameKey(String name) {
    final int first = name.isEmpty ? 0 : name.codeUnitAt(0);
    final bool hangul = first >= 0xAC00 && first <= 0xD7A3;
    return '${hangul ? 0 : 1}$name';
  }
}

// InheritedNotifier 라서 notifyListeners 만으로 의존 위젯이 다시 빌드된다
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
}

// context.colors / context.dimens 와 같은 사용감
extension AppScopeContext on BuildContext {
  AppState get appState =>
      dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
