import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;

import '../domain/models.dart';

// sise_day.naver 한 페이지 파싱 결과
class DailyPage {
  const DailyPage({required this.rows, required this.lastPage});

  // 최신 날짜부터. 한 페이지 최대 10행
  final List<DailyPrice> rows;

  // 페이지 네비게이션에서 읽은 마지막 페이지 번호
  final int lastPage;
}

final RegExp _date = RegExp(r'^\d{4}\.\d{2}\.\d{2}$');
final RegExp _pageParam = RegExp(r'page=(\d+)');

// EUC-KR 디코딩된 HTML 문자열을 받음
// 컬럼 순서: 날짜, 종가, 전일비, 시가, 고가, 저가, 거래량
// requestedPage 는 네비게이션이 없을 때 lastPage 기본값
DailyPage parseDailyPage(String htmlText, {required int requestedPage}) {
  final Document doc = html.parse(htmlText);

  final List<DailyPrice> rows = <DailyPrice>[];
  for (final Element tr in doc.querySelectorAll('table.type2 tr')) {
    final List<Element> tds = tr.querySelectorAll('td');
    if (tds.length != 7) continue;
    final String date = tds[0].text.trim();
    if (!_date.hasMatch(date)) continue; // 헤더, 구분선, 빈 행 건너뜀

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

  // 네비게이션 링크 중 가장 큰 page 값 = 마지막 페이지
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

// 전일비 부호는 숫자에 없고 em 클래스로 구분 (bu_pup 상승 / bu_pdn 하락 / bu_pn 보합)
int _signedChange(Element td) {
  final int abs = _num(td);
  final Element? em = td.querySelector('em');
  if (em == null) return abs;
  if (em.classes.contains('bu_pdn')) return -abs;
  if (em.classes.contains('bu_pn')) return 0;
  return abs;
}
