import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ingredients.dart';
import '../data/recipe.dart';
import '../services/chef_brain.dart';
import '../services/recipe_generator.dart';
import '../services/recipe_prompt.dart';
import '../strings.dart';
import '../widgets/app_card.dart';
import '../widgets/app_page.dart';
import '../widgets/app_sizes.dart';
import '../widgets/big_action_button.dart';
import '../widgets/custom_text.dart';
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

  /// The words as the child should see them, without model tags or escapes.
  String get _plainRaw => plainRecipeText(_raw, streaming: _loading);

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
    if (_plainRaw.trim().isEmpty) {
      _showQuickChef(notice: AppStrings.aiHiccup);
      return;
    }

    final Recipe? parsed = parseRecipeText(
      _raw,
      isAi: _usingAi,
      foods: _foodNames,
    );
    if (_usingAi &&
        parsed != null &&
        !recipeUsesOnlyAllowedFoods(parsed, _foodNames)) {
      _showQuickChef(notice: AppStrings.aiExtraFood);
      return;
    }
    if (parsed == null && !RegExp(r'[A-Za-z]').hasMatch(_plainRaw)) {
      // The model sometimes writes only spaces or newline tokens. There is
      // nothing for the child to read, so use the reliable Quick chef.
      _showQuickChef(notice: AppStrings.aiHiccup);
      return;
    }
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

    final Recipe? parsed = _plainRaw.trim().isEmpty
        ? null
        : parseRecipeText(_raw, isAi: _usingAi, foods: _foodNames);
    setState(() {
      _loading = false;
      _notice = null;
      if (parsed != null) {
        _recipe = parsed;
        _rawMode = false;
        _problem = null;
      } else if (_plainRaw.trim().isNotEmpty) {
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
    return AppPage(
      title: AppStrings.recipeTitle,
      body: AppScrollBody(
        controller: _scrollController,
        maxWidth: AppSizes.maxContentWidth,
        topPadding: AppSpacing.sm,
        bottomPadding: 36,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const StepIndicator(currentStep: 2),
            const SizedBox(height: AppSpacing.md),
            _ChefBadge(isAi: _usingAi),
            const SizedBox(height: AppSpacing.md),
            _buildHero(context),
            if (_notice != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _NoticeCard(text: _notice!),
            ],
            if (_problem == 'timeout') ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _ProblemCard(
                emoji: '🤔',
                title: AppStrings.timeoutTitle,
                body: AppStrings.timeoutBody,
              ),
            ],
            if (_problem == 'stopped') ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _ProblemCard(
                emoji: '🛑',
                title: AppStrings.stoppedTitle,
                body: AppStrings.stoppedBody,
              ),
            ],
            if (_rawMode) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildRawCard(context),
            ],
            if (_loading) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context),
            ] else if (_recipe != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _buildIngredients(context, _recipe!),
              const SizedBox(height: AppSpacing.lg),
              _buildSteps(context, _recipe!),
              const SizedBox(height: AppSpacing.lg),
              _buildTip(context, _recipe!),
              const SizedBox(height: AppSpacing.lg),
              _buildActions(context),
            ] else if (_problem != null || _rawMode) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _buildProblemActions(context),
            ],
            const SizedBox(height: AppSpacing.xl),
            _buildSafetyCard(context),
            const SizedBox(height: AppSpacing.sm),
            CustomText.bodySmall(
              AppStrings.pantryNote,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Recipe? recipe = _recipe;
    return AppCard(
      radius: AppRadius.hero,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[colors.primaryContainer, colors.tertiaryContainer],
      ),
      child: Column(
        children: <Widget>[
          if (_loading) ...<Widget>[
            const _BobbingChef(emoji: '🧑‍🍳', size: 72),
            const SizedBox(height: AppSpacing.sm),
            CustomText.headlineSmall(
              _usingAi
                  ? AppStrings.writingRecipeTitle
                  : AppStrings.quickChefWriting,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            CustomText.bodyLarge(
              AppStrings.writingRecipeBody,
              textAlign: TextAlign.center,
            ),
            if (_plainRaw.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _buildLiveText(context),
            ],
          ] else if (recipe != null) ...<Widget>[
            AppEmoji(recipe.emoji, size: 64),
            const SizedBox(height: AppSpacing.sm),
            CustomText.headlineSmall(recipe.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                _FactChip(
                  icon: Icons.schedule,
                  text: '${recipe.minutes} ${AppStrings.minutesShort}',
                ),
                _FactChip(icon: Icons.speed, text: recipe.level),
              ],
            ),
          ] else ...<Widget>[
            const AppEmoji('📝', size: 56),
            const SizedBox(height: AppSpacing.sm),
            CustomText.headlineSmall(
              AppStrings.rawRecipeTitle,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveText(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      width: double.infinity,
      radius: AppRadius.large,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: colors.surface.withValues(alpha: 0.8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomText.labelLarge(AppStrings.liveRecipe),
          const SizedBox(height: AppSpacing.sm),
          CustomText.bodyMedium('${_plainRaw.trimLeft()} ▍'),
        ],
      ),
    );
  }

  Widget _buildRawCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      color: colors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomText.titleLarge(AppStrings.rawRecipeTitle),
          const SizedBox(height: AppSpacing.xs),
          CustomText.bodyMedium(AppStrings.rawRecipeBody),
          const SizedBox(height: AppSpacing.sm),
          AppSelectableText(_plainRaw, variant: AppTextVariant.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildIngredients(BuildContext context, Recipe recipe) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<String> foods = recipe.foods.isNotEmpty
        ? recipe.foods
        : _foodNames;
    return AppCard(
      color: colors.surfaceContainerHigh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CustomText.titleLarge(AppStrings.ingredientsLabel),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final String food in foods)
                Chip(
                  avatar: AppEmoji(_emojiForFood(food)),
                  label: CustomText(food),
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
        CustomText.titleLarge(AppStrings.stepsLabel),
        const SizedBox(height: AppSpacing.sm),
        if (recipe.steps.isEmpty)
          CustomText.bodyLarge(AppStrings.recipeNotFound)
        else
          for (int index = 0; index < recipe.steps.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    return AppCard(
      color: colors.secondaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppEmoji('💡', size: AppSizes.emojiMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CustomText.titleMedium(AppStrings.chefTip),
                const SizedBox(height: AppSpacing.xs),
                CustomText.bodyLarge(recipe.tip),
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
        label: const CustomText(AppStrings.stopChef),
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
        const SizedBox(height: AppSpacing.sm),
        if (!_usingAi) ...<Widget>[
          OutlinedButton.icon(
            onPressed: aiReady ? _retryAi : _getAiChef,
            icon: Icon(aiReady ? Icons.refresh : Icons.download),
            label: CustomText(
              aiReady ? AppStrings.tryAiAgain : AppStrings.getAiChef,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        OutlinedButton.icon(
          onPressed: _changeFoods,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const CustomText(AppStrings.changeFoods),
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
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _showQuickChef(),
          icon: const Icon(Icons.soup_kitchen_outlined),
          label: const CustomText(AppStrings.useQuickChefAction),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (!aiReady)
          OutlinedButton.icon(
            onPressed: _getAiChef,
            icon: const Icon(Icons.download),
            label: const CustomText(AppStrings.getAiChef),
          ),
        const SizedBox(height: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: _changeFoods,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const CustomText(AppStrings.changeFoods),
        ),
      ],
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppRadius.large,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: colors.errorContainer.withValues(alpha: 0.55),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppEmoji('🦺', size: AppSizes.emojiMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: CustomText.bodyMedium(AppStrings.safetyNote)),
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
      child: AppCard(
        radius: AppRadius.pill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: isAi ? colors.primaryContainer : colors.secondaryContainer,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppEmoji(isAi ? '🤖' : '⚡', size: AppSizes.emojiSmall),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: CustomText.labelLarge(
                isAi ? AppStrings.aiChef : AppStrings.quickChef,
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
    return AppCard(
      radius: AppRadius.pill,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: colors.surface.withValues(alpha: 0.55),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: AppSizes.iconSmall),
          const SizedBox(width: AppSpacing.xs),
          CustomText.labelLarge(text),
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
          child: CustomText.titleMedium('$number'),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: CustomText.bodyLarge(text),
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
    return AppCard(
      radius: AppRadius.large,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: colors.tertiaryContainer,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AppEmoji('🤖', size: AppSizes.emoji),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: CustomText.bodyMedium(text)),
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
    return AppCard(
      color: colors.surfaceContainerHigh,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppEmoji(emoji, size: AppSizes.emojiMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CustomText.titleMedium(title),
                const SizedBox(height: AppSpacing.xs),
                CustomText.bodyMedium(body),
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
        child: AppEmoji(emoji, size: size),
      ),
    );
  }
}
