import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

/// A warm, simple screen shown while the food finder wakes up.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.seed.withValues(alpha: 0.20), colors.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.7, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder:
                          (BuildContext context, double value, Widget? child) {
                            return Transform.scale(scale: value, child: child);
                          },
                      child: const _SplashMascot(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.loadingTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: colors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.loadingBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(strokeWidth: 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A big friendly cook with floating food around it.
class _SplashMascot extends StatelessWidget {
  const _SplashMascot();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: AppStrings.mascotSemantic,
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
            ),
            const ExcludeSemantics(
              child: Text('🧑‍🍳', style: TextStyle(fontSize: 78)),
            ),
            const Positioned(
              left: 2,
              top: 26,
              child: ExcludeSemantics(
                child: Text('🍎', style: TextStyle(fontSize: 30)),
              ),
            ),
            const Positioned(
              right: 4,
              top: 54,
              child: ExcludeSemantics(
                child: Text('🥕', style: TextStyle(fontSize: 26)),
              ),
            ),
            const Positioned(
              right: 30,
              bottom: 4,
              child: ExcludeSemantics(
                child: Text('🧀', style: TextStyle(fontSize: 28)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
