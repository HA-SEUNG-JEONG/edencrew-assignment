# 관심 화면 — 정렬 바텀시트 · 빈 상태 · 상승색 시안 대조

날짜: 2026-09-12
대상 시안: `01 · 관심_empty` / `01 · 관심` / `01 · 관심_sort` (`.lfp` 원본)

## 배경 — 직전 기록 정정

같은 날 작성한 `2026-09-12-watchlist-design-gap.md`는 관심 화면 빈 상태를
"시안에 없는 상태"로 분류해 대조 대상에서 제외했다. **이는 오류다.**
빈 상태는 `01 · 관심_empty` 프레임에 실제로 존재했고, 정렬 바텀시트 역시
`01 · 관심_sort` 프레임에 별도 시안이 있었다.

직전 패스(`fbf0c3c` 헤더·행, `2da875d`/`555f2a0` 탭바)는 헤더·목록 행·탭바만
다뤘고, 이 두 화면은 대조되지 않은 채 남아 있었다. 이번 패스가 그 공백을 메운다.

## 변경 내용

### 1. 정렬 바텀시트 (`lib/ui/watchlist_screen.dart`)

| 항목 | 시안 | 변경 전 | 변경 후 |
|---|---|---|---|
| 시트 제목 | 19 / w700 | 18 | 19 |
| 헤더 블록 높이 | 64 (가로 패딩 24) | `fromLTRB(24,24,24,8)` ≈ 54 | `SizedBox(height: 64)` + 가로 패딩 24 |
| 옵션 라벨 굵기 | w500 | w400 (`regular`) | w500 (`medium`) |
| 체크 아이콘 | 24 | `iconMd` = 20 | 24 |
| 하단 여백 | 34 | SafeArea + `space2`(8) | SafeArea 단독 |
| 스크림 | `#80000000` | Material 기본 `black54`(`#8A000000`) | `colors.surfaceScrim` |

`barrierColor`를 지정하지 않던 기존 주석("실측값이 Material 기본값과 같아")은
사실과 달랐다. Material 기본 스크림은 54% 불투명이고 시안은 50%다. 주석을 정정하고
`barrierColor`를 명시했다.

### 2. 목록 행 (`lib/ui/watchlist_screen.dart`)

좌측(종목명↔부제)·우측(현재가↔등락) 세로 간격 `2`가 빠져 있었다.
양쪽 `Column`에 `spacing: dimens.space1 / 2`를 주는 방식으로 통일했다.
스켈레톤 분기에 따로 있던 `SizedBox(height: dimens.space1 / 2)`는 `spacing`이
대신하므로 제거했다.

### 3. 빈 상태 (`lib/ui/common.dart`)

| 항목 | 시안 | 변경 전 | 변경 후 |
|---|---|---|---|
| 제목 크기 | 19 | 18 | 19 |
| 아이콘↔제목 간격 | 12 | `space5`(20) | `space3`(12) |
| 제목↔본문 간격 | 12 | `space4`(16) | `space3`(12) |

`EmptyState`는 관심 빈 상태 · 관심 조회 실패 · 검색 진입 전 · 검색 결과 없음
**4곳이 공유하는 공용 위젯**이다. 관심 시안 실측값을 기준으로 네 곳을 함께 통일했다.

### 4. 상승 색 토큰 (`lib/theme/app_palette.dart`)

`red400` `#FF5B5B` → `#FF6B5B` (시안 실측).
`redAlpha12`는 `red400`에서 파생되지 않은 **별도 리터럴**이라 함께 고쳐야 한다:
`0x1FFF5B5B` → `0x1FFF6B5B`. 한쪽만 고치면 `priceUpBg`·`chartAreaUp`이 옛 색조로 남는다.

영향 범위: `priceUpText`, `priceUpBg`, `chartLineUp`, `chartAreaUp` —
검색 · 상세 · 차트 화면의 상승색도 함께 반영된다.
하락 `#4D9BEE` · 보합 `#B4B2A9`은 이미 일치해 손대지 않았다.

### 5. 스크림 토큰 신설 (`app_palette.dart` + `app_colors.dart`)

`AppPalette.blackAlpha50` = `Color(0x80000000)` →
`AppColors.surfaceScrim` 시맨틱 토큰. 화면 코드가 원색 리터럴을 직접 쓰지 않는
프로젝트 규약(`app_colors.dart` 헤더)을 따르기 위해 2단 토큰으로 추가했다.

## 손대지 않은 것

**하단 탭바** — `.lfp`의 TabBar 속성 묶음은 `index: 1`(검색 활성)인데
`labelColor`/`unselectedLabelColor`가 뒤집혀 있어(활성 항목이 비활성 색으로 칠해짐)
묶음 전체의 신뢰도가 낮다. 같은 묶음의 `indicatorWeight: 1`을 근거로 삼은
`555f2a0`(밑줄 인디케이터)은 **사용자 결정으로 현재 상태를 유지**한다.
나머지(배경 `#161614`, 상단 선 `#23231F`, 라벨 11/w400)는 이미 일치한다.

**체크 아이콘 stroke** — 시안은 `#FAFAFA`지만 `textPrimary`(`#FAF9F5`)와
사실상 구분되지 않아 익스포터 노이즈로 보고 토큰을 유지했다.

**시트 상단 1px 패딩** — 시안 시트 높이 267은 `padding top 1`을 포함한 값이다.
1px는 지각 임계 아래이고, 시트 최상단의 `SizedBox(height: 1)`은 의도가 읽히지
않아 나중에 삭제되기 쉽다. 구현 높이는 **266**으로 두었다.

## 검증

`flutter analyze` — No issues / `flutter test` — 28개 통과.

위젯 테스트로 393×852, `padding bottom: 34` 조건에서 직접 실측(검증 후 삭제):

```
SHEET  393.0 × 266.0      (헤더 64 + 옵션 56×3 + SafeArea 34)
HEADER 393.0 × 64.0
OPT    현재가순/등락률순/가나다순 각 393.0 × 56.0
CHECK  24.0 × 24.0
ROW    종목명 bottom 272.0 → 부제 top 274.0  (간격 2)
EMPTY  아이콘 40×40, 아이콘 bottom 406.5 → 제목 top 418.5  (간격 12)
       제목 bottom 445.5 → 본문 top 457.5              (간격 12)
UP     #FF6B5B   DOWN #4D9BEE   FLAT #B4B2A9   SCRIM #80000000 (alpha 0.502)
```

`showModalBottomSheet`가 띄우는 라우트는 Navigator 위에 있어, 위젯 트리 안쪽에
끼운 `MediaQuery`의 bottom inset을 받지 못한다. 시트 하단 여백을 실측하려면
`tester.view.padding`(`FakeViewPadding`)을 설정해야 한다 — 트리 내부
`MediaQuery`만 쓰면 SafeArea가 0으로 잡혀 232가 측정된다.
