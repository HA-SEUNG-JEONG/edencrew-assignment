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
