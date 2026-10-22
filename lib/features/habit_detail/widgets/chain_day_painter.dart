import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/habit_stats.dart';

class ChainDayPainter extends CustomPainter {
  const ChainDayPainter({
    required this.day,
    required this.color,
    required this.isDark,
  });

  final CalendarDay day;
  final Color color;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width;
    final center = Offset(cell / 2, cell / 2);

    // 1. Zincir Bağlantısı (sadece done ve link bayrakları true olan günlerde)
    if (day.mark == DayMark.done) {
      final linkPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..strokeWidth = cell * 0.12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Link Left (hücre merkezinden sol kenara)
      if (day.linkLeft) {
        canvas.drawLine(center, Offset(0, center.dy), linkPaint);
      }

      // Link Right (hücre merkezinden sağ kenara)
      if (day.linkRight) {
        canvas.drawLine(center, Offset(cell, center.dy), linkPaint);
      }

      // Satır kırılımlarında açık halka uçları
      if (day.continuesNextRow) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cell, center.dy), width: cell * 0.25, height: cell * 0.25),
          -pi / 2,
          pi,
          false,
          linkPaint,
        );
      }
      if (day.continuesPrevRow) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(0, center.dy), width: cell * 0.25, height: cell * 0.25),
          pi / 2,
          pi,
          false,
          linkPaint,
        );
      }
    }

    // 2. Gün Numarası
    final textStyle = TextStyle(
      fontSize: cell * 0.38,
      fontWeight: FontWeight.w600,
      color: switch (day.mark) {
        DayMark.beforeStart => (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant).withValues(alpha: 0.25),
        DayMark.future => (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant).withValues(alpha: 0.4),
        DayMark.done => (isDark ? AppColors.darkNeutralVariant : AppColors.neutralVariant).withValues(alpha: 0.5),
        _ => isDark ? AppColors.darkNeutral : AppColors.neutral,
      },
    );

    final textSpan = TextSpan(text: '${day.date.day}', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );

    // 3. X İşareti (done) - el çizimi hissi için tohumlanmış Random
    if (day.mark == DayMark.done) {
      final rand = Random(day.date.millisecondsSinceEpoch);
      final xPaint = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = cell * 0.12
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final inset = cell * 0.20;
      final jitter = cell * 0.05;

      // Çizgi 1: sol üstten sağ alta
      final p1 = Offset(inset + (rand.nextDouble() - 0.5) * jitter, inset + (rand.nextDouble() - 0.5) * jitter);
      final p2 = Offset(cell - inset + (rand.nextDouble() - 0.5) * jitter, cell - inset + (rand.nextDouble() - 0.5) * jitter);
      canvas.drawLine(p1, p2, xPaint);

      // Çizgi 2: sağ üstten sol alta
      final p3 = Offset(cell - inset + (rand.nextDouble() - 0.5) * jitter, inset + (rand.nextDouble() - 0.5) * jitter);
      final p4 = Offset(inset + (rand.nextDouble() - 0.5) * jitter, cell - inset + (rand.nextDouble() - 0.5) * jitter);
      canvas.drawLine(p3, p4, xPaint);
    }

    // 4. Relapse (turuncu küçük dolu daire)
    if (day.mark == DayMark.relapse) {
      final relapsePaint = Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx, cell * 0.8), cell * 0.12, relapsePaint);
    }

    // 5. Frozen (Kalkan korumalı gün - mavi/cyan küçük nokta)
    if (day.mark == DayMark.frozen) {
      final frozenPaint = Paint()
        ..color = AppColors.tertiary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(center.dx, cell * 0.8), cell * 0.12, frozenPaint);
    }

    // 6. Today (halka ile çevrili)
    if (day.isToday) {
      final todayPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, cell * 0.44, todayPaint);
    }
  }

  @override
  bool shouldRepaint(ChainDayPainter oldDelegate) {
    return oldDelegate.day.mark != day.mark ||
        oldDelegate.day.linkLeft != day.linkLeft ||
        oldDelegate.day.linkRight != day.linkRight ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}
