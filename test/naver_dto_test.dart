import 'dart:convert';
import 'dart:io';

import 'package:edencrew_assignment_starter/data/codec/euc_kr.dart';
import 'package:edencrew_assignment_starter/data/dto/naver_dto.dart';
import 'package:edencrew_assignment_starter/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String name, Encoding encoding) =>
    jsonDecode(encoding.decode(File('assets/mock/$name').readAsBytesSync()))
        as Map<String, dynamic>;

void main() {
  test('ac: 국내 6자리 종목만 남기고 Stock 으로 변환', () {
    final List<dynamic> items =
        _json('ac_samsung.json', utf8)['items'] as List<dynamic>;
    final List<Stock> stocks = <Stock>[
      for (final dynamic item in items)
        if (AcItemDto.fromJson(item as Map<String, dynamic>).isDomesticStock)
          AcItemDto.fromJson(item).toStock(),
    ];
    expect(stocks, isNotEmpty);
    expect(stocks.first.symbol, '005930');
    expect(stocks.first.name, '삼성전자');
    expect(stocks.first.market, '코스피');
    expect(stocks.first.id, 'domestic:005930');
    expect(stocks.first.subtitle, '005930 · 코스피');
  });

  test('ac 필터: 해외·IPO 예정·6자리 아님 제외', () {
    expect(
      AcItemDto.fromJson(<String, dynamic>{
        'code': 'SSAC',
        'name': 'x',
        'typeName': '나스닥',
        'nationCode': 'USA',
        'category': 'stock',
      }).isDomesticStock,
      isFalse,
    );
    expect(
      AcItemDto.fromJson(<String, dynamic>{
        'code': 'A495910',
        'name': 'x',
        'typeName': '코스닥',
        'nationCode': 'KOR',
        'category': 'ipo',
      }).isDomesticStock,
      isFalse,
    );
  });

  test('realtime: EUC-KR 디코딩 후 cd 로 색인, 파생값 계산', () {
    final List<RealtimeItemDto> list = RealtimeItemDto.listFromResponse(
      _json('realtime_batch.json', eucKr),
    );
    expect(list, hasLength(3));

    final Map<String, Quote> bySymbol = <String, Quote>{
      for (final RealtimeItemDto d in list) d.cd: d.toQuote(),
    };
    final Quote samsung = bySymbol['005930']!;
    expect(samsung.price, 257250);
    expect(samsung.prevClose, 269000);
    expect(samsung.change, -11750);
    expect(samsung.changeRate, closeTo(-4.368, 0.001));
    expect(samsung.volume, 8433282);
    expect(samsung.marketCap, 257250 * 5846278608);
  });

  test('realtime: 누락 필드는 0, 전일 종가 0이면 등락률 0', () {
    final Quote q = RealtimeItemDto.fromJson(<String, dynamic>{
      'cd': '000000',
    }).toQuote();
    expect(q.price, 0);
    expect(q.changeRate, 0);
  });

  test('meta: 종목명·거래소명', () {
    final Stock s = StockMetaDto.fromJson(
      _json('meta_491000.json', utf8),
    ).toStock();
    expect(s.symbol, '491000');
    expect(s.name, '리브스메드');
    expect(s.market, '코스닥');
  });
}
