import '../../domain/models.dart';

// 검색 자동완성 응답 items[] 한 건
class AcItemDto {
  const AcItemDto({
    required this.code,
    required this.name,
    required this.typeName,
    required this.nationCode,
    required this.category,
  });

  factory AcItemDto.fromJson(Map<String, dynamic> json) => AcItemDto(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    typeName: json['typeName'] as String? ?? '',
    nationCode: json['nationCode'] as String? ?? '',
    category: json['category'] as String? ?? '',
  );

  final String code;
  final String name;

  final String typeName; // 거래소명 (코스피, 코스닥 ...)
  final String nationCode;

  final String category; // stock / ipo / index / marketindicator

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  // 국내 주식 + 6자리 코드만. 해외 종목, IPO 예정 코드(A495910 같은 것) 제외
  bool get isDomesticStock =>
      category == 'stock' && nationCode == 'KOR' && _sixDigits.hasMatch(code);

  Stock toStock() => Stock(symbol: code, name: name, market: typeName);
}

// 실시간 시세 응답 result.areas[].datas[] 한 건
// 장 시작 전이나 거래정지면 숫자가 비어서 오므로 nullable 로 받고 변환할 때 0 처리
class RealtimeItemDto {
  const RealtimeItemDto({
    required this.cd,
    required this.nv,
    required this.pcv,
    required this.ov,
    required this.hv,
    required this.lv,
    required this.aq,
    required this.countOfListedStock,
  });

  factory RealtimeItemDto.fromJson(Map<String, dynamic> json) =>
      RealtimeItemDto(
        cd: json['cd'] as String? ?? '',
        nv: _int(json['nv']),
        pcv: _int(json['pcv']),
        ov: _int(json['ov']),
        hv: _int(json['hv']),
        lv: _int(json['lv']),
        aq: _int(json['aq']),
        countOfListedStock: _int(json['countOfListedStock']),
      );

  // 응답에서 종목 목록만 추출. 순서가 요청 순서와 다를 수 있어서 cd 로 찾아야 함
  static List<RealtimeItemDto> listFromResponse(Map<String, dynamic> json) {
    final List<dynamic> areas =
        (json['result'] as Map<String, dynamic>?)?['areas'] as List<dynamic>? ??
        const <dynamic>[];
    return <RealtimeItemDto>[
      for (final dynamic area in areas)
        for (final dynamic data
            in (area as Map<String, dynamic>)['datas'] as List<dynamic>? ??
                const <dynamic>[])
          RealtimeItemDto.fromJson(data as Map<String, dynamic>),
    ];
  }

  final String cd;
  final int? nv;
  final int? pcv;
  final int? ov;
  final int? hv;
  final int? lv;
  final int? aq;
  final int? countOfListedStock;

  Quote toQuote() => Quote(
    symbol: cd,
    price: nv ?? 0,
    prevClose: pcv ?? 0,
    open: ov ?? 0,
    high: hv ?? 0,
    low: lv ?? 0,
    volume: aq ?? 0,
    listedShares: countOfListedStock ?? 0,
  );

  static int? _int(Object? v) => v is num ? v.toInt() : null;
}

// 종목 메타 응답 (fchart/domestic/stock/{symbol})
class StockMetaDto {
  const StockMetaDto({
    required this.symbolCode,
    required this.stockName,
    required this.stockExchangeNameKor,
  });

  factory StockMetaDto.fromJson(Map<String, dynamic> json) => StockMetaDto(
    symbolCode: json['symbolCode'] as String? ?? '',
    stockName: json['stockName'] as String? ?? '',
    stockExchangeNameKor: json['stockExchangeNameKor'] as String? ?? '',
  );

  final String symbolCode;
  final String stockName;
  final String stockExchangeNameKor;

  Stock toStock() =>
      Stock(symbol: symbolCode, name: stockName, market: stockExchangeNameKor);
}
