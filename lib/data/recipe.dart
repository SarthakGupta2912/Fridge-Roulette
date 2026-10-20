/// One recipe written by the AI chef or the quick chef.
class Recipe {
  const Recipe({
    required this.title,
    required this.emoji,
    required this.minutes,
    required this.level,
    required this.steps,
    required this.tip,
    this.foods = const <String>[],
    this.rawText = '',
    this.isAi = false,
  });

  final String title;
  final String emoji;
  final int minutes;

  /// Easy, Medium or Tricky.
  final String level;

  final List<String> steps;
  final String tip;

  /// The foods the child had in the fridge.
  final List<String> foods;

  /// The model's original words. Kept so we can show them if parsing fails.
  final String rawText;

  /// True when this came from the on-device language model.
  final bool isAi;

  /// A friendly alias used by older widgets.
  String get name => title;
}
