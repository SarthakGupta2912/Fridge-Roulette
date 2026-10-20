import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../data/recipe.dart';
import '../strings.dart';
import '../widgets/big_action_button.dart';
import '../widgets/layout_helper.dart';
import '../widgets/step_indicator.dart';

/// What the child chose at the bottom of the recipe page.
enum RecipeScreenResult { spinAgain, newPhoto }

/// Step 3, part two. The full recipe challenge with steps and a safety note.
class RecipeScreen extends StatelessWidget {
  const RecipeScreen({
    super.key,
    required this.recipe,
    required this.availableFoodIds,
  });

  final Recipe recipe;
  final List<String> availableFoodIds;

  /// Easy, Medium or Tricky, in words a child understands.
  String _difficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppStrings.easy;
      case 2:
        return AppStrings.medium;
      default:
        return AppStrings.tricky;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.recipeTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide = isWideScreen(constraints.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 20,
                8,
                wide ? 28 : 20,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const StepIndicator(currentStep: 2),
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: _buildAbout(context)),
                            const SizedBox(width: 28),
                            Expanded(flex: 6, child: _buildSteps(context)),
                          ],
                        )
                      else ...[
                        _buildAbout(context),
                        const SizedBox(height: 24),
                        _buildSteps(context),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _buildActions(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The name, time, items and the fun twist.
  Widget _buildAbout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(context),
        const SizedBox(height: 16),
        _buildTwist(context),
        const SizedBox(height: 20),
        _buildIngredients(context),
      ],
    );
  }

  Widget _buildHero(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Text(recipe.emoji, style: const TextStyle(fontSize: 76)),
          ),
          const SizedBox(height: 6),
          Text(
            recipe.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.schedule,
                label: '${recipe.minutes} ${AppStrings.minutesShort}',
              ),
              _InfoPill(
                icon: Icons.speed,
                label: _difficultyLabel(recipe.difficulty),
              ),
              if (recipe.isMixAndMatch)
                _InfoPill(
                  icon: Icons.auto_awesome,
                  label: AppStrings.mixAndMatch,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTwist(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Text('💡', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.challengeTwist,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  recipe.twist,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.ingredientsLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final String id in recipe.requiredFoods)
                _buildFoodRow(context, id),
              if (recipe.optionalFoods.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    AppStrings.extraFood,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                ),
                for (final String id in recipe.optionalFoods)
                  _buildFoodRow(context, id, optional: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          AppStrings.pantryNote,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  /// One food line with a tick when the child already has it.
  Widget _buildFoodRow(
    BuildContext context,
    String id, {
    bool optional = false,
  }) {
    final Ingredient? food = findIngredient(id);
    if (food == null) {
      return const SizedBox.shrink();
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool haveIt = availableFoodIds.contains(id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(food.emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              food.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Icon(
            haveIt ? Icons.check_circle : Icons.add_circle_outline,
            color: optional ? colors.onSurfaceVariant : colors.tertiary,
            size: 24,
          ),
        ],
      ),
    );
  }

  /// The numbered cooking steps and the grown-up safety note.
  Widget _buildSteps(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.stepsLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (int index = 0; index < recipe.steps.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(
                          '${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recipe.steps[index],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colors.onSecondaryContainer,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.safetyNote,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BigActionButton(
          label: AppStrings.spinAgain,
          icon: Icons.casino,
          onPressed: () =>
              Navigator.of(context).pop(RecipeScreenResult.spinAgain),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(RecipeScreenResult.newPhoto),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text(AppStrings.newPhoto),
        ),
      ],
    );
  }
}

/// A small rounded label for time, difficulty and recipe type.
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}
