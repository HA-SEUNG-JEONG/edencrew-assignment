# 1일차·2일차 진행 순서 검증

**날짜**: 2026-09-13
**유형**: 검증 (코드 변경 없음)
**대상**: `docs/ASSIGNMENT.md` 진행 순서 1일차(구조 파악 · 실행 · mock · DTO), 2일차(관심 · 검색 · 관심 상태 동기화)

## 정적 검증

```
flutter analyze   No issues found!
flutter test      +30: All tests passed!
```

## 1일차

| 항목 | 결과 | 근거 |
| --- | --- | --- |
| Figma 구조 파악 | ✓ | `docs/fixes/2026-09-12-*-design-gap.md` 세 화면 시안 대조 기록 |
| `flutter run` 확인 | ✓ | Android `emulator-5554`, iOS iPhone 16 시뮬레이터 모두 기동 |
| endpoint 4개 mock 저장 | ✓ | `assets/mock/` ac · realtime(EUC-KR 배치) · meta · sise_day(p1/p2 · lastPage · 미상장) |
| DTO · 파싱 | ✓ | 4개 endpoint 를 `StockRepository` 로 실서버 호출해 파싱값 확인 (아래) |

실서버 호출은 임시 테스트(`test/live_tmp_test.dart`, 확인 후 삭제)로 저장소 코드를 직접 실행했다.

```
search('삼성')      10건, 삼성전자/005930/코스피 …
fetchQuotes(seed)   1 GET, 005930 price=259500 prev=269000 change=-9500 rate=-3.53 cap=1517109298776000
fetchMeta('005930') 삼성전자/005930/코스피
dailyPrices(2p)     20행, 20260911 close=259500 change=-9500 vol=13938673
```

`docs/NAVER_API.md` 처리 요건은 국내 6자리 필터, canonical id(`Stock.id => 'domestic:$symbol'`), 배치 조회(query 1건), EUC-KR, `lastPage` 상한까지 `test/naver_dto_test.dart` · `test/stock_repository_test.dart` 가 검증한다.

## 2일차 실행 검증

Android `emulator-5554`, iOS iPhone 16 시뮬레이터(393×852). 두 플랫폼 결과가 같았다.

| 항목 | 확인 내용 |
| --- | --- |
| 관심 목록 행 | 종목명 · `코드 · 시장` · 현재가 · 등락(하락 파랑) |
| 새로고침 | 탭 1회당 `GET …/realtime?query=SERVICE_ITEM%3A005930%2C000660%2C035720%2C247540%2C373220` 1건. 빈 목록에서는 요청 없음(Android 확인, `app_state.dart:71` 가드) |
| 정렬 3종 | 바텀시트 체크 · 헤더 칩 문구 · 순서: 현재가순(SK하이닉스 1,812,000 위) · 등락률순(카카오 -1.15% 위) · 가나다순(한글 먼저, LG · SK 뒤) |
| 검색 초기 · 로딩 | `종목을 검색해 보세요` 문구, 입력 후 스피너, `GET ac?q=SK` 1건(디바운스) |
| 검색 결과 | `SK` 접두 보라 하이라이트, 관심 종목만 별 채움 |
| 등록 · 해제 토스트 | `관심이 등록되었습니다`(별 채움) / `관심이 해제되었습니다`(별 테두리). 등록 시 `GET …query=SERVICE_ITEM%3A034730` 1건, 이미 받은 시세가 있으면 요청 없음 |
| 검색 등록 → 관심 반영 | `SK 585,000` 행이 가나다순 위치에 추가 |
| 상세 해제 → 동기화 | 상세 별 테두리 → 뒤로 → 검색 별 테두리 → 관심 목록에서 제거 |
| 검색어 지움 · 결과 없음 | X 로 초기 상태 복귀, `zzz` 는 `'zzz'와 일치하는 검색 결과를 찾지 못했습니다` |
| 관심 빈 상태 | `관심 종목이 없습니다` + 안내 문구, 헤더 · 하단 탭 유지 (Android 스와이프 삭제, iOS 검색 별 해제) |
| 스켈레톤 | Android: 오프라인 등록 시 가격 자리 박스, 새로고침 후 값 채움. iOS: 시세 도착이 첫 프레임보다 빨라 캡처 실패, `test/widget_test.dart` 정렬 테스트(시세 없는 행 맨 아래)로 대체 |
| 상승 · 보합 색 | 실시간 데이터가 전부 하락이라 확인 불가. `priceColor` 분기와 `test/format_test.dart` 보합 케이스로 대체 |

## 미결

- `StockRepository.fetchMeta` 는 구현 · 테스트만 있고 UI 에서 호출하지 않는다(`detail_screen.dart:11` 주석대로 의도된 생략). `docs/NAVER_API.md` 의 "meta 연결" 요건과 어긋나며 README 에도 기록이 없다.

## 방법 메모

- Android: `adb shell input tap/swipe/text`, `svc wifi disable` 로 오프라인, 토스트는 탭 직후 연속 캡처
- iOS: `osascript` System Events `click at`(창 원점 -455,53 · 상단 여백 52), `keystroke` 는 ASCII 만 입력 가능해 seed 해제는 종목코드 검색으로 진행
