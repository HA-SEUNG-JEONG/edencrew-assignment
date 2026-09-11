/// 화면 표기 형식. 숫자 값이 아니라 형식을 Figma와 맞추는 것이 목적입니다.
library;

final RegExp _thousands = RegExp(r'(\d)(?=(\d{3})+$)');

/// `1234567` → `1,234,567`
String formatNumber(int n) {
  final String digits = n.abs().toString().replaceAllMapped(
    _thousands,
    (Match m) => '${m[1]},',
  );
  return n < 0 ? '-$digits' : digits;
}

/// 부호 포함. `+1,200` / `-400` / `0`
String formatSigned(int n) => n > 0 ? '+${formatNumber(n)}' : formatNumber(n);

/// 등락률(%) 소수 둘째 자리. `+4.37%` / `-0.22%` / `0.00%`
String formatRate(double rate) {
  final String fixed = rate.abs().toStringAsFixed(2);
  if (fixed == '0.00') return '0.00%';
  return '${rate > 0 ? '+' : '-'}$fixed%';
}

/// 관심 행·상세 헤더의 등락 표기. `-400 (-0.22%)`
String formatChange(int change, double rate) =>
    '${formatSigned(change)} (${formatRate(rate)})';

/// 거래량 축약. 천 단위 미만은 그대로. `29,113,282` → `29,113천`
String formatVolume(int volume) =>
    volume >= 1000 ? '${formatNumber(volume ~/ 1000)}천' : formatNumber(volume);

/// 시가총액 축약. 1조 이상은 `조`, 1억 이상은 `억`, 그 미만은 원 단위 그대로.
String formatMarketCap(int won) {
  const int trillion = 1000000000000;
  const int hundredMillion = 100000000;
  if (won >= trillion) return '${formatNumber(won ~/ trillion)}조';
  if (won >= hundredMillion) return '${formatNumber(won ~/ hundredMillion)}억';
  return formatNumber(won);
}

/// `yyyyMMdd` → `MM.DD`
String formatMonthDay(String yyyyMMdd) =>
    '${yyyyMMdd.substring(4, 6)}.${yyyyMMdd.substring(6, 8)}';
