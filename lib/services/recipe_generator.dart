import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';

import '../data/model_info.dart';
import '../data/recipe.dart';
import 'recipe_prompt.dart';
import 'simple_recipe_generator.dart';

/// Writes recipes with the small on-device language model.
///
/// The model is loaded only when a recipe is needed. It is closed again when
/// the child leaves the recipe screen or the app goes to the background.
class RecipeGenerator {
  RecipeGenerator({
    Random? random,
    RecipePromptBuilder? promptBuilder,
    SimpleRecipeGenerator? quickChef,
    this.readyCheck,
  }) : _random = random ?? Random(),
       _promptBuilder = promptBuilder ?? RecipePromptBuilder(random: random),
       _quickChef = quickChef ?? SimpleRecipeGenerator(random: random);

  final Random _random;
  final RecipePromptBuilder _promptBuilder;
  final SimpleRecipeGenerator _quickChef;
  final Future<bool> Function()? readyCheck;

  final List<String> _recentTitles = <String>[];
  InferenceModel? _model;
  InferenceModelSession? _session;
  bool _generating = false;

  static const Duration generationTimeout = Duration(seconds: 60);

  bool get isGenerating => _generating;
  List<String> get recentTitles => List<String>.unmodifiable(_recentTitles);

  /// True when the model has already been downloaded.
  Future<bool> isAiReady() async {
    final Future<bool> Function()? check = readyCheck;
    if (check != null) {
      return check();
    }
    try {
      return await FlutterEdgeAi.isModelInstalled(ModelInfo.fileName);
    } catch (error) {
      debugPrint('Could not check for the AI chef: $error');
      return false;
    }
  }

  /// A no-AI recipe for the Quick chef screen.
  Recipe makeQuickRecipe(List<String> foods) {
    return _quickChef.makeRecipe(foods);
  }

  /// Streams the recipe as the model writes it.
  ///
  /// The caller may cancel the subscription or call [stop] at any time.
  Stream<String> makeRecipe(List<String> foods) async* {
    if (_generating) {
      throw StateError('The chef is already writing a recipe.');
    }
    _generating = true;
    InferenceModelSession? session;
    final StringBuffer written = StringBuffer();

    try {
      final RecipePrompt prompt = _promptBuilder.build(
        foods: foods,
        recentTitles: _recentTitles,
      );
      final InferenceModel model = await _loadModel();
      session = await model.createSession(
        temperature: 0.85,
        topK: 40,
        topP: 0.95,
        randomSeed: _random.nextInt(1 << 31),
        systemInstruction:
            'You are Chef Coco, a kind chef for children. Follow the format '
            'exactly. Write plain text only.',
      );
      _session = session;
      await session.addQueryChunk(Message(text: prompt.text, isUser: true));

      int tokens = 0;
      await for (final String token in session.getResponseAsync().timeout(
        generationTimeout,
      )) {
        written.write(token);
        tokens++;
        yield token;
        if (tokens >= 340) {
          await session.stopGeneration();
          break;
        }
      }

      final Recipe? recipe = parseRecipeText(written.toString(), isAi: true);
      if (recipe != null) {
        _remember(recipe.title);
      }
    } on TimeoutException {
      await _stopSession();
      rethrow;
    } finally {
      _session = null;
      try {
        await session?.close();
      } catch (error) {
        debugPrint('Could not close the chef session: $error');
      }
      _generating = false;
    }
  }

  /// Stops the model as soon as the child taps Stop.
  Future<void> stop() async {
    await _stopSession();
  }

  /// Closes the model and gives its memory back to the phone.
  Future<void> release() async {
    await _stopSession();
    final InferenceModel? model = _model;
    _model = null;
    if (model == null) {
      return;
    }
    try {
      await model.close();
    } catch (error) {
      debugPrint('Could not close the AI chef: $error');
    }
  }

  Future<void> _stopSession() async {
    final InferenceModelSession? session = _session;
    _session = null;
    if (session == null) {
      return;
    }
    try {
      await session.stopGeneration();
    } catch (error) {
      debugPrint('Could not stop the chef: $error');
    }
  }

  Future<InferenceModel> _loadModel() async {
    final InferenceModel? loaded = _model;
    if (loaded != null) {
      return loaded;
    }

    InferenceModel model;
    try {
      model = await FlutterEdgeAi.getActiveModel(
        maxTokens: 1280,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (error) {
      debugPrint('GPU chef did not wake up, trying the CPU: $error');
      model = await FlutterEdgeAi.getActiveModel(
        maxTokens: 1280,
        preferredBackend: PreferredBackend.cpu,
      );
    }
    _model = model;
    return model;
  }

  void _remember(String title) {
    _recentTitles.add(title);
    while (_recentTitles.length > 3) {
      _recentTitles.removeAt(0);
    }
  }
}
