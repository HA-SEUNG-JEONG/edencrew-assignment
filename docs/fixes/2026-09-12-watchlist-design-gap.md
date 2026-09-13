# 관심 화면 시안(.lfp) 대조 UI 갭 수정

**날짜**: 2026-09-12
**유형**: fix
**관련 파일**: `lib/main.dart`, `lib/ui/watchlist_screen.dart`, `lib/ui/search_screen.dart`, `lib/ui/detail_screen.dart`

## 변경 내용

직전 실측 패스(`c868b5d`/`df4fdb8`/`c5ed945`)는 행 텍스트와 요약 카드만 다뤘고
관심 화면 헤더와 하단 탭바는 대상에서 빠져 있었다. `.lfp` 시안의 폰트 크기(행 15/11)가
`c868b5d`의 역산 결과와 정확히 일치해 `.lfp`를 수치 근거로 채택하고, 어긋난 항목만 교정했다.

시안에 없는 상태(빈 상태·스와이프 삭제·당겨서 새로고침)는 과제 요구사항상 의도된
자체 판단이므로 건드리지 않았다.

## 주요 구현 사항

### 하단 탭바 (`2da875d`)

- 아이콘(`Icons.star`/`star_border`/`search`)과 아이콘↔라벨 간격 제거 — 시안 TabBar는 11/w400 라벨 전용
- 선택 표시는 `navActive`/`navInactive` 색 대비만 사용, 인디케이터 없음
- `dimens.tabBarHeight`(56) 고정 해제. 라벨만 남기면 시안 높이가 약 31이라 터치 영역에
  못 미쳐 `kMinInteractiveDimension`(48)으로 최소 높이를 보장했다 — 시안 대비 의도된 편차

### 헤더·행·정렬 칩 (`fbf0c3c`)

| 항목 | 변경 |
|---|---|
| 헤더 높이 | `rowMinHeight`(56) 고정 → 상하 `space3` 패딩 (실측 52) |
| 헤더 제목 | 18 → 19 |
| 정렬 칩↔새로고침 | `space3` → `space4` |
| 새로고침 아이콘·스피너 | `iconSm`(16) → `iconMd`(20) |
| 정렬 칩 라벨 | w400 → w700, 라벨↔화살표 간격 4 제거 |
| 정렬 화살표 | `iconSm` → `iconMd` |
| 행 높이 | `60` 하드코딩 → 상하 `space3` 패딩 (실측 62) |
| 부제 색 | `textTertiary`(#888780) → `textSecondary`(#B4B2A9) |
| 현재가 굵기 | w700 → w500 (종목명과 동일) |

부제 색과 보조 아이콘 크기는 검색·상세 화면에도 같이 적용해 세 화면을 통일했다.
`search_screen.dart:186`(힌트), `detail_screen.dart:324`(요약 카드 라벨), `:396`(표 헤더)의
`textTertiary`는 부제가 아니라 그대로 두었다.

## 검증

- `flutter analyze` — No issues found
- `flutter test` — 28개 전부 통과 (탭 라벨 텍스트 기반 finder라 아이콘 제거 영향 없음)
- 393×852 렌더 실측: 헤더 52 / 행 62 / 탭바 48+1, 스켈레톤 64×16·48×12 유지

## 미결

`.lfp`의 TabBar bulb가 Lucy에서 수동 교체된 컴포넌트일 가능성이 있어 원본 Figma에는
아이콘이 있었을 수 있다. 되돌릴 수 있게 탭바 변경만 `2da875d`로 분리해 두었다.

## 관련 커밋

- `2da875d` fix: 하단 탭을 시안대로 라벨 전용으로 되돌림
- `fbf0c3c` fix: 관심 화면 헤더·행·정렬 칩을 시안 실측값에 맞춤
