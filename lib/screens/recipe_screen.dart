import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../data/recipe.dart';
import '../services/chef_brain.dart';
import '../services/recipe_generator.dart';
import '../services/recipe_prompt.dart';
import '../strings.dart';
import '../widgets/big_action_button.dart';
import '../widgets/layout_helper.dart';
import '../widgets/step_indicator.dart';
import 'model_download_screen.dart';

/// Step 3, part two. The AI chef writes a recipe live, word by word.
class RecipeScreen extends StatefulWidget {
  const RecipeScreen({
    super.key,
    required this.chefBrain,
    required this.generator,
    required this.foodIds,
  });

  final ChefBrain chefBrain;
  final RecipeGenerator generator;
  final List<String> foodIds;

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  Recipe? _recipe;
  String _raw = '';
  bool _loading = true;
  bool _usingAi = true;
  bool _rawMode = false;
  String? _problem;
  String? _notice;
  StreamSubscription<String>? _subscription;
  Timer? _backgroundTimer;
  int _run = 0;

  List<String> get _foodNames {
    final List<String> names = <String>[];
    for (final String id in widget.foodIds) {
      final Ingredient? food = findIngredient(id);
      final String name = food?.name ?? id;
      if (name.trim().isNotEmpty && !names.contains(name)) {
        names.add(name);
      }
    }
    return names;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start(useAi: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundTimer?.cancel();
    _subscription?.cancel();
    unawaited(widget.generator.stop());
    unawaited(widget.generator.release());
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTimer?.cancel();
      _backgroundTimer = Timer(const Duration(minutes: 2), () {
        unawaited(widget.generator.release());
      });
    } else if (state == AppLifecycleState.resumed) {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;
    }
  }

  Future<void> _start({required bool useAi}) async {
    final int run = ++_run;
    await _subscription?.cancel();
    _subscription = null;
    await widget.generator.stop();
    if (!mounted || run != _run) {
      return;
    }

    setState(() {
      _loading = true;
      _recipe = null;
      _raw = '';
      _rawMode = false;
      _problem = null;
      _notice = null;
      _usingAi = useAi;
    });

    if (!useAi) {
      _showQuickChef();
      return;
    }

    final bool ready = await widget.generator.isAiReady();
    if (!mounted || run != _run) {
      return;
    }
    if (!ready) {
      _showQuickChef(notice: AppStrings.aiNoModel);
      return;
    }

    try {
      final Stream<String> stream = widget.generator.makeRecipe(_foodNames);
      _subscription = stream.listen(
        (String token) => _onToken(token, run),
        onError: (Object error) => _onError(error, run),
        onDone: () => _onDone(run),
        cancelOnError: false,
      );
    } catch (error) {
      _showQuickChef(notice: AppStrings.aiHiccup);
    }
  }

  void _onToken(String token, int run) {
    if (!mounted || run != _run) {
      return;
    }
    final String clean = token.replaceAll(RegExp(r'<\|[^>]*\|>'), '');
    if (clean.isEmpty) {
      return;
    }
    setState(() => _raw += clean);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      );
    });
  }

  void _onError(Object error, int run) {
    if (!mounted || run != _run) {
      return;
    }
    if (error is TimeoutException) {
      setState(() {
        _loading = false;
        _problem = 'timeout';
      });
      return;
    }
    _showQuickChef(notice: AppStrings.aiHiccup);
  }

  void _onDone(int run) {
    if (!mounted || run != _run) {
      return;
    }
    if (_raw.trim().isEmpty) {
      _showQuickChef(notice: AppStrings.aiHiccup);
      return;
    }

    final Recipe? parsed = parseRecipeText(
      _raw,
      isAi: _usingAi,
      foods: _foodNames,
    );
    setState(() {
      _loading = false;
      if (parsed == null) {
        _rawMode = true;
      } else {
        _recipe = parsed;
      }
    });
  }

  void _showQuickChef({String? notice}) {
    if (!mounted) {
      return;
    }
    final Recipe quick = widget.generator.makeQuickRecipe(_foodNames);
    setState(() {
      _recipe = quick;
      _raw = '';
      _rawMode = false;
      _loading = false;
      _usingAi = false;
      _problem = null;
      _notice = notice;
    });
  }

  Future<void> _stop() async {
    ++_run;
    await _subscription?.cancel();
    _subscription = null;
    await widget.generator.stop();
    if (!mounted) {
      return;
    }

    final Recipe? parsed = _raw.trim().isEmpty
        ? null
        : parseRecipeText(_raw, isAi: _usingAi, foods: _foodNames);
    setState(() {
      _loading = false;
      _notice = null;
      if (parsed != null) {
        _recipe = parsed;
        _rawMode = false;
        _problem = null;
      } else if (_raw.trim().isNotEmpty) {
        _rawMode = true;
        _problem = null;
      } else {
        _problem = 'stopped';
      }
    });
  }

  Future<void> _makeAnother() async {
    await _start(useAi: _usingAi);
  }

  Future<void> _retryAi() async {
    await _start(useAi: true);
  }

  Future<void> _getAiChef() async {
    if (widget.chefBrain.isReady) {
      await _retryAi();
      return;
    }
    final bool? downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            ModelDownloadScreen(chefBrain: widget.chefBrain, canSkip: false),
      ),
    );
    if (!mounted || downloaded != true) {
      return;
    }
    await widget.chefBrain.refresh();
    if (!mounted) {
      return;
    }
    await _retryAi();
  }

  void _changeFoods() {
    Navigator.of(context).popUntil(
      (Route<dynamic> route) => route.settings.name == 'check' || route.isFirst,
    );
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
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                wide ? 28 : 20,
                8,
                wide ? 28 : 20,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const StepIndicator(currentStep: 2),
                      const SizedBox(height: 14),
                      _ChefBadge(isAi: _usingAi),
                      const SizedBox(height: 12),
                      _buildHero(context),
                      if (_notice != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _NoticeCard(text: _notice!),
                      ],
                      if (_problem == 'timeout') ...<Widget>[
                        const SizedBox(height: 12),
                        _ProblemCard(
                          emoji: '🤔',
                          title: AppStrings.timeoutTitle,
                          body: AppStrings.timeoutBody,
                        ),
                      ],
                      if (_problem == 'stopped') ...<Widget>[
                        const SizedBox(height: 12),
                        _ProblemCard(
                          emoji: '🛑',
                          title: AppStrings.stoppedTitle,
                          body: AppStrings.stoppedBody,
                        ),
                      ],
                      if (_rawMode) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildRawCard(context),
                      ],
                      if (_loading) ...<Widget>[
                        const SizedBox(height: 16),
                        _buildActions(context),
                      ] else if (_recipe != null) ...<Widget>[
                        const SizedBox(height: 14),
                        _buildIngredients(context, _recipe!),
                        const SizedBox(height: 16),
                        _buildSteps(context, _recipe!),
                        const SizedBox(height: 16),
                        _buildTip(context, _recipe!),
                        const SizedBox(height: 18),
                        _buildActions(context),
                      ] else if (_problem != null || _rawMode) ...<Widget>[
                        const SizedBox(height: 16),
                        _buildProblemActions(context),
                      ],
                      const SizedBox(height: 20),
                      _buildSafetyCard(context),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.pantryNote,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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

  Widget _buildHero(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Recipe? recipe = _recipe;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
        ),
      ),
      child: Column(
        children: <Widget>[
          if (_loading) ...<Widget>[
            const _BobbingChef(emoji: '🧑‍🍳', size: 72),
            const SizedBox(height: 8),
            Text(
              _usingAi
                  ? AppStrings.writingRecipeTitle
                  : AppStrings.quickChefWriting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.writingRecipeBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_raw.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              _buildLiveText(context),
            ],
          ] else if (recipe != null) ...<Widget>[
            ExcludeSemantics(
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 64)),
            ),
            const SizedBox(height: 6),
            Text(
              recipe.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _FactChip(
                  icon: Icons.schedule,
                  text: '${recipe.minutes} ${AppStrings.minutesShort}',
                ),
                _FactChip(icon: Icons.speed, text: recipe.level),
              ],
            ),
          ] else ...<Widget>[
            const ExcludeSemantics(
              child: Text('📝', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.rawRecipeTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveText(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppStrings.liveRecipe,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${_raw.trimLeft()} ▍',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildRawCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
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
            AppStrings.rawRecipeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.rawRecipeBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 10),
          SelectableText(_raw, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildIngredients(BuildContext context, Recipe recipe) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> foods = recipe.foods.isNotEmpty
        ? recipe.foods
        : _foodNames;
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
            AppStrings.ingredientsLabel,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String food in foods)
                Chip(
                  avatar: ExcludeSemantics(child: Text(_emojiForFood(food))),
                  label: Text(food),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context, Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          AppStrings.stepsLabel,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (recipe.steps.isEmpty)
          Text(
            AppStrings.recipeNotFound,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        else
          for (int index = 0; index < recipe.steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StepRow(number: index + 1, text: recipe.steps[index]),
            ),
      ],
    );
  }

  Widget _buildTip(BuildContext context, Recipe recipe) {
    if (recipe.tip.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExcludeSemantics(
            child: Text('💡', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  AppStrings.chefTip,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(recipe.tip, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_loading) {
      return OutlinedButton.icon(
        onPressed: _stop,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text(AppStrings.stopChef),
      );
    }

    final bool aiReady = widget.chefBrain.isReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BigActionButton(
          label: AppStrings.makeAnother,
          icon: Icons.auto_awesome,
          onPressed: _makeAnother,
        ),
        const SizedBox(height: 8),
        if (!_usingAi) ...<Widget>[
          OutlinedButton.icon(
            onPressed: aiReady ? _retryAi : _getAiChef,
            icon: Icon(aiReady ? Icons.refresh : Icons.download),
            label: Text(aiReady ? AppStrings.tryAiAgain : AppStrings.getAiChef),
          ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: _changeFoods,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text(AppStrings.changeFoods),
        ),
      ],
    );
  }

  Widget _buildProblemActions(BuildContext context) {
    final bool aiReady = widget.chefBrain.isReady;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BigActionButton(
          label: AppStrings.tryAiAgain,
          icon: Icons.refresh,
          onPressed: _retryAi,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showQuickChef(),
          icon: const Icon(Icons.soup_kitchen_outlined),
          label: const Text(AppStrings.useQuickChefAction),
        ),
        const SizedBox(height: 6),
        if (!aiReady)
          OutlinedButton.icon(
            onPressed: _getAiChef,
            icon: const Icon(Icons.download),
            label: const Text(AppStrings.getAiChef),
          ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: _changeFoods,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text(AppStrings.changeFoods),
        ),
      ],
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExcludeSemantics(
            child: Text('🦺', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.safetyNote,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _emojiForFood(String name) {
    for (final Ingredient food in allIngredients) {
      if (food.name.toLowerCase() == name.toLowerCase()) {
        return food.emoji;
      }
    }
    return '🍽️';
  }
}

class _ChefBadge extends StatelessWidget {
  const _ChefBadge({required this.isAi});

  final bool isAi;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isAi ? colors.primaryContainer : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExcludeSemantics(
              child: Text(
                isAi ? '🤖' : '⚡',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isAi ? AppStrings.aiChef : AppStrings.quickChef,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const ExcludeSemantics(
            child: Text('🤖', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BobbingChef extends StatelessWidget {
  const _BobbingChef({required this.emoji, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (BuildContext context, double value, Widget? child) {
          return Transform.translate(
            offset: Offset(0, -7 * value),
            child: Transform.rotate(angle: (value - 0.5) * 0.08, child: child),
          );
        },
        child: Text(emoji, style: TextStyle(fontSize: size)),
      ),
    );
  }
}
