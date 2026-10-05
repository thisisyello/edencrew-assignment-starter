import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/dto/daily_candle_dto.dart';
import '../../../theme/theme.dart';

class CandlestickChart extends StatelessWidget {
  const CandlestickChart({super.key, required this.candles});

  final List<DailyCandleDto> candles;

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return SizedBox(
        height: 230,
        child: Center(
          child: Text(
            '차트 데이터가 없습니다.',
            style: TextStyle(color: context.colors.textTertiary, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 230,
      width: double.infinity,
      child: CustomPaint(
        painter: _CandlestickPainter(
          candles: candles,
          upColor: context.colors.chartLineUp,
          downColor: context.colors.chartLineDown,
          flatColor: context.colors.chartLineFlat,
          axisColor: context.colors.chartBaseline,
        ),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  const _CandlestickPainter({
    required this.candles,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.axisColor,
  });

  final List<DailyCandleDto> candles;

  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    const topPadding = 12.0;
    const bottomPadding = 20.0;

    final chartHeight = size.height - topPadding - bottomPadding;

    final highest = candles.map((candle) => candle.high).reduce(math.max);

    final lowest = candles.map((candle) => candle.low).reduce(math.min);

    final priceRange = math.max(1, highest - lowest);

    double priceToY(int price) {
      final ratio = (price - lowest) / priceRange;

      return topPadding + chartHeight * (1 - ratio);
    }

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * i / 3;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    final slotWidth = size.width / candles.length;
    final bodyWidth = math.max(1.0, math.min(8.0, slotWidth * 0.55));

    for (var i = 0; i < candles.length; i++) {
      final candle = candles[i];

      final centerX = slotWidth * i + slotWidth / 2;

      final Color color;

      if (candle.close > candle.open) {
        color = upColor;
      } else if (candle.close < candle.open) {
        color = downColor;
      } else {
        color = flatColor;
      }

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;

      final highY = priceToY(candle.high);
      final lowY = priceToY(candle.low);
      final openY = priceToY(candle.open);
      final closeY = priceToY(candle.close);

      canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), paint);

      final bodyTop = math.min(openY, closeY);
      final bodyBottom = math.max(openY, closeY);
      final bodyHeight = math.max(1.0, bodyBottom - bodyTop);

      final rect = Rect.fromLTWH(
        centerX - bodyWidth / 2,
        bodyTop,
        bodyWidth,
        bodyHeight,
      );

      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.upColor != upColor ||
        oldDelegate.downColor != downColor ||
        oldDelegate.flatColor != flatColor ||
        oldDelegate.axisColor != axisColor;
  }
}
