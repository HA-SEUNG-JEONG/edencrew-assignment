import 'dart:convert';

import 'cp949_table.dart';

/// EUC-KR(CP949) 바이트를 문자열로 디코딩합니다.
///
/// Naver `sise_day` HTML과 `realtime` JSON이 `charset=EUC-KR`로 내려오는데
/// `dart:convert`에는 해당 codec이 없고, pub.dev의 순수 Dart 구현은 null-safety
/// 이전에 멈춰 있습니다. 플랫폼 채널 플러그인은 `flutter test`에서 쓸 수 없어
/// Python `codecs`로 뽑은 매핑 표를 소스에 포함하는 방식을 택했습니다.
/// (표 생성: `tool/gen_cp949_table.py`)
///
/// 1바이트(0x00~0x7F)는 ASCII 그대로, 2바이트 조합은 표에서 찾고 매핑이 없으면
/// U+FFFD로 대체합니다. 디코더만 필요하므로 인코더는 구현하지 않았습니다.
const Encoding eucKr = _EucKrCodec();

class _EucKrCodec extends Encoding {
  const _EucKrCodec();

  @override
  String get name => 'euc-kr';

  @override
  Converter<List<int>, String> get decoder => const _EucKrDecoder();

  @override
  Converter<String, List<int>> get encoder =>
      throw UnsupportedError('EUC-KR 인코딩은 필요하지 않아 구현하지 않았습니다.');
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

  /// trail 바이트 → 표의 열 인덱스. 0x41~0x5A, 0x61~0x7A, 0x81~0xFE 순서.
  static int? _trailIndex(int b) {
    if (b >= 0x41 && b <= 0x5A) return b - 0x41;
    if (b >= 0x61 && b <= 0x7A) return b - 0x61 + 26;
    if (b >= 0x81 && b <= 0xFE) return b - 0x81 + 52;
    return null;
  }
}
