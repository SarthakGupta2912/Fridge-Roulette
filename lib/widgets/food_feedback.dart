import 'package:flutter/material.dart';

import '../strings.dart';
import 'app_card.dart';
import 'app_sizes.dart';
import 'custom_text.dart';

/// A friendly card that explains a problem and gives clear buttons.
class FoodProblemCard extends StatelessWidget {
  const FoodProblemCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String emoji;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppEmoji(emoji, size: AppSizes.emojiMedium),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: CustomText.titleMedium(title)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyMedium(body),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.tonal(
                onPressed: onPrimary,
                child: CustomText(primaryLabel, textAlign: TextAlign.center),
              ),
              OutlinedButton(
                onPressed: onSecondary,
                child: CustomText(secondaryLabel, textAlign: TextAlign.center),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A soft place holder when the child adds food by hand, without a photo.
class NoPhotoCard extends StatelessWidget {
  const NoPhotoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      constraints: const BoxConstraints(minHeight: 230),
      width: double.infinity,
      radius: AppRadius.image,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 26,
      ),
      color: colors.surfaceContainerHigh,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppEmoji('🧺', size: 58),
          const SizedBox(height: AppSpacing.md),
          CustomText.bodyLarge(
            AppStrings.noPhotoYet,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Covers the photo while the food finder is thinking.
class DetectingOverlay extends StatelessWidget {
  const DetectingOverlay({
    super.key,
    required this.waitingForModel,
    this.progress = 0,
    this.progressLabel,
    this.onCancel,
    this.borderRadius = AppRadius.image,
  });

  final bool waitingForModel;

  /// 0.0 to 1.0 while the close-up scan runs. 0 shows an indeterminate bar.
  final double progress;
  final String? progressLabel;
  final VoidCallback? onCancel;

  /// 0 for a full-page overlay, or a rounded value over a photo.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool showProgress = !waitingForModel;
    // White stays readable on the dark scrim in both light and dark themes.
    const Color onScrim = Colors.white;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ColoredBox(
        color: colors.scrim.withValues(alpha: 0.72),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    // Small landscape screens with large text can be shorter
                    // than the card. Let it scroll instead of clipping.
                    final double minHeight = (constraints.maxHeight - 40)
                        .clamp(0.0, double.infinity)
                        .toDouble();
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CustomText.titleLarge(
                                waitingForModel
                                    ? AppStrings.getReady
                                    : AppStrings.lookingForFood,
                                textAlign: TextAlign.center,
                                color: onScrim,
                              ),
                              if (showProgress) ...[
                                const SizedBox(height: AppSpacing.md),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.small,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    minHeight: 9,
                                    color: colors.primary,
                                    backgroundColor: onScrim.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                                if (progressLabel != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  CustomText.labelLarge(
                                    progressLabel!,
                                    textAlign: TextAlign.center,
                                    color: onScrim,
                                  ),
                                ],
                              ],
                              const SizedBox(height: AppSpacing.xs),
                              CustomText.bodyMedium(
                                waitingForModel
                                    ? AppStrings.loadingBody
                                    : AppStrings.detectingHint,
                                textAlign: TextAlign.center,
                                color: onScrim,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Keep Stop reachable without scrolling, even in landscape.
              if (showProgress && onCancel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    0,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: onScrim,
                      minimumSize: const Size(
                        AppSizes.touchTarget,
                        AppSizes.minTouchTarget,
                      ),
                    ),
                    child: const CustomText(AppStrings.stopLooking),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
