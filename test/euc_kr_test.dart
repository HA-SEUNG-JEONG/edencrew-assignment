import 'dart:io';

import 'package:edencrew_assignment_starter/data/codec/euc_kr.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EUC-KR 바이트를 한글로 디코딩한다', () {
    // '삼성전자' EUC-KR: BB EF BC BA C0 FC C0 DA
    const List<int> bytes = <int>[0xBB, 0xEF, 0xBC, 0xBA, 0xC0, 0xFC, 0xC0, 0xDA];
    expect(eucKr.decode(bytes), '삼성전자');
  });

  test('ASCII는 그대로, 깨진 바이트는 U+FFFD', () {
    expect(eucKr.decode('abc 123'.codeUnits), 'abc 123');
    expect(eucKr.decode(<int>[0x41, 0xBB]), 'A�');
    expect(eucKr.decode(<int>[0x80, 0x41]), '�A');
  });

  test('mock 응답에서 한글 깨짐 없이 디코딩된다', () {
    final String html = eucKr.decode(
      File('assets/mock/sise_day_005930_p1.html').readAsBytesSync(),
    );
    expect(html, contains('일별</span>시세'));
    expect(html, contains('하락'));
    expect(html, isNot(contains('�')));

    final String json = eucKr.decode(
      File('assets/mock/realtime_batch.json').readAsBytesSync(),
    );
    expect(json, contains('"nm":"삼성전자"'));
    expect(json, contains('SK하이닉스'));
  });
}
