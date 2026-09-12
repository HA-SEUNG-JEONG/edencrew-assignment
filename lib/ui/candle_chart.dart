import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../theme/theme.dart';

// 캔들 차트. 패키지 없이 CustomPainter 로 직접 그린다.
// 축 라벨과 거래량 바는 시안에 없어 그리지 않는다
class CandleChart extends StatelessWidget {
  const CandleChart({super.key, required this.prices});

  // 저장소가 최신순으로 주므로 그릴 때 뒤집어 왼쪽이 과거가 되게 한다
  final List<DailyPrice> prices;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return SizedBox(
      height: 152,
      child: CustomPaint(
        size: Size.infinite,
        painter: _CandlePainter(
          prices: prices,
          up: colors.chartLineUp,
          down: colors.chartLineDown,
        ),
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.prices, required this.up, required this.down});

  final List<DailyPrice> prices;
  final Color up;
  final Color down;

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;

    int lowest = prices.first.low;
    int highest = prices.first.high;
    for (final DailyPrice price in prices) {
      lowest = min(lowest, price.low);
      highest = max(highest, price.high);
    }
    final double span = (highest - lowest).toDouble();
    double y(int value) => span == 0
        ? size.height / 2
        : size.height * (1 - (value - lowest) / span);

    final double slot = size.width / prices.length;
    // 1년은 250봉이라 몸통이 1px 아래로 내려간다. 최소 1px 로 붙든다
    final double bodyWidth = max(1, slot * 0.6);

    for (int i = 0; i < prices.length; i++) {
      final DailyPrice price = prices[prices.length - 1 - i];
      final double centerX = slot * (i + 0.5);
      // 전일비가 아니라 당일 시가 기준이다. 전일비로 칠하면 몸통 방향과 색이 어긋난다
      final Paint paint = Paint()
        ..color = price.close >= price.open ? up : down;

      canvas.drawRect(
        Rect.fromLTRB(
          centerX - 0.5,
          y(price.high),
          centerX + 0.5,
          y(price.low),
        ),
        paint,
      );
      final double top = y(max(price.open, price.close));
      final double bottom = y(min(price.open, price.close));
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - bodyWidth / 2,
          top,
          centerX + bodyWidth / 2,
          max(bottom, top + 1),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CandlePainter oldDelegate) =>
      !identical(oldDelegate.prices, prices) ||
      oldDelegate.up != up ||
      oldDelegate.down != down;
}
