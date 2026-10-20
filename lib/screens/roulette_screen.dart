import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/ingredients.dart';
import '../services/chef_brain.dart';
import '../services/recipe_generator.dart';
import '../strings.dart';
import '../widgets/big_action_button.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/step_indicator.dart';
import 'recipe_screen.dart';

/// Step 3, part one. The slot machine spins, then the chef writes a recipe.
class RouletteScreen extends StatefulWidget {
  const RouletteScreen({
    super.key,
    required this.chefBrain,
    required this.generator,
    required this.foodIds,
  });

  final ChefBrain chefBrain;
  final RecipeGenerator generator;
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
      '🍳',
      '🥣',
      '🍽️',
      '🥕',
      '🍎',
      '🍌',
      '🧀',
      '🍅',
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

  /// Spins for a moment, then opens the live recipe screen.
  Future<void> _spin() async {
    if (_spinning) {
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _spinning = true);

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

    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) {
      return;
    }
    _reelTimer?.cancel();
    _reelTimer = null;
    setState(() => _spinning = false);

    _confetti.forward(from: 0);
    unawaited(HapticFeedback.heavyImpact());

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'recipe'),
        builder: (BuildContext context) => RecipeScreen(
          chefBrain: widget.chefBrain,
          generator: widget.generator,
          foodIds: widget.foodIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.rouletteTitle)),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
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
                      BigActionButton(
                        label: _spinning
                            ? AppStrings.spinning
                            : AppStrings.spinTheWheel,
                        icon: Icons.casino,
                        onPressed: _spinning ? null : _spin,
                        busy: _spinning,
                        semanticLabel: _spinning
                            ? AppStrings.spinning
                            : AppStrings.spinTheWheel,
                      ),
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
    final String centerEmoji = _reelEmojis[_reelIndex % length];
    final String leftEmoji = _reelEmojis[(_reelIndex - 1) % length];
    final String rightEmoji = _reelEmojis[(_reelIndex + 1) % length];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            _spinning ? AppStrings.spinningForYou : AppStrings.rouletteReady,
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
                  children: <Widget>[
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
          Text(
            _spinning ? AppStrings.detectingHint : AppStrings.spinHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
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
        children: <Widget>[
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
              children: <Widget>[
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
