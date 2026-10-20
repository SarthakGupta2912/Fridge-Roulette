/// One recipe challenge the child can cook.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.requiredFoods,
    this.optionalFoods = const [],
    required this.minutes,
    required this.difficulty,
    required this.twist,
    required this.steps,
    this.isMixAndMatch = false,
  });

  final String id;
  final String name;
  final String emoji;

  /// Foods that must be in the fridge. Empty means a mix-and-match idea.
  final List<String> requiredFoods;

  /// Nice extras. The child does not need these.
  final List<String> optionalFoods;

  final int minutes;

  /// 1 is easy, 2 is medium, 3 is a bigger challenge.
  final int difficulty;

  final String twist;
  final List<String> steps;

  /// True for a simple snack the app makes up from two safe foods.
  final bool isMixAndMatch;
}
