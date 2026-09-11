/// 종목 식별 정보. 검색 결과·관심 목록·상세 헤더가 공통으로 쓰는 최소 단위입니다.
class Stock {
  const Stock({required this.symbol, required this.name, required this.market});

  /// 6자리 종목코드 (예: `005930`)
  final String symbol;
  final String name;

  /// 거래소명 (예: `코스피`, `코스닥`)
  final String market;

  /// Naver 가이드가 요구하는 canonical id.
  String get id => 'domestic:$symbol';

  /// `005930 · 코스피`
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

/// 실시간 시세. 등락·시가총액은 가이드대로 파생값으로 계산합니다.
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

  /// 등락률(%). 전일 종가가 0이면(상장 첫날 등) 0으로 둡니다.
  double get changeRate => prevClose == 0 ? 0 : change / prevClose * 100;

  /// 시가총액(원) = 현재가 × 상장 주식 수
  int get marketCap => price * listedShares;
}

/// 일별 시세 한 행. [date]는 `yyyyMMdd`로 정규화된 문자열입니다.
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

  /// 전일비. 부호 포함 (하락이면 음수).
  final int change;
  final int open;
  final int high;
  final int low;
  final int volume;
}

/// 관심 목록 정렬 기준. [label]은 헤더 칩과 바텀시트에 그대로 표시됩니다.
enum SortKey {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const SortKey(this.label);
  final String label;
}

/// 상세 화면 기간 탭. [pages]는 일별 시세 표에서 필요한 페이지 수(1페이지 = 10거래일).
enum Period {
  month1('1개월', 2),
  month3('3개월', 6),
  month6('6개월', 12),
  year1('1년', 25);

  const Period(this.label, this.pages);
  final String label;
  final int pages;
}
