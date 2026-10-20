import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ingredients.dart';
import '../data/recipe.dart';
import '../services/recipe_picker.dart';
import '../strings.dart';
import '../widgets/big_action_button.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/step_indicator.dart';
import 'recipe_screen.dart';

/// Step 3, part one. A short slot-machine spin picks the recipe.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({
    super.key,
    required this.picker,
    required this.foodIds,
  });

  final RecipePicker picker;
  final List<String> foodIds;

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confetti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  final Random _random = Random();

  Timer? _reelTimer;
  late final List<String> _reelEmojis = _makeReelEmojis();
  int _reelIndex = 0;
  bool _spinning = false;
  bool _noRecipe = false;
  Recipe? _recipe;

  @override
  void dispose() {
    _reelTimer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  /// The emojis that flicker inside the wheel. We start with the child's food.
  List<String> _makeReelEmojis() {
    final List<String> emojis = <String>[];
    for (final String id in widget.foodIds) {
      final Ingredient? food = findIngredient(id);
      if (food != null && !emojis.contains(food.emoji)) {
        emojis.add(food.emoji);
      }
    }
    const List<String> extra = <String>[
      '🍎',
      '🥕',
      '🧀',
      '🍌',
      '🥦',
      '🍅',
      '🍞',
      '🥛',
    ];
    for (final String emoji in extra) {
      if (emojis.length >= 8) {
        break;
      }
      if (!emojis.contains(emoji)) {
        emojis.add(emoji);
      }
    }
    return emojis;
  }

  /// Runs the slot for a moment, then asks the picker for a recipe.
  Future<void> _spin() async {
    if (_spinning) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _spinning = true;
      _recipe = null;
      _noRecipe = false;
    });

    _reelTimer?.cancel();
    _reelTimer = Timer.periodic(const Duration(milliseconds: 90), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _reelIndex = (_reelIndex + 1 + _random.nextInt(2)) % _reelEmojis.length;
      });
    });

    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) {
      return;
    }
    _reelTimer?.cancel();
    _reelTimer = null;

    final Recipe? recipe = widget.picker.pickRecipe(widget.foodIds);
    setState(() {
      _spinning = false;
      _recipe = recipe;
      _noRecipe = recipe == null;
    });

    if (recipe != null) {
      _confetti.forward(from: 0);
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _openRecipe() async {
    final Recipe? recipe = _recipe;
    if (recipe == null) {
      return;
    }
    final RecipeScreenResult? result = await Navigator.of(context)
        .push<RecipeScreenResult>(
          MaterialPageRoute<RecipeScreenResult>(
            builder: (BuildContext context) =>
                RecipeScreen(recipe: recipe, availableFoodIds: widget.foodIds),
          ),
        );
    if (!mounted || result == null) {
      return;
    }
    if (result == RecipeScreenResult.spinAgain) {
      await _spin();
    } else {
      _startOver();
    }
  }

  /// Goes back to step 1 and throws the photo away.
  void _startOver() {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.rouletteTitle)),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const StepIndicator(currentStep: 2),
                      const SizedBox(height: 20),
                      Text(
                        AppStrings.rouletteSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),
                      _buildSlotCard(context),
                      const SizedBox(height: 20),
                      _buildControls(context),
                      const SizedBox(height: 22),
                      _buildFoodsCard(context),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: ConfettiBurst(animation: _confetti)),
          ],
        ),
      ),
    );
  }

  /// The big friendly machine with three emoji reels.
  Widget _buildSlotCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final int length = _reelEmojis.length;
    final String centerEmoji =
        _recipe?.emoji ?? _reelEmojis[_reelIndex % length];
    final String leftEmoji = _reelEmojis[(_reelIndex - 1) % length];
    final String rightEmoji = _reelEmojis[(_reelIndex + 1) % length];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Column(
        children: [
          Text(
            _spinning
                ? AppStrings.spinningForYou
                : _recipe != null
                ? AppStrings.recipeReady
                : AppStrings.rouletteReady,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Semantics(
            label: AppStrings.wheelSemantic,
            child: ExcludeSemantics(
              child: SizedBox(
                height: 132,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Reel(emoji: leftEmoji, size: 52, dimmed: true),
                    const SizedBox(width: 10),
                    _Reel(emoji: centerEmoji, size: 86),
                    const SizedBox(width: 10),
                    _Reel(emoji: rightEmoji, size: 52, dimmed: true),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_recipe != null)
            Text(
              _recipe!.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            )
          else
            Text(
              _spinning ? AppStrings.detectingHint : AppStrings.spinHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
        ],
      ),
    );
  }

  /// The big spin button, or the choices after the wheel stops.
  Widget _buildControls(BuildContext context) {
    if (_noRecipe) {
      return _buildNoRecipeCard(context);
    }

    if (_recipe != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BigActionButton(
            label: AppStrings.letsCook,
            icon: Icons.restaurant_menu,
            onPressed: _openRecipe,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _spin,
            icon: const Icon(Icons.casino_outlined),
            label: const Text(AppStrings.spinAgain),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _startOver,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text(AppStrings.newPhoto),
          ),
        ],
      );
    }

    return BigActionButton(
      label: _spinning ? AppStrings.spinning : AppStrings.spinTheWheel,
      icon: Icons.casino,
      onPressed: _spinning ? null : _spin,
      busy: _spinning,
      semanticLabel: _spinning ? AppStrings.spinning : AppStrings.spinTheWheel,
    );
  }

  /// Shown when even a two-food snack cannot be made from the foods.
  Widget _buildNoRecipeCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(
                child: Text('🧺', style: TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.rouletteNoRecipe,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.rouletteNoRecipeBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add),
                label: const Text(AppStrings.addMoreFood),
              ),
              OutlinedButton.icon(
                onPressed: _startOver,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text(AppStrings.newPhoto),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A small, read-only list of the foods that went into the wheel.
  Widget _buildFoodsCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<Ingredient> foods = <Ingredient>[];
    for (final String id in widget.foodIds) {
      final Ingredient? food = findIngredient(id);
      if (food != null) {
        foods.add(food);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.foodsInFridge,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (foods.isEmpty)
            Text(
              AppStrings.noFoodsYet,
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final Ingredient food in foods)
                  Chip(
                    avatar: ExcludeSemantics(child: Text(food.emoji)),
                    label: Text(food.name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One emoji inside the slot machine.
class _Reel extends StatelessWidget {
  const _Reel({required this.emoji, required this.size, this.dimmed = false});

  final String emoji;
  final double size;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final Widget reel = SizedBox(
      width: size + 16,
      height: size + 34,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 110),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            emoji,
            key: ValueKey<String>(emoji),
            style: TextStyle(fontSize: size),
          ),
        ),
      ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: reel) : reel;
  }
}
