import 'package:flutter/material.dart';

import 'app_sizes.dart';

/// The named text styles we use across the app.
///
/// Keeping the names the same as [TextTheme] makes the theme easy to follow.
enum AppTextVariant {
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

/// One text widget for the whole app.
///
/// It uses the Poppins theme, respects the child's text-size setting through
/// [MediaQuery], and avoids applying that setting twice.
class CustomText extends StatelessWidget {
  const CustomText(
    this.data, {
    super.key,
    this.variant,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });

  const CustomText.headlineLarge(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.headlineLarge;

  const CustomText.headlineMedium(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.headlineMedium;

  const CustomText.headlineSmall(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.headlineSmall;

  const CustomText.titleLarge(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.titleLarge;

  const CustomText.titleMedium(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.titleMedium;

  const CustomText.titleSmall(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.titleSmall;

  const CustomText.bodyLarge(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.bodyLarge;

  const CustomText.bodyMedium(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.bodyMedium;

  const CustomText.bodySmall(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.bodySmall;

  const CustomText.labelLarge(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.labelLarge;

  const CustomText.labelMedium(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.labelMedium;

  const CustomText.labelSmall(
    this.data, {
    super.key,
    this.style,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  }) : variant = AppTextVariant.labelSmall;

  final String data;
  final AppTextVariant? variant;
  final TextStyle? style;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle base = variant == null
        ? DefaultTextStyle.of(context).style
        : _styleFor(textTheme, variant!);
    TextStyle textStyle = base.merge(style);
    if (color != null) {
      textStyle = textStyle.copyWith(color: color);
    }
    if (fontWeight != null) {
      textStyle = textStyle.copyWith(fontWeight: fontWeight);
    }

    // MediaQuery tells us the child's text-size choice. We apply it here and
    // turn off Text's own scaling so the size is never doubled.
    final TextScaler scaler =
        MediaQuery.maybeOf(context)?.textScaler ?? TextScaler.noScaling;
    final double? fontSize = textStyle.fontSize;
    if (fontSize != null) {
      textStyle = textStyle.copyWith(fontSize: scaler.scale(fontSize));
    }

    return Text(
      data,
      style: textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
      textScaler: TextScaler.noScaling,
    );
  }

  TextStyle _styleFor(TextTheme textTheme, AppTextVariant variant) {
    return switch (variant) {
      AppTextVariant.headlineLarge =>
        textTheme.headlineLarge ?? const TextStyle(),
      AppTextVariant.headlineMedium =>
        textTheme.headlineMedium ?? const TextStyle(),
      AppTextVariant.headlineSmall =>
        textTheme.headlineSmall ?? const TextStyle(),
      AppTextVariant.titleLarge => textTheme.titleLarge ?? const TextStyle(),
      AppTextVariant.titleMedium => textTheme.titleMedium ?? const TextStyle(),
      AppTextVariant.titleSmall => textTheme.titleSmall ?? const TextStyle(),
      AppTextVariant.bodyLarge => textTheme.bodyLarge ?? const TextStyle(),
      AppTextVariant.bodyMedium => textTheme.bodyMedium ?? const TextStyle(),
      AppTextVariant.bodySmall => textTheme.bodySmall ?? const TextStyle(),
      AppTextVariant.labelLarge => textTheme.labelLarge ?? const TextStyle(),
      AppTextVariant.labelMedium => textTheme.labelMedium ?? const TextStyle(),
      AppTextVariant.labelSmall => textTheme.labelSmall ?? const TextStyle(),
    };
  }
}

/// A selectable paragraph that still uses [CustomText] for its size and font.
class AppSelectableText extends StatelessWidget {
  const AppSelectableText(
    this.data, {
    super.key,
    this.variant,
    this.style,
    this.color,
    this.textAlign,
  });

  final String data;
  final AppTextVariant? variant;
  final TextStyle? style;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: CustomText(
        data,
        variant: variant,
        style: style,
        color: color,
        textAlign: textAlign,
      ),
    );
  }
}

/// A decorative emoji. Screen readers skip it unless a label is provided.
class AppEmoji extends StatelessWidget {
  const AppEmoji(
    this.emoji, {
    super.key,
    this.size = AppSizes.emoji,
    this.semanticLabel,
  });

  final String emoji;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget text = CustomText(
      emoji,
      style: TextStyle(fontSize: size, height: 1),
    );
    if (semanticLabel == null) {
      return ExcludeSemantics(child: text);
    }
    return Semantics(label: semanticLabel, child: text);
  }
}
