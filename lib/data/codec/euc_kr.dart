import 'dart:convert';

import 'cp949_table.dart';

// EUC-KR(CP949) 디코더
// 네이버 일별 시세 HTML 과 실시간 JSON 이 EUC-KR 이라 필요.
// dart:convert 에 없고 pub 패키지들은 null-safety 미지원, 플랫폼 플러그인은 flutter test 에서 못 써서
// 파이썬으로 뽑은 매핑 표(cp949_table.dart)를 직접 넣음. 디코더만 구현.
// 0x00~0x7F 는 ASCII, 2바이트는 표에서 찾고 없으면 U+FFFD
const Encoding eucKr = _EucKrCodec();

class _EucKrCodec extends Encoding {
  const _EucKrCodec();

  @override
  String get name => 'euc-kr';

  @override
  Converter<List<int>, String> get decoder => const _EucKrDecoder();

  @override
  Converter<String, List<int>> get encoder =>
      throw UnsupportedError('encoder 미구현');
}

class _EucKrDecoder extends Converter<List<int>, String> {
  const _EucKrDecoder();

  static const int _trailsPerLead = 178;

  @override
  String convert(List<int> input) {
    final StringBuffer out = StringBuffer();
    int i = 0;
    while (i < input.length) {
      final int lead = input[i];
      if (lead < 0x80) {
        out.writeCharCode(lead);
        i += 1;
        continue;
      }
      final int? trailIndex = i + 1 < input.length
          ? _trailIndex(input[i + 1])
          : null;
      if (lead < 0x81 || lead > 0xFE || trailIndex == null) {
        out.write('�');
        i += 1;
        continue;
      }
      out.writeCharCode(
        cp949Table.codeUnitAt((lead - 0x81) * _trailsPerLead + trailIndex),
      );
      i += 2;
    }
    return out.toString();
  }

  // trail 바이트를 표의 열 인덱스로. 0x41~0x5A, 0x61~0x7A, 0x81~0xFE 순서
  static int? _trailIndex(int b) {
    if (b >= 0x41 && b <= 0x5A) return b - 0x41;
    if (b >= 0x61 && b <= 0x7A) return b - 0x61 + 26;
    if (b >= 0x81 && b <= 0xFE) return b - 0x81 + 52;
    return null;
  }
}
