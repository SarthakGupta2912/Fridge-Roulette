import 'dart:math';

import '../data/ingredients.dart';
import '../data/recipe.dart';
import '../data/recipes.dart';

/// Chooses a recipe that fits the foods we have.
/// It remembers the last 3 results so the wheel feels fresh.
class RecipePicker {
  RecipePicker({List<Recipe>? recipes, Random? random})
    : _recipes = recipes ?? allRecipes,
      _random = random ?? Random();

  final List<Recipe> _recipes;
  final Random _random;
  final List<String> _recentIds = [];

  /// Returns a recipe that uses only the available foods, or null if there
  /// are not enough foods for even a 2-food snack.
  Recipe? pickRecipe(List<String> availableFoodIds) {
    final Set<String> available = availableFoodIds.toSet();
    final List<Recipe> eligible = [];
    for (final Recipe recipe in _recipes) {
      if (recipe.requiredFoods.isEmpty) {
        continue;
      }
      bool hasEverything = true;
      for (final String foodId in recipe.requiredFoods) {
        if (!available.contains(foodId)) {
          hasEverything = false;
          break;
        }
      }
      if (hasEverything) {
        eligible.add(recipe);
      }
    }

    Recipe? choice = _pickWithoutRepeats(eligible);
    choice ??= _makeMixAndMatch(available);
    if (choice != null) {
      _remember(choice.id);
    }
    return choice;
  }

  /// Picks from the eligible recipes, avoiding the last 3 when possible.
  Recipe? _pickWithoutRepeats(List<Recipe> eligible) {
    if (eligible.isEmpty) {
      return null;
    }
    final List<Recipe> fresh = [];
    for (final Recipe recipe in eligible) {
      if (!_recentIds.contains(recipe.id)) {
        fresh.add(recipe);
      }
    }
    final List<Recipe> pool = fresh.isEmpty ? eligible : fresh;
    return pool[_random.nextInt(pool.length)];
  }

  void _remember(String recipeId) {
    _recentIds.add(recipeId);
    while (_recentIds.length > 3) {
      _recentIds.removeAt(0);
    }
  }

  /// Builds a simple snack from two safe foods when no recipe fits.
  Recipe? _makeMixAndMatch(Set<String> available) {
    final List<Ingredient> safeFoods = [];
    for (final String id in available) {
      final Ingredient? food = findIngredient(id);
      if (food != null && food.isSnackSafe) {
        safeFoods.add(food);
      }
    }
    if (safeFoods.length < 2) {
      return null;
    }

    safeFoods.shuffle(_random);
    final Ingredient first = safeFoods[0];
    final Ingredient second = safeFoods[1];
    final List<String> pair = [first.id, second.id]..sort();
    final String id = 'mix_${pair[0]}_${pair[1]}';

    return Recipe(
      id: id,
      name: '${first.name} + ${second.name} Snack',
      emoji: first.emoji,
      requiredFoods: [first.id, second.id],
      minutes: 3,
      difficulty: 1,
      twist: 'Make a funny face on your plate!',
      steps: [
        'Wash the food if it needs a wash.',
        'Ask a grown-up to cut big pieces.',
        'Put both foods on a plate.',
        'Make a funny pattern with them.',
        'Eat your snack with a big smile!',
      ],
      isMixAndMatch: true,
    );
  }
}
