import 'package:flutter/material.dart';

/// Hand-drawn Veg (leaf) / Non-Veg (drumstick) icons, painted natively
/// via CustomPainter from the exact SVG path data supplied — no
/// flutter_svg dependency needed for just two fixed icons. Both are
/// drawn on a 100x100 design grid and scaled to [size].
class VegLeafIcon extends StatelessWidget {
  final double size;
  const VegLeafIcon({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _VegLeafPainter()),
      );
}

class NonVegDrumstickIcon extends StatelessWidget {
  final double size;
  const NonVegDrumstickIcon({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _NonVegDrumstickPainter()),
      );
}

class _VegLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    final leaf = Path()
      ..moveTo(24, 76)
      ..cubicTo(24, 45, 45, 22, 78, 20)
      ..cubicTo(78, 53, 55, 76, 24, 76)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF1B7A42));

    final vein = Path()
      ..moveTo(28, 72)
      ..cubicTo(40, 60, 52, 48, 70, 25);
    canvas.drawPath(
      vein,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final stem = Path()
      ..moveTo(24, 76)
      ..cubicTo(20, 81, 16, 85, 12, 87);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF1B7A42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NonVegDrumstickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    // SVG's <g transform="rotate(-30 50 50)"> — rotate everything below
    // by -30deg around the (50,50) pivot of the 100x100 design grid.
    canvas.translate(50, 50);
    canvas.rotate(-30 * 3.1415926535 / 180);
    canvas.translate(-50, -50);

    final bonePaint = Paint()..color = const Color(0xFFE6D7C3);
    canvas.drawCircle(const Offset(28, 58), 7, bonePaint);
    canvas.drawCircle(const Offset(28, 70), 7, bonePaint);
    canvas.drawRect(const Rect.fromLTWH(28, 58, 22, 12), bonePaint);

    final meat = Path()
      ..moveTo(40, 64)
      ..cubicTo(40, 44, 56, 32, 72, 32)
      ..cubicTo(86, 32, 92, 48, 88, 64)
      ..cubicTo(82, 78, 60, 78, 40, 64)
      ..close();
    canvas.drawPath(meat, Paint()..color = const Color(0xFFC0392B));

    final shine = Path()
      ..moveTo(60, 40)
      ..cubicTo(68, 40, 75, 45, 76, 52);
    canvas.drawPath(
      shine,
      Paint()
        ..color = const Color(0xFFFF8A80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
