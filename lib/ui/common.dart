import 'package:flutter/material.dart';

import '../theme/theme.dart';

// 상승 빨강 / 하락 파랑 / 보합. 세 화면이 같은 규칙을 쓴다
Color priceColor(BuildContext context, int change) {
  final AppColors colors = context.colors;
  if (change > 0) return colors.priceUpText;
  if (change < 0) return colors.priceDownText;
  return colors.priceFlatText;
}

// 아직 시세를 받지 못한 자리. 시안에 애니메이션 정의가 없어 정적 박스로 둔다
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusSm),
      ),
    );
  }
}

// 관심 없음 · 검색 전 · 검색 결과 없음 · 조회 실패에서 같은 뼈대를 쓴다
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final String? actionLabel = this.actionLabel;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: colors.textTertiary),
            SizedBox(height: dimens.space5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
              ),
            ),
            SizedBox(height: dimens.space4),
            Text(
              description,
              textAlign: TextAlign.center,
              // 검색어가 길어도 안내 문구가 화면을 넘기지 않게 두 줄로 묶는다
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 11,
                fontWeight: AppTypography.regular,
                height: 14 / 11,
              ),
            ),
            if (actionLabel != null) ...<Widget>[
              SizedBox(height: dimens.space5),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: colors.accentDefault,
                    fontSize: 13,
                    fontWeight: AppTypography.medium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 관심 등록 버튼. 검색 행과 상세 헤더가 같이 쓴다.
// 아이콘 오른쪽 여백만큼 부모 행의 우측 패딩을 줄여 시안 위치를 맞춘다
class StarButton extends StatelessWidget {
  const StarButton({super.key, required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dimens.space2,
          vertical: dimens.space3,
        ),
        child: Icon(
          active ? Icons.star : Icons.star_border,
          size: 18,
          color: active ? colors.favoriteActive : colors.favoriteInactive,
        ),
      ),
    );
  }
}

// 종목명에서 검색어와 일치하는 구간만 전경색을 바꾼다. 시안에 배경 칠은 없다
List<TextSpan> highlightSpans(String name, String query, AppColors colors) {
  final String needle = query.trim().toLowerCase();
  if (needle.isEmpty) return <TextSpan>[TextSpan(text: name)];

  final String haystack = name.toLowerCase();
  final List<TextSpan> spans = <TextSpan>[];
  int cursor = 0;
  for (int at = haystack.indexOf(needle); at >= 0;) {
    if (at > cursor) spans.add(TextSpan(text: name.substring(cursor, at)));
    spans.add(
      TextSpan(
        text: name.substring(at, at + needle.length),
        style: TextStyle(color: colors.searchHighlight),
      ),
    );
    cursor = at + needle.length;
    at = haystack.indexOf(needle, cursor);
  }
  if (cursor < name.length) spans.add(TextSpan(text: name.substring(cursor)));
  return spans;
}

// 관심 등록·해제 결과 토스트.
// 연속 토글에서 지난 토스트가 줄 서면 현재 상태와 어긋나므로 먼저 비운다
void showFavoriteToast(BuildContext context, bool added) {
  final AppColors colors = context.colors;
  final AppDimens dimens = context.dimens;
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      // 하단 탭 위로 12 띄운다
      margin: EdgeInsets.fromLTRB(
        dimens.space4,
        0,
        dimens.space4,
        dimens.space3,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17),
      backgroundColor: colors.surfaceOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      duration: const Duration(seconds: 2),
      dismissDirection: DismissDirection.down,
      content: SizedBox(
        height: 46,
        child: Row(
          children: <Widget>[
            Icon(
              added ? Icons.star : Icons.star_border,
              size: dimens.iconSm,
              color: added ? colors.favoriteActive : colors.textSecondary,
            ),
            SizedBox(width: dimens.space2 + 1),
            Text(
              added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
