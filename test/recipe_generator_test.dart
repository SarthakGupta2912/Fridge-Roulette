import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_roulette/data/model_info.dart';
import 'package:fridge_roulette/data/recipe.dart';
import 'package:fridge_roulette/services/recipe_generator.dart';
import 'package:fridge_roulette/services/recipe_prompt.dart';
import 'package:fridge_roulette/services/simple_recipe_generator.dart';

const String goodModelText = '''
TITLE: Banana Apple Sunshine
EMOJI: 🍌
TIME: 12 minutes
LEVEL: Medium
STEPS:
1. Wash the banana and the apple.
2. Ask a grown-up to cut them into small pieces.
3. Put them in a bowl and mix them together.
4. Make a smiley face on top.
TIP: Eat it with a funny story.
''';

void main() {
  group('prompt builder', () {
    test('includes foods, basics, recent names and the fixed format', () {
      final RecipePromptBuilder builder = RecipePromptBuilder(
        random: Random(3),
      );
      final RecipePrompt prompt = builder.build(
        foods: <String>['Banana', 'Apple', 'banana'],
        recentTitles: <String>['Old One', 'Old Two', 'Old Three', 'Old Four'],
      );

      expect(prompt.text, contains('Banana, Apple'));
      expect(prompt.text, contains('salt, pepper, oil, water, sugar'));
      expect(prompt.text, contains('Old One; Old Two; Old Three'));
      expect(prompt.text, isNot(contains('Old Four')));
      expect(prompt.text, contains('TITLE:'));
      expect(prompt.text, contains('EMOJI:'));
      expect(prompt.text, contains('TIME:'));
      expect(prompt.text, contains('LEVEL:'));
      expect(prompt.text, contains('STEPS:'));
      expect(prompt.text, contains('TIP:'));
      expect(prompt.text, contains('Never use alcohol'));
      expect(prompt.text, contains('raw meat'));
      expect(prompt.text, contains('ask a grown-up'));
      expect(RecipePromptBuilder.chefStyles, contains(prompt.chefStyle));
      expect(RecipePromptBuilder.twists, contains(prompt.twist));
    });

    test('falls back to a surprise food when the list is empty', () {
      final RecipePrompt prompt = RecipePromptBuilder(
        random: Random(1),
      ).build(foods: <String>['  '], recentTitles: <String>[]);
      expect(prompt.text, contains('a surprise food'));
    });
  });

  group('recipe parser', () {
    test('reads a well-formed recipe', () {
      final Recipe? recipe = parseRecipeText(
        goodModelText,
        isAi: true,
        foods: <String>['Banana', 'Apple'],
      );

      expect(recipe, isNotNull);
      expect(recipe!.title, 'Banana Apple Sunshine');
      expect(recipe.emoji, '🍌');
      expect(recipe.minutes, 12);
      expect(recipe.level, 'Medium');
      expect(recipe.steps, hasLength(4));
      expect(recipe.steps.first, contains('Wash the banana'));
      expect(recipe.tip, 'Eat it with a funny story.');
      expect(recipe.foods, <String>['Banana', 'Apple']);
      expect(recipe.isAi, isTrue);
    });

    test('is forgiving about stars, lowercase and missing emoji', () {
      const String messy = '''
**title:** Funny Toast
**time:** 8 minutes
**level:** tricky
**steps:**
1) Ask a grown-up for help.
2) Put the food on a plate.
3) Make a funny shape.
**tip:** Have fun!
''';
      final Recipe? recipe = parseRecipeText(messy);

      expect(recipe, isNotNull);
      expect(recipe!.title, 'Funny Toast');
      expect(recipe.emoji, '🍳');
      expect(recipe.minutes, 8);
      expect(recipe.level, 'Tricky');
      expect(recipe.steps, hasLength(3));
      expect(recipe.tip, 'Have fun!');
    });

    test('returns null when there are no numbered steps', () {
      expect(parseRecipeText('The chef wrote a little poem.'), isNull);
      expect(parseRecipeText(''), isNull);
    });

    test('reads literal slash-n line breaks and a Title prefix', () {
      const String text =
          r'\nTitle: The Simple Banana Apple Slice\nEMOJI: 🍌\nTIME: 2\n'
          r'LEVEL: Easy\nSTEPS:\n1. Peel the banana.\n2. Slice the apple.\n'
          r'3. Mix them.\n4. Serve cold.\nTIP: Yum!';
      final Recipe? recipe = parseRecipeText(
        text,
        foods: <String>['Banana', 'Apple'],
      );

      expect(recipe, isNotNull);
      expect(recipe!.title, 'The Simple Banana Apple Slice');
      expect(recipe.steps, hasLength(4));
    });

    test('cleans a repeated word in the title and flags invented food', () {
      const String text = '''
TITLE: Rainbow Rainbow Apple Pie
EMOJI: 🥧
TIME: 20
LEVEL: Easy
STEPS:
1. Put the pie crust in a dish.
2. Add the apple.
3. Top with whipped cream.
4. Ask a grown-up to bake it.
TIP: Yum!
''';
      final Recipe? recipe = parseRecipeText(
        text,
        foods: <String>['Banana', 'Apple'],
      );

      expect(recipe, isNotNull);
      expect(recipe!.title, 'Rainbow Apple Pie');
      expect(
        recipeUsesOnlyAllowedFoods(recipe, <String>['Banana', 'Apple']),
        isFalse,
      );
    });

    test('allows an extra food when it was detected in the fridge', () {
      final Recipe? recipe = parseRecipeText(
        goodModelText.replaceFirst('Wash the banana', 'Melt the butter'),
        foods: <String>['Banana', 'Apple', 'Butter'],
      );

      expect(recipe, isNotNull);
      expect(
        recipeUsesOnlyAllowedFoods(recipe!, <String>[
          'Banana',
          'Apple',
          'Butter',
        ]),
        isTrue,
      );
    });

    test('number steps even when the STEPS label is missing', () {
      const String text = '''
TITLE: Quick Bowl
EMOJI: 🥣
TIME: 9
LEVEL: Easy
1. Wash the food.
2. Ask a grown-up to mix it.
3. Serve it with a smile.
TIP: Yum!
''';
      final Recipe? recipe = parseRecipeText(text);
      expect(recipe, isNotNull);
      expect(recipe!.steps, hasLength(3));
      expect(recipe.title, 'Quick Bowl');
    });
  });

  group('quick chef', () {
    test('uses the child foods and always changes the title', () {
      final SimpleRecipeGenerator chef = SimpleRecipeGenerator(
        random: Random(5),
      );
      String? previous;
      for (int i = 0; i < 40; i++) {
        final Recipe recipe = chef.makeRecipe(<String>['Banana', 'Apple']);
        expect(recipe.title, isNot(previous));
        expect(recipe.isAi, isFalse);
        expect(recipe.steps, isNotEmpty);
        expect(
          recipe.steps.any((String step) => step.contains('grown-up')),
          isTrue,
        );
        previous = recipe.title;
      }
    });

    test('keeps the detected foods in the recipe', () {
      final Recipe recipe = SimpleRecipeGenerator(
        random: Random(2),
      ).makeRecipe(<String>['Carrot', 'Potato']);
      expect(recipe.foods, containsAll(<String>['Carrot', 'Potato']));
    });
  });

  group('generator helpers', () {
    test('quick recipe works without starting the AI engine', () {
      final RecipeGenerator generator = RecipeGenerator(random: Random(1));
      final Recipe recipe = generator.makeQuickRecipe(<String>['Banana']);
      expect(recipe.title, isNotEmpty);
      expect(recipe.steps, isNotEmpty);
      expect(generator.recentTitles, isEmpty);
    });
  });

  group('model info', () {
    test('records a small mobile model with a commercial-use license', () {
      expect(ModelInfo.sizeBytes, greaterThan(300 * 1024 * 1024));
      expect(ModelInfo.sizeBytes, lessThan(1024 * 1024 * 1024));
      expect(ModelInfo.downloadUrl, endsWith(ModelInfo.fileName));
      expect(ModelInfo.downloadUrl, startsWith('https://'));
      expect(ModelInfo.licenseUrl, startsWith('https://'));
      expect(ModelInfo.licenseName, contains('Apache'));
      expect(ModelInfo.sizeLabel, contains('MB'));
    });
  });
}
