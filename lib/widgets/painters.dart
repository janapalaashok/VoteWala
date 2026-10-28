import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Ballot box with a ticked ballot and the "VW" monogram.
class BallotMarkPainter extends CustomPainter {
  const BallotMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    // Ballot paper with tick.
    canvas.save();
    canvas.translate(50, 28);
    canvas.rotate(-0.14);
    final paper = RRect.fromRectAndRadius(const Rect.fromLTWH(-19, -22, 38, 40), const Radius.circular(4));
    canvas.drawRRect(paper, Paint()..color = Colors.white);
    canvas.drawRRect(
        paper,
        Paint()
          ..color = AppColors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    canvas.drawPath(
      Path()
        ..moveTo(-10, -2)
        ..lineTo(-2, 7)
        ..lineTo(12, -12),
      Paint()
        ..color = AppColors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Box lid.
    canvas.drawPath(
      Path()
        ..moveTo(10, 44)
        ..lineTo(90, 44)
        ..lineTo(82, 56)
        ..lineTo(18, 56)
        ..close(),
      Paint()..color = AppColors.orange,
    );
    canvas.drawLine(
        const Offset(30, 48.5),
        const Offset(70, 48.5),
        Paint()
          ..color = AppColors.orangeDark
          ..strokeWidth = 3);

    // Monogram.
    final tp = TextPainter(
      text: const TextSpan(
        style: TextStyle(fontSize: 46, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, height: 1, letterSpacing: -4),
        children: [
          TextSpan(text: 'V', style: TextStyle(color: AppColors.orange)),
          TextSpan(text: 'W', style: TextStyle(color: AppColors.green)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(50 - tp.width / 2, 56));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Line-art Andhra skyline: temple gopuram, city, cable bridge.
class SkylinePainter extends CustomPainter {
  const SkylinePainter({this.color = const Color(0xFFC9CED6)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final base = h * 0.95;
    canvas.drawLine(Offset(0, base), Offset(w, base), p);

    // Gopuram: stacked, narrowing tiers.
    var tierW = w * 0.2, x = w * 0.06, y = base;
    for (var i = 0; i < 6; i++) {
      final tierH = h * (i == 0 ? 0.16 : 0.1);
      canvas.drawRect(Rect.fromLTWH(x, y - tierH, tierW, tierH), p);
      for (var k = 1; k < 4; k++) {
        canvas.drawLine(Offset(x + tierW * k / 4, y - tierH * 0.3), Offset(x + tierW * k / 4, y - tierH * 0.7), p);
      }
      y -= tierH;
      x += tierW * 0.09;
      tierW *= 0.82;
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(x + tierW / 2, y - h * 0.04), width: tierW * 0.8, height: h * 0.08), p);
    canvas.drawLine(Offset(x + tierW / 2, y - h * 0.08), Offset(x + tierW / 2, y - h * 0.14), p);

    // City blocks.
    final rnd = Random(7);
    var bx = w * 0.3;
    while (bx < w * 0.5) {
      final bw = w * (0.03 + rnd.nextDouble() * 0.03);
      final bh = h * (0.2 + rnd.nextDouble() * 0.35);
      canvas.drawRect(Rect.fromLTWH(bx, base - bh, bw, bh), p);
      for (var wy = base - bh + 6; wy < base - 6; wy += 8) {
        canvas.drawLine(Offset(bx + 3, wy), Offset(bx + bw - 3, wy), p..strokeWidth = 0.7);
      }
      p.strokeWidth = 1.3;
      bx += bw + w * 0.008;
    }

    // Cable-stayed bridge.
    final deck = h * 0.72;
    canvas.drawLine(Offset(w * 0.52, deck), Offset(w, deck), p);
    for (final tx in [w * 0.64, w * 0.88]) {
      final top = h * 0.2;
      canvas.drawLine(Offset(tx, base), Offset(tx, top), p);
      for (var k = 1; k <= 5; k++) {
        canvas.drawLine(Offset(tx, top + k * 4), Offset(tx - w * 0.022 * k, deck), p..strokeWidth = 0.8);
        canvas.drawLine(Offset(tx, top + k * 4), Offset(tx + w * 0.022 * k, deck), p);
      }
      p.strokeWidth = 1.3;
    }
    // Water ripples.
    for (var k = 0; k < 6; k++) {
      final rx = w * (0.55 + k * 0.075);
      canvas.drawLine(Offset(rx, base - 4), Offset(rx + w * 0.03, base - 4), p..strokeWidth = 0.8);
    }
  }

  @override
  bool shouldRepaint(covariant SkylinePainter old) => old.color != color;
}

/// Coastal hills and sea, used behind the home hero text.
class HeroScenePainter extends CustomPainter {
  const HeroScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C6CA6), Color(0xFF8FC1E3)],
        ).createShader(rect),
    );
    canvas.drawCircle(Offset(w * 0.82, h * 0.22), h * 0.09, Paint()..color = const Color(0x55FFF4D6));

    Path hill(double startY, List<double> peaks) {
      final path = Path()..moveTo(0, h);
      path.lineTo(0, h * startY);
      for (var i = 0; i < peaks.length; i++) {
        final x0 = w * i / peaks.length, x1 = w * (i + 1) / peaks.length;
        path.quadraticBezierTo((x0 + x1) / 2, h * peaks[i], x1, h * (startY + (i.isEven ? 0.04 : -0.02)));
      }
      return path
        ..lineTo(w, h)
        ..close();
    }

    canvas.drawPath(hill(0.52, [0.32, 0.44, 0.28, 0.4]), Paint()..color = const Color(0xFF5C8C99));
    canvas.drawPath(hill(0.62, [0.5, 0.58, 0.42]), Paint()..color = const Color(0xFF2F6046));

    final sea = Rect.fromLTWH(0, h * 0.74, w, h * 0.26);
    canvas.drawRect(
      sea,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F7BA8), Color(0xFF1C4F78)],
        ).createShader(sea),
    );
    final wave = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2;
    final rnd = Random(3);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * w, y = h * (0.77 + rnd.nextDouble() * 0.2);
      canvas.drawLine(Offset(x, y), Offset(x + 12 + rnd.nextDouble() * 20, y), wave);
    }
    // Lighthouse on the headland.
    final lx = w * 0.86, ly = h * 0.5;
    canvas.drawPath(
      Path()
        ..moveTo(lx - 5, ly + 22)
        ..lineTo(lx - 3, ly)
        ..lineTo(lx + 3, ly)
        ..lineTo(lx + 5, ly + 22)
        ..close(),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(Rect.fromLTWH(lx - 4, ly - 5, 8, 5), Paint()..color = AppColors.red);

    // Readability scrim behind text.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.black.withValues(alpha: 0.55), Colors.black.withValues(alpha: 0.05)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ceiling fan (YSRCP symbol).
class FanPainter extends CustomPainter {
  const FanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = Paint()..color = const Color(0xFF3C4250);
    canvas.drawLine(Offset(c.dx, 0), Offset(c.dx, c.dy), p..strokeWidth = r * 0.08);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(pi / 2 + i * 2 * pi / 3);
      canvas.drawOval(Rect.fromLTWH(r * 0.1, -r * 0.12, r * 0.88, r * 0.24), p);
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.16, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Glass tumbler (Janasena symbol).
class GlassPainter extends CustomPainter {
  const GlassPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = const Color(0xFF3C4250)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.08)
        ..lineTo(w * 0.8, h * 0.08)
        ..lineTo(w * 0.7, h * 0.92)
        ..lineTo(w * 0.3, h * 0.92)
        ..close(),
      p,
    );
    p.strokeWidth = w * 0.035;
    for (final x in [0.38, 0.5, 0.62]) {
      canvas.drawLine(Offset(w * x, h * 0.2), Offset(w * (0.5 + (x - 0.5) * 0.75), h * 0.82), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
