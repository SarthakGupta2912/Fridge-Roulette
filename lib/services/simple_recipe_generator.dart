import 'dart:math';

import '../data/ingredients.dart';
import '../data/recipe.dart';

/// The friendly "Quick chef" who writes a recipe without any AI model.
///
/// It mixes a cooking method, a flavour and a serving idea, and it remembers
/// the last title so the child never sees the same name twice in a row.
class SimpleRecipeGenerator {
  SimpleRecipeGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;
  String? _lastTitle;

  static const List<String> _methods = <String>[
    'Sizzle',
    'Sunshine',
    'Magic',
    'Happy',
    'Tiny',
    'Rainbow',
    'Super',
    'Cozy',
  ];

  static const List<String> _flavours = <String>[
    'Snack',
    'Surprise',
    'Supper',
    'Bites',
    'Bowl',
    'Stack',
    'Party',
    'Munch',
  ];

  static const List<String> _servingIdeas = <String>[
    'Make a smiley face on the plate.',
    'Use three bright colours.',
    'Give it a funny name before you eat.',
    'Make a tiny mountain with the food.',
    'Count to five, then take the first bite.',
    'Make a rainbow pattern on the plate.',
  ];

  static const List<String> _tips = <String>[
    'Ask a grown-up to help with the hot pan.',
    'Wash your hands before you start.',
    'Taste with your eyes first. Does it look funny?',
    'A grown-up can help you cut big pieces.',
    'Clean up together when you finish.',
  ];

  /// Makes a quick, safe recipe from the foods the child has.
  Recipe makeRecipe(List<String> foods) {
    final List<String> cleaned = <String>[];
    for (final String food in foods) {
      final String name = food.trim();
      if (name.isNotEmpty &&
          !cleaned.any(
            (String other) => other.toLowerCase() == name.toLowerCase(),
          )) {
        cleaned.add(name);
      }
    }
    if (cleaned.isEmpty) {
      cleaned.add('surprise food');
    }
    cleaned.shuffle(_random);

    final String first = cleaned.first;
    final String second = cleaned.length > 1 ? cleaned[1] : first;
    final String pair = first == second ? first : '$first + $second';

    String title = _makeTitle(pair);
    if (title == _lastTitle) {
      final String method = _pick(_methods);
      title = '$method $pair ${_pick(_flavours)}';
    }
    if (title == _lastTitle) {
      title = '$title 2';
    }
    _lastTitle = title;

    final String serving = _pick(_servingIdeas);
    final String tip = _pick(_tips);
    final String emoji = _emojiFor(first);

    return Recipe(
      title: title,
      emoji: emoji,
      minutes: 10 + _random.nextInt(16),
      level: _random.nextBool() ? 'Easy' : 'Medium',
      steps: <String>[
        'Wash the $first${second == first ? '' : ' and $second'} well.',
        'Ask a grown-up to cut any big pieces and to turn on the stove or oven.',
        'Cook the food until it is hot all the way through. Meat, fish and eggs must be fully cooked.',
        'Add a tiny bit of salt, pepper or oil if the grown-up says it is okay.',
        serving,
      ],
      tip: tip,
      foods: cleaned.take(4).toList(),
      rawText: '',
      isAi: false,
    );
  }

  String _makeTitle(String pair) {
    final String method = _pick(_methods);
    final String flavour = _pick(_flavours);
    return '$method $pair $flavour';
  }

  String _pick(List<String> choices) {
    return choices[_random.nextInt(choices.length)];
  }

  String _emojiFor(String foodName) {
    final String wanted = foodName.toLowerCase();
    for (final Ingredient food in allIngredients) {
      if (food.name.toLowerCase() == wanted ||
          food.id.toLowerCase() == wanted) {
        return food.emoji;
      }
    }
    return '🍳';
  }
}
