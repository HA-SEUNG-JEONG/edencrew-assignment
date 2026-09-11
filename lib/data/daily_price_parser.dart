import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../domain/models.dart';

/// `sise_day.naver` 한 페이지의 파싱 결과.
class DailyPage {
  const DailyPage({required this.rows, required this.lastPage});

  /// 최신 날짜가 먼저 오는 순서(Naver 표 순서 그대로). 한 페이지 최대 10행.
  final List<DailyPrice> rows;

  /// 이 종목의 마지막 페이지 번호. 이 값보다 큰 page 를 요청하면 Naver 는
  /// 마지막 페이지를 그대로 다시 돌려주므로(빈 응답 아님) 반드시 상한으로 써야 합니다.
  final int lastPage;
}

final RegExp _date = RegExp(r'^\d{4}\.\d{2}\.\d{2}$');
final RegExp _pageParam = RegExp(r'page=(\d+)');

/// 이미 EUC-KR 디코딩이 끝난 HTML 문자열을 받습니다.
///
/// 표 컬럼 순서: 날짜, 종가, 전일비, 시가, 고가, 저가, 거래량.
/// [requestedPage]는 페이지 네비게이션이 전혀 없을 때(미상장 코드 등) lastPage 대체값입니다.
DailyPage parseDailyPage(String htmlText, {required int requestedPage}) {
  final Document doc = html.parse(htmlText);

  final List<DailyPrice> rows = <DailyPrice>[];
  for (final Element tr in doc.querySelectorAll('table.type2 tr')) {
    final List<Element> tds = tr.querySelectorAll('td');
    if (tds.length != 7) continue;
    final String date = tds[0].text.trim();
    if (!_date.hasMatch(date)) continue; // 헤더·구분선·빈 행

    rows.add(
      DailyPrice(
        date: date.replaceAll('.', ''),
        close: _num(tds[1]),
        change: _signedChange(tds[2]),
        open: _num(tds[3]),
        high: _num(tds[4]),
        low: _num(tds[5]),
        volume: _num(tds[6]),
      ),
    );
  }

  int lastPage = requestedPage;
  for (final Element a in doc.querySelectorAll('table.Nnavi a')) {
    final Match? m = _pageParam.firstMatch(a.attributes['href'] ?? '');
    if (m == null) continue;
    final int page = int.parse(m[1]!);
    if (page > lastPage) lastPage = page;
  }

  return DailyPage(rows: rows, lastPage: lastPage);
}

int _num(Element td) =>
    int.tryParse(td.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

/// 전일비 칸. 부호는 숫자에 없고 `em.bu_pup`(상승) / `bu_pdn`(하락) / `bu_pn`(보합) 클래스로만 구분됩니다.
int _signedChange(Element td) {
  final int abs = _num(td);
  final Element? em = td.querySelector('em');
  if (em == null) return abs;
  if (em.classes.contains('bu_pdn')) return -abs;
  if (em.classes.contains('bu_pn')) return 0;
  return abs;
}
