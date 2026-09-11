import 'package:edencrew_assignment_starter/domain/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('천 단위 구분', () {
    expect(formatNumber(0), '0');
    expect(formatNumber(999), '999');
    expect(formatNumber(1000), '1,000');
    expect(formatNumber(257250), '257,250');
    expect(formatNumber(-1234567), '-1,234,567');
  });

  test('등락 표기 — 하락 / 상승 / 보합', () {
    expect(formatChange(-400, -0.22), '-400 (-0.22%)');
    expect(formatChange(11750, 4.3654), '+11,750 (+4.37%)');
    expect(formatChange(0, 0), '0 (0.00%)');
    // 반올림 후 0.00 이 되면 부호를 붙이지 않는다
    expect(formatRate(-0.001), '0.00%');
  });

  test('거래량 축약 — 천 단위', () {
    expect(formatVolume(29113282), '29,113천');
    expect(formatVolume(8433282), '8,433천');
    expect(formatVolume(999), '999');
    expect(formatVolume(1000), '1천');
  });

  test('시가총액 축약 — 조 / 억', () {
    expect(formatMarketCap(1063000000000000), '1,063조');
    expect(formatMarketCap(257250 * 5846278608), '1,503조');
    expect(formatMarketCap(853200000000), '8,532억');
    expect(formatMarketCap(50000000), '50,000,000');
  });

  test('날짜 MM.DD', () {
    expect(formatMonthDay('20260911'), '09.11');
  });
}
