import 'package:flutter/material.dart';

import 'app_sizes.dart';
import 'custom_text.dart';

/// A soft surface card. Use this instead of repeating the same decoration.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.card,
    this.border,
    this.constraints,
    this.width,
    this.onTap,
  });

  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double radius;
  final BoxBorder? border;
  final BoxConstraints? constraints;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: border,
    );

    if (onTap == null) {
      return Container(
        width: width,
        constraints: constraints,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }

    final Widget card = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (width == null && constraints == null) {
      return card;
    }
    return Container(width: width, constraints: constraints, child: card);
  }
}

/// One label and value line, used by the model and settings cards.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 92,
  });

  final String label;
  final String value;
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: labelWidth, child: CustomText.labelLarge(label)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: CustomText.bodyMedium(value)),
        ],
      ),
    );
  }
}
