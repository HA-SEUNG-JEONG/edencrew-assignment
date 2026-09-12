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
