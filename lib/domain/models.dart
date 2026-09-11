// 종목 기본 정보. 검색 결과, 관심 목록, 상세 헤더에서 공통 사용
class Stock {
  const Stock({required this.symbol, required this.name, required this.market});

  final String symbol; // 6자리 종목코드 (005930)
  final String name;
  final String market; // 코스피 / 코스닥

  String get id => 'domestic:$symbol';

  // "005930 · 코스피"
  String get subtitle => '$symbol · $market';

  Map<String, Object> toJson() => <String, Object>{
    'symbol': symbol,
    'name': name,
    'market': market,
  };

  factory Stock.fromJson(Map<String, dynamic> json) => Stock(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    market: json['market'] as String,
  );

  @override
  bool operator ==(Object other) => other is Stock && other.symbol == symbol;

  @override
  int get hashCode => symbol.hashCode;
}

// 실시간 시세
class Quote {
  const Quote({
    required this.symbol,
    required this.price,
    required this.prevClose,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.listedShares,
  });

  final String symbol;
  final int price;
  final int prevClose;
  final int open;
  final int high;
  final int low;
  final int volume;
  final int listedShares;

  int get change => price - prevClose;

  // 전일 종가 0이면 (상장 첫날 등) 0 처리
  double get changeRate => prevClose == 0 ? 0 : change / prevClose * 100;

  // 시가총액 = 현재가 x 상장주식수
  int get marketCap => price * listedShares;
}

// 일별 시세 한 행. date 는 yyyyMMdd
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.close,
    required this.change,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
  });

  final String date;
  final int close;
  final int change; // 전일비, 하락이면 음수
  final int open;
  final int high;
  final int low;
  final int volume;
}

// 관심 목록 정렬 기준
enum SortKey {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const SortKey(this.label);
  final String label;
}

// 상세 화면 기간 탭. pages = 필요한 일별 시세 페이지 수 (1페이지 = 10거래일)
enum Period {
  month1('1개월', 2),
  month3('3개월', 6),
  month6('6개월', 12),
  year1('1년', 25);

  const Period(this.label, this.pages);
  final String label;
  final int pages;
}
