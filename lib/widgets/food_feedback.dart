import 'package:flutter/material.dart';

import '../strings.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: onPrimary,
                child: Text(primaryLabel, textAlign: TextAlign.center),
              ),
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel, textAlign: TextAlign.center),
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
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ExcludeSemantics(
            child: Text('🧺', style: TextStyle(fontSize: 58)),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.noPhotoYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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
    this.borderRadius = 24,
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
                      padding: const EdgeInsets.all(20),
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
                              const SizedBox(height: 12),
                              Text(
                                waitingForModel
                                    ? AppStrings.getReady
                                    : AppStrings.lookingForFood,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: onScrim),
                              ),
                              if (showProgress) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                                  const SizedBox(height: 6),
                                  Text(
                                    progressLabel!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: onScrim,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 6),
                              Text(
                                waitingForModel
                                    ? AppStrings.loadingBody
                                    : AppStrings.detectingHint,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: onScrim),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: onScrim,
                      minimumSize: const Size(56, 48),
                    ),
                    child: const Text(AppStrings.stopLooking),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
