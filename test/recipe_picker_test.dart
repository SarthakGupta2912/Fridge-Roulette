import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_roulette/data/ingredients.dart';
import 'package:fridge_roulette/data/recipe.dart';
import 'package:fridge_roulette/data/recipes.dart';
import 'package:fridge_roulette/services/recipe_picker.dart';

Recipe makeRecipe(String id, List<String> foods) {
  return Recipe(
    id: id,
    name: 'Recipe $id',
    emoji: '🍳',
    requiredFoods: foods,
    minutes: 5,
    difficulty: 1,
    twist: 'Have fun!',
    steps: const ['One', 'Two', 'Three', 'Four'],
  );
}

void main() {
  group('recipe data', () {
    test('has at least 60 recipes', () {
      expect(allRecipes.length, greaterThanOrEqualTo(60));
    });

    test('ids are unique and ingredients exist', () {
      final Set<String> ids = {};
      for (final Recipe recipe in allRecipes) {
        expect(ids.add(recipe.id), isTrue, reason: 'Duplicate id ${recipe.id}');
        expect(recipe.steps.length, inInclusiveRange(4, 7));
        expect(recipe.difficulty, inInclusiveRange(1, 3));
        expect(recipe.minutes, greaterThan(0));
        for (final String foodId in [
          ...recipe.requiredFoods,
          ...recipe.optionalFoods,
        ]) {
          expect(
            findIngredient(foodId),
            isNotNull,
            reason: '${recipe.id} uses unknown food $foodId',
          );
          expect(pantryBasics, isNot(contains(foodId)));
        }
      }
    });
  });

  group('eligibility', () {
    test('needs every required food', () {
      final RecipePicker picker = RecipePicker(
        recipes: [
          makeRecipe('toast', ['bread', 'cheese']),
        ],
        random: Random(1),
      );
      expect(picker.pickRecipe(['bread', 'cheese', 'tomato']), isNotNull);
    });

    test('says no when one food is missing', () {
      final RecipePicker picker = RecipePicker(
        recipes: [
          makeRecipe('toast', ['bread', 'cheese']),
        ],
        random: Random(1),
      );
      final Recipe? recipe = picker.pickRecipe(['bread', 'chicken']);
      // Mix and match can still make a snack, but never the toast recipe.
      expect(recipe?.id, isNot('toast'));
    });
  });

  group('no repeats', () {
    test('does not repeat the last 3 picks when other choices exist', () {
      final List<Recipe> recipes = [
        makeRecipe('a', ['apple']),
        makeRecipe('b', ['apple']),
        makeRecipe('c', ['apple']),
        makeRecipe('d', ['apple']),
        makeRecipe('e', ['apple']),
      ];
      final RecipePicker picker = RecipePicker(
        recipes: recipes,
        random: Random(7),
      );
      final List<String> picks = [];
      for (int i = 0; i < 12; i++) {
        final Recipe? recipe = picker.pickRecipe(['apple']);
        expect(recipe, isNotNull);
        if (picks.length >= 3) {
          final List<String> lastThree = picks.sublist(picks.length - 3);
          expect(lastThree, isNot(contains(recipe!.id)));
        }
        picks.add(recipe!.id);
      }
    });
  });

  group('mix and match fallback', () {
    test('makes a snack from two safe foods when no recipe fits', () {
      final RecipePicker picker = RecipePicker(
        recipes: const [],
        random: Random(3),
      );
      final Recipe? recipe = picker.pickRecipe(['apple', 'banana']);
      expect(recipe, isNotNull);
      expect(recipe!.isMixAndMatch, isTrue);
      expect(recipe.requiredFoods.toSet(), {'apple', 'banana'});
      expect(recipe.requiredFoods.length, 2);
    });

    test('only uses foods that are available', () {
      final RecipePicker picker = RecipePicker(
        recipes: const [],
        random: Random(4),
      );
      final Recipe? recipe = picker.pickRecipe([
        'apple',
        'banana',
        'strawberry',
        'yogurt',
      ]);
      expect(recipe, isNotNull);
      for (final String id in recipe!.requiredFoods) {
        expect(['apple', 'banana', 'strawberry', 'yogurt'], contains(id));
      }
    });

    test('returns null with one food', () {
      final RecipePicker picker = RecipePicker(
        recipes: const [],
        random: Random(5),
      );
      expect(picker.pickRecipe(['apple']), isNull);
    });

    test('returns null when the foods need cooking', () {
      final RecipePicker picker = RecipePicker(
        recipes: const [],
        random: Random(6),
      );
      expect(picker.pickRecipe(['chicken', 'fish']), isNull);
    });
  });

  test('picked recipes only use foods we have', () {
    final RecipePicker picker = RecipePicker(random: Random(9));
    final List<String> foods = [
      'bread',
      'cheese',
      'tomato',
      'lettuce',
      'banana',
      'yogurt',
    ];
    final Recipe? recipe = picker.pickRecipe(foods);
    expect(recipe, isNotNull);
    for (final String id in recipe!.requiredFoods) {
      expect(foods, contains(id));
    }
  });
}
