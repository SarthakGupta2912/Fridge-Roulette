import 'package:flutter/material.dart';

import '../strings.dart';
import 'app_card.dart';
import 'app_sizes.dart';
import 'custom_text.dart';

/// Shows the 3 steps of the app and marks the current one.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.currentStep});

  /// 0 means photo, 1 means check food, 2 means spin and recipe.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showLongLabels = constraints.maxWidth >= 520;
        final List<String> labels = showLongLabels
            ? const [
                AppStrings.stepSnap,
                AppStrings.stepCheck,
                AppStrings.stepSpin,
              ]
            : const [
                AppStrings.stepShortSnap,
                AppStrings.stepShortCheck,
                AppStrings.stepShortSpin,
              ];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int index = 0; index < 3; index++)
              Expanded(
                child: _StepDot(
                  number: index + 1,
                  label: labels[index],
                  fullLabel: const [
                    AppStrings.stepSnap,
                    AppStrings.stepCheck,
                    AppStrings.stepSpin,
                  ][index],
                  isCurrent: index == currentStep,
                  isDone: index < currentStep,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One circle with a number and a short label.
class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.fullLabel,
    required this.isCurrent,
    required this.isDone,
  });

  final int number;
  final String label;
  final String fullLabel;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color circleColor;
    if (isCurrent) {
      circleColor = colors.primary;
    } else if (isDone) {
      circleColor = colors.tertiary;
    } else {
      circleColor = colors.surfaceContainerHighest;
    }
    final Color textColor = isCurrent
        ? colors.onPrimary
        : isDone
        ? colors.onTertiary
        : colors.onSurfaceVariant;
    return Semantics(
      label: AppStrings.stepSemantic(number, fullLabel),
      selected: isCurrent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: AppSizes.stepDot,
            height: AppSizes.stepDot,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.outlineVariant, width: 2),
            ),
            alignment: Alignment.center,
            child: isDone
                ? Icon(Icons.check, size: AppSizes.iconStep, color: textColor)
                : CustomText.titleMedium(
                    '$number',
                    color: textColor,
                    fontWeight: FontWeight.w900,
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          CustomText.labelMedium(
            label,
            textAlign: TextAlign.center,
            color: isCurrent ? colors.primary : colors.onSurfaceVariant,
            fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
          ),
        ],
      ),
    );
  }
}

/// The little "How it works" strip on the home screen.
class HowItWorksStrip extends StatelessWidget {
  const HowItWorksStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppRadius.image,
      color: colors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.titleLarge(AppStrings.howItWorks),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: _HowStep(
                  emoji: AppStrings.stepSnapEmoji,
                  text: AppStrings.stepSnap,
                ),
              ),
              Expanded(
                child: _HowStep(
                  emoji: AppStrings.stepCheckEmoji,
                  text: AppStrings.stepCheck,
                ),
              ),
              Expanded(
                child: _HowStep(
                  emoji: AppStrings.stepSpinEmoji,
                  text: AppStrings.stepSpin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One emoji and label inside the how-it-works strip.
class _HowStep extends StatelessWidget {
  const _HowStep({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
      child: Column(
        children: [
          AppEmoji(emoji, size: AppSizes.emojiMedium),
          const SizedBox(height: AppSpacing.xs),
          CustomText.bodySmall(
            text,
            textAlign: TextAlign.center,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
