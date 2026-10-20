import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/detector_service.dart';
import '../strings.dart';

/// Shows the fridge photo and draws a box around each food.
class PhotoWithBoxes extends StatelessWidget {
  const PhotoWithBoxes({
    super.key,
    required this.imageBytes,
    required this.aspectRatio,
    required this.detections,
    required this.activeFoodIds,
    this.maxHeight = 440,
  });

  final Uint8List imageBytes;
  final double aspectRatio;
  final List<FoodDetection> detections;
  final Set<String> activeFoodIds;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = width / aspectRatio;
        if (height > maxHeight) {
          height = maxHeight;
          width = height * aspectRatio;
        }
        final ColorScheme colors = Theme.of(context).colorScheme;
        return Center(
          child: Semantics(
            image: true,
            label: AppStrings.photoSemantic,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                      errorBuilder:
                          (
                            BuildContext context,
                            Object error,
                            StackTrace? stack,
                          ) {
                            return ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 54,
                                ),
                              ),
                            );
                          },
                    ),
                    CustomPaint(
                      painter: FoodBoxPainter(
                        detections: detections,
                        activeFoodIds: activeFoodIds,
                        boxColor: colors.primary,
                        labelTextColor: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Draws a rounded box and a small food label on the photo.
class FoodBoxPainter extends CustomPainter {
  FoodBoxPainter({
    required this.detections,
    required this.activeFoodIds,
    required this.boxColor,
    required this.labelTextColor,
  });

  final List<FoodDetection> detections;
  final Set<String> activeFoodIds;
  final Color boxColor;
  final Color labelTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    for (final FoodDetection detection in detections) {
      final Rect? box = detection.box;
      if (box == null || !activeFoodIds.contains(detection.food.id)) {
        continue;
      }
      final Rect rect = Rect.fromLTRB(
        box.left * size.width,
        box.top * size.height,
        box.right * size.width,
        box.bottom * size.height,
      );
      if (rect.width < 8 || rect.height < 8) {
        continue;
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        boxPaint,
      );
      _drawLabel(canvas, size, rect, detection);
    }
  }

  void _drawLabel(Canvas canvas, Size size, Rect box, FoodDetection detection) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${detection.food.emoji} ${detection.food.name}',
        style: TextStyle(
          color: labelTextColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width - 16);

    const double padding = 6;
    final double labelWidth = textPainter.width + padding * 2;
    final double labelHeight = textPainter.height + padding;
    double labelLeft = box.left;
    if (labelLeft + labelWidth > size.width) {
      labelLeft = size.width - labelWidth;
    }
    if (labelLeft < 0) {
      labelLeft = 0;
    }
    double labelTop = box.top - labelHeight - 4;
    if (labelTop < 0) {
      labelTop = box.top + 4;
    }

    final Rect labelRect = Rect.fromLTWH(
      labelLeft,
      labelTop,
      labelWidth,
      labelHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(8)),
      Paint()..color = boxColor,
    );
    textPainter.paint(
      canvas,
      Offset(labelLeft + padding, labelTop + padding / 2),
    );
  }

  @override
  bool shouldRepaint(covariant FoodBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.activeFoodIds != activeFoodIds ||
        oldDelegate.boxColor != boxColor;
  }
}
