// 화면 표시용 숫자 포맷 함수 모음

final RegExp _thousands = RegExp(r'(\d)(?=(\d{3})+$)');

// 1234567 -> 1,234,567
String formatNumber(int n) {
  final String digits = n.abs().toString().replaceAllMapped(
    _thousands,
    (Match m) => '${m[1]},',
  );
  return n < 0 ? '-$digits' : digits;
}

// +1,200 / -400 / 0
String formatSigned(int n) => n > 0 ? '+${formatNumber(n)}' : formatNumber(n);

// +4.37% / -0.22% / 0.00%
String formatRate(double rate) {
  final String fixed = rate.abs().toStringAsFixed(2);
  if (fixed == '0.00') return '0.00%';
  return '${rate > 0 ? '+' : '-'}$fixed%';
}

// -400 (-0.22%)
String formatChange(int change, double rate) =>
    '${formatSigned(change)} (${formatRate(rate)})';

// 29,113,282 -> 29,113천 (1000 미만은 그대로)
String formatVolume(int volume) =>
    volume >= 1000 ? '${formatNumber(volume ~/ 1000)}천' : formatNumber(volume);

// 1조 이상 조, 1억 이상 억, 그 미만은 원 단위
String formatMarketCap(int won) {
  const int trillion = 1000000000000;
  const int hundredMillion = 100000000;
  if (won >= trillion) return '${formatNumber(won ~/ trillion)}조';
  if (won >= hundredMillion) return '${formatNumber(won ~/ hundredMillion)}억';
  return formatNumber(won);
}

// yyyyMMdd -> MM.DD
String formatMonthDay(String yyyyMMdd) =>
    '${yyyyMMdd.substring(4, 6)}.${yyyyMMdd.substring(6, 8)}';
