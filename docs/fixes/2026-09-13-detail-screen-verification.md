# 종목 상세 화면 실행 검증

**날짜**: 2026-09-13
**유형**: 검증 (코드 변경 없음)
**대상**: `lib/ui/detail_screen.dart`, `lib/ui/candle_chart.dart`, `lib/data/stock_repository.dart`

## 정적 검증

```
flutter analyze   No issues found!
flutter test      +30: All tests passed!
```

페이지 이어받기 로직은 `test/stock_repository_test.dart` 의 `dailyPrices` 테스트 3개가 검증한다
(기간 확장 시 부족분만 추가 요청 · 축소 시 요청 0, `lastPage` 초과 요청 없음, 미상장 코드 1페이지만).

## 실행 검증

Android `emulator-5554`, iOS iPhone 16 시뮬레이터(393×852). 검색 탭에서 `005930` 검색 후 행을 탭해 진입했다.
`GET …sise_day.naver?code=005930&page=N` 로그를 탭마다 대조했고 두 플랫폼 결과가 같았다.

| 조작 | 새로 발생한 GET |
| --- | --- |
| 상세 진입 (1개월) | page 1, 2 |
| 3개월 | page 3..6 |
| 6개월 | page 7..12 |
| 1년 | page 13..25 |
| 1개월 복귀 | 없음, 차트·표 즉시 갱신 |

총 25건, page 1..25 각 1회. 중복 요청 없음.

## 화면 확인 (두 플랫폼 스크린샷)

- 헤더: 뒤로가기 · `삼성전자` · `005930 · 코스피` · 별
- 현재가 `259,500`, `▼ 9,500 (-3.53%)` 파란색
- 요약 카드 5개, 거래량 `13,938천`, 시가총액 `1,517조`
- 일별 시세: `MM.DD`, 부호 붙은 등락 빨강/파랑, 거래량 전체 자릿수
- 차트: 상승 빨강 · 하락 파랑 · 꼬리 회색, 기간마다 캔들 수 증가, 1년은 얇은 봉
- 보합: 현재가 보합은 실시간 데이터라 확인 불가. 일별 시세 표의 `0` 행은 회색으로 렌더링됨을 확인

## 방법 메모

- Android 탭: `adb shell input tap`, 스크린샷 `adb exec-out screencap -p`
- iOS 탭: `osascript` System Events `click at` (시뮬레이터 창 좌표), 스크린샷 `xcrun simctl io <udid> screenshot`
- `_DailyCache` 는 앱 수명 동안 유지되므로 GET 시퀀스는 앱 실행 후 첫 진입에서만 재현된다
