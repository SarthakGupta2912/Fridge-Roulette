import 'dart:math';

import 'package:flutter/material.dart';

/// A quick, light confetti burst. It is drawn with a CustomPainter,
/// so the app does not need an animation package.
class ConfettiBurst extends StatelessWidget {
  const ConfettiBurst({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              size: Size.infinite,
              painter: ConfettiPainter(progress: animation.value),
            );
          },
        ),
      ),
    );
  }
}

/// Draws colorful pieces that fly out and fall down.
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.progress});

  final double progress;

  static const List<Color> colors = [
    Color(0xFFFF7A00),
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) {
      return;
    }
    final Random random = Random(42);
    final Paint paint = Paint();
    final double fade = 1 - progress;

    for (int i = 0; i < 70; i++) {
      final double startX = size.width / 2 + (random.nextDouble() - 0.5) * 80;
      final double speedX = (random.nextDouble() - 0.5) * 420;
      final double speedY = -180 - random.nextDouble() * 320;
      final double x = startX + speedX * progress;
      final double y =
          size.height * 0.45 + speedY * progress + 380 * progress * progress;
      final double pieceSize = 5 + random.nextDouble() * 7;
      paint.color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6 + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: pieceSize,
            height: pieceSize * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
