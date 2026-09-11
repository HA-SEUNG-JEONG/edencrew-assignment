# Naver 응답 샘플 (2026-09-11 수집)

| 파일 | endpoint | 용도 |
| --- | --- | --- |
| `ac_samsung.json` | `/ac?q=삼성` | 검색 DTO. `typeName`(시장), `nationCode`, 6자리 code 필터 확인 |
| `realtime_batch.json` | `/api/realtime?query=SERVICE_ITEM:005930,000660,035420` | 배치 시세. **EUC-KR** (`nm` 필드 한글) |
| `realtime_491000.json` | 단일 종목 시세 | 상세 진입용 |
| `meta_005930.json`, `meta_491000.json` | `/fchart/domestic/stock/{symbol}` | `stockName`, `stockExchangeNameKor` |
| `sise_day_005930_p1.html`, `_p2.html` | `sise_day.naver?code=005930&page=1,2` | 10행, `lastPage=756` (pgRR 존재) |
| `sise_day_491000_p1.html` | 리브스메드 1페이지 | `lastPage=18` — 1년 탭(25페이지)보다 작은 종목 |
| `sise_day_491000_p18.html` | 리브스메드 마지막 페이지 | 5행, `pgRR` 없음 → 페이지 링크 최댓값이 lastPage |
| `sise_day_unlisted_p1.html` | 미상장 코드(495910) | 0행, 페이지 네비게이션 없음 |

확인한 사항

- `finance.naver.com`은 브라우저 User-Agent 없으면 네이버 홈으로 응답. UA 필수.
- `sise_day`, `realtime` 모두 `charset=EUC-KR`. `ac`, `meta`는 UTF-8.
- `lastPage`보다 큰 page 요청 시 마지막 페이지 내용을 **그대로 다시** 돌려줌 (빈 응답 아님). 반드시 상한 검사 필요.
- 전일비 부호는 `em.bu_pup`(상승) / `bu_pdn`(하락) / `bu_pn`(보합) 클래스로 구분.
