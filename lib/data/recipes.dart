import 'recipe.dart';
import 'recipes_a.dart';
import 'recipes_b.dart';
import 'recipes_c.dart';

/// Every recipe in the app. There are 70 in total.
const List<Recipe> allRecipes = [...recipesA, ...recipesB, ...recipesC];

/// Basics we always pretend are in the kitchen.
const List<String> pantryBasics = ['salt', 'pepper', 'oil', 'water', 'sugar'];

/// Finds a recipe by its id.
Recipe? findRecipe(String id) {
  for (final Recipe recipe in allRecipes) {
    if (recipe.id == id) {
      return recipe;
    }
  }
  return null;
}
