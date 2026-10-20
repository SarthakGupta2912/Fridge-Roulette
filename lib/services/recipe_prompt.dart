import 'dart:math';

import '../data/recipe.dart';

/// One prompt plus the chef style and twist we chose for it.
class RecipePrompt {
  const RecipePrompt({
    required this.text,
    required this.chefStyle,
    required this.twist,
  });

  final String text;
  final String chefStyle;
  final String twist;
}

/// Builds the instructions sent to the small on-device language model.
///
/// This class does no AI work itself, so it is easy to test.
class RecipePromptBuilder {
  RecipePromptBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const List<String> chefStyles = <String>[
    'a silly pirate chef',
    'a tiny dinosaur chef',
    'a space chef from planet Snack',
    'a grandma chef with a big laugh',
    'a robot chef who loves beeps',
    'a jungle explorer chef',
    'a superhero chef with a cape',
  ];

  static const List<String> twists = <String>[
    'Make the food look like a smiley face.',
    'Use three bright colours on the plate.',
    'Give the dish a funny story before eating.',
    'Make the food into a funny shape on the plate.',
    'Serve it in tiny bites with a silly countdown.',
    'Give the dish a made-up superhero name.',
    'Make a rainbow pattern with the food.',
  ];

  /// Builds the fixed plain-text prompt.
  ///
  /// [recentTitles] holds up to the last three recipe names so the model can
  /// avoid writing the same idea again.
  RecipePrompt build({
    required List<String> foods,
    required List<String> recentTitles,
  }) {
    final String chefStyle = chefStyles[_random.nextInt(chefStyles.length)];
    final String twist = twists[_random.nextInt(twists.length)];
    final String foodList = _cleanFoods(foods).join(', ');
    final String avoid = recentTitles
        .map((String title) => title.trim())
        .where((String title) => title.isNotEmpty)
        .take(3)
        .join('; ');

    final StringBuffer prompt = StringBuffer()
      ..writeln('You are Chef Coco, a friendly recipe writer for children.')
      ..writeln('Write ONE very simple recipe.')
      ..writeln('Use ONLY these foods from the fridge: $foodList.')
      ..writeln(
        'You may also use ONLY these basics: salt, pepper, oil, water, sugar.',
      )
      ..writeln(
        'Do not add any other ingredient. Never invent pie crust, flour, '
        'butter, milk, cream, cheese, meat, fish, eggs, bread, rice or pasta '
        'unless it is in the fridge list.',
      )
      ..writeln(
        'If the fridge list has only fruit, make a cold fruit dish and do not '
        'use an oven or a stove.',
      )
      ..writeln(
        'The recipe must be kid-friendly. Never use alcohol. Never tell a '
        'child to eat raw meat, raw fish or raw eggs. Meat, fish and eggs must '
        'be cooked all the way through.',
      )
      ..writeln(
        'If a step needs a knife, a hot pan, an oven or a stove, tell the '
        'child to ask a grown-up first.',
      )
      ..writeln('Use exactly 4 short steps. One sentence per step.')
      ..writeln(
        'Use medium-high heat only when a grown-up is helping. Keep it safe '
        'and easy.',
      )
      ..writeln('Chef style: $chefStyle.')
      ..writeln('Fun twist: $twist')
      ..writeln('Do not repeat the same word twice in the title.');

    if (avoid.isNotEmpty) {
      prompt.writeln(
        'Do not repeat these recent recipe names or the same idea: $avoid.',
      );
    }

    prompt
      ..writeln('Write in plain text using EXACTLY this format:')
      ..writeln('TITLE: a short funny name')
      ..writeln('EMOJI: one food emoji')
      ..writeln('TIME: a number of minutes')
      ..writeln('LEVEL: Easy, Medium or Tricky')
      ..writeln('STEPS:')
      ..writeln('1. first step')
      ..writeln('2. second step')
      ..writeln('3. third step')
      ..writeln('4. fourth step')
      ..writeln('TIP: one fun and safe tip')
      ..writeln('Do not use JSON, Markdown, stars or extra headings.')
      ..writeln('Start now with TITLE:');

    return RecipePrompt(
      text: prompt.toString().trim(),
      chefStyle: chefStyle,
      twist: twist,
    );
  }

  List<String> _cleanFoods(List<String> foods) {
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
      return const <String>['a surprise food'];
    }
    return cleaned;
  }
}

/// Makes the model's words readable while it is still writing.
///
/// Small models sometimes send the two characters `\n` instead of a real line
/// break, or add HTML tags such as `<br>`. This turns those into plain text so
/// the child never sees escape codes or tags on screen.
///
/// Set [streaming] while tokens are still arriving. It hides a half-finished
/// tag at the very end, such as `<br` or `<|im_end`, instead of flashing it.
String plainRecipeText(String raw, {bool streaming = false}) {
  String text = raw
      // ChatML markers such as <|im_end|>.
      .replaceAll(RegExp(r'<\|[^>]*\|>'), '')
      // HTML line breaks and block tags become real line breaks.
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'<\s*/\s*(?:p|div|li|h[1-6]|tr)\s*>', caseSensitive: false),
        '\n',
      )
      .replaceAll(
        RegExp(r'<\s*(?:p|div|li|h[1-6]|tr)\b[^>]*>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]*>'), '')
      // Common HTML entities.
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      // Literal escape sequences. The regex allows the model to double them.
      .replaceAll(RegExp(r'\\+r\\+n'), '\n')
      .replaceAll(RegExp(r'\\+n'), '\n')
      .replaceAll(RegExp(r'\\+r'), '\n')
      .replaceAll(RegExp(r'\\+t'), ' ')
      // Very light Markdown cleanup.
      .replaceAll('**', '')
      .replaceAll('__', '')
      .replaceAll('`', '')
      .replaceAll(RegExp(r'^\s*#+\s*', multiLine: true), '');

  if (streaming) {
    // Do not show a tag or escape that is still arriving.
    text = text
        .replaceFirst(RegExp(r'<[/!?a-zA-Z|][^>]*$'), '')
        .replaceFirst(RegExp(r'&[a-zA-Z#0-9]*$'), '')
        .replaceFirst(RegExp(r'\\+$'), '');
  }

  text = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return streaming ? text.trimLeft() : text.trim();
}

/// Reads the model's plain text into a [Recipe].
///
/// The parser is deliberately forgiving: small models sometimes forget an
/// emoji, add stars, or write a step on the same line as STEPS. If the text
/// cannot be understood at all, this returns null and the screen shows the
/// chef's raw words instead.
Recipe? parseRecipeText(
  String raw, {
  bool isAi = false,
  List<String> foods = const <String>[],
}) {
  final String text = plainRecipeText(raw).replaceFirst(
    RegExp(r'^\s*(assistant|user|system)\s*:?\s*', caseSensitive: false),
    '',
  );
  if (text.isEmpty) {
    return null;
  }

  final List<String> lines = text.split('\n');
  String? title;
  String? emoji;
  String? tip;
  String? level;
  int? minutes;
  final List<String> steps = <String>[];
  bool inSteps = false;

  for (final String originalLine in lines) {
    final String line = originalLine.trim();
    if (line.isEmpty) {
      continue;
    }
    final String clean = line
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^#+\s*'), '')
        .trim();
    final String upper = clean.toUpperCase();

    if (_isLabel(upper, 'TITLE')) {
      title = _valueAfterLabel(clean);
      inSteps = false;
      continue;
    }
    if (_isLabel(upper, 'EMOJI')) {
      emoji = _valueAfterLabel(clean);
      continue;
    }
    if (_isLabel(upper, 'TIME')) {
      minutes = _firstNumber(_valueAfterLabel(clean));
      continue;
    }
    if (_isLabel(upper, 'LEVEL')) {
      level = _valueAfterLabel(clean);
      continue;
    }
    if (_isLabel(upper, 'TIP')) {
      tip = _valueAfterLabel(clean);
      inSteps = false;
      continue;
    }
    if (_isLabel(upper, 'STEPS')) {
      inSteps = true;
      final String inlineStep = _valueAfterLabel(clean);
      if (inlineStep.isNotEmpty) {
        steps.add(_cleanStep(inlineStep));
      }
      continue;
    }

    if (inSteps) {
      final String? step = _stepFromLine(clean);
      if (step != null && step.isNotEmpty) {
        steps.add(step);
      }
    }
  }

  // Some small models forget the STEPS label but still number the steps.
  if (steps.isEmpty) {
    for (final String line in lines) {
      final String? step = _stepFromLine(line);
      if (step != null && step.isNotEmpty) {
        steps.add(step);
      }
    }
  }

  // If there is no title, borrow the first useful line.
  if (title == null || title.trim().isEmpty) {
    for (final String line in lines) {
      final String clean = line
          .replaceAll('**', '')
          .replaceAll(RegExp(r'^#+\s*'), '')
          .trim();
      if (clean.isEmpty) {
        continue;
      }
      final String upper = clean.toUpperCase();
      if (_isAnyLabel(upper) || _stepFromLine(clean) != null) {
        continue;
      }
      title = clean;
      break;
    }
  }

  // Without at least one step this is not a recipe. The screen shows the
  // chef's raw words instead, so the child is never left with a blank card.
  if (steps.isEmpty) {
    return null;
  }

  final String chosenEmoji = _emojiFrom(emoji) ?? '🍳';
  final String chosenLevel = _levelFrom(level);

  return Recipe(
    title: _cleanTitle((title ?? 'Chef\'s Surprise').trim()),
    emoji: chosenEmoji,
    minutes: minutes != null && minutes > 0 && minutes <= 120 ? minutes : 15,
    level: chosenLevel,
    steps: steps.take(8).toList(),
    tip: (tip != null && tip.trim().isNotEmpty)
        ? tip.trim()
        : 'Ask a grown-up for help with knives and hot things.',
    foods: foods,
    rawText: text,
    isAi: isAi,
  );
}

/// Checks the AI text for common foods that were not detected in the fridge.
///
/// A small model can ignore the ingredient list and add pie crust, cream or
/// meat. In that case the screen should use the safe Quick chef recipe instead.
bool recipeUsesOnlyAllowedFoods(Recipe recipe, List<String> foods) {
  final String text = recipe.rawText.isNotEmpty
      ? recipe.rawText.toLowerCase()
      : <String>[
          recipe.title,
          ...recipe.steps,
          recipe.tip,
        ].join(' ').toLowerCase();
  final List<String> allowed = foods
      .map((String food) => food.trim().toLowerCase())
      .where((String food) => food.isNotEmpty)
      .toList();

  for (final String extra in _extraFoods) {
    final RegExp pattern = RegExp(
      r'\b' + RegExp.escape(extra) + r'\b',
      caseSensitive: false,
    );
    if (!pattern.hasMatch(text)) {
      continue;
    }
    final bool isAllowed = allowed.any(
      (String food) => food.contains(extra) || extra.contains(food),
    );
    if (!isAllowed) {
      return false;
    }
  }
  return true;
}

const List<String> _extraFoods = <String>[
  'pie crust',
  'crust',
  'flour',
  'butter',
  'milk',
  'cream',
  'cheese',
  'egg',
  'eggs',
  'chicken',
  'fish',
  'meat',
  'beef',
  'pork',
  'bacon',
  'bread',
  'rice',
  'pasta',
  'noodles',
  'oats',
  'chocolate',
  'honey',
  'vanilla',
  'baking powder',
  'baking soda',
  'yeast',
  'cake',
  'cookie',
  'ketchup',
  'mustard',
  'mayonnaise',
  'soy sauce',
  'stock',
  'broth',
];

String _cleanTitle(String value) {
  final String cleaned = value
      .replaceAll(r'\n', ' ')
      .replaceFirst(RegExp(r'^(?:title)\s*[:\-]\s*', caseSensitive: false), '')
      .trim();
  final List<String> words = cleaned.split(RegExp(r'\s+'));
  final List<String> kept = <String>[];
  for (final String word in words) {
    if (word.isEmpty) {
      continue;
    }
    if (kept.isEmpty || kept.last.toLowerCase() != word.toLowerCase()) {
      kept.add(word);
    }
  }
  return kept.isEmpty ? 'Chef\'s Surprise' : kept.join(' ');
}

bool _isAnyLabel(String upper) {
  return <String>[
    'TITLE',
    'EMOJI',
    'TIME',
    'LEVEL',
    'STEPS',
    'TIP',
  ].any((String label) => _isLabel(upper, label));
}

bool _isLabel(String upper, String label) {
  return upper.startsWith('$label:') ||
      upper.startsWith('$label -') ||
      upper.startsWith('$label –');
}

String _valueAfterLabel(String line) {
  final int colon = line.indexOf(':');
  if (colon >= 0) {
    return line.substring(colon + 1).trim();
  }
  final int dash = line.indexOf(RegExp(r'[-–]'));
  if (dash >= 0) {
    return line.substring(dash + 1).trim();
  }
  return '';
}

String? _stepFromLine(String line) {
  final String clean = line
      .replaceAll('**', '')
      .replaceAll(RegExp(r'^\s*#+\s*'), '')
      .trim();
  final RegExpMatch? match = RegExp(
    r'^(?:\d+[.)]|[-*•])\s*(.+)$',
  ).firstMatch(clean);
  if (match == null) {
    return null;
  }
  return _cleanStep(match.group(1) ?? '');
}

String _cleanStep(String step) {
  return step.replaceAll(RegExp(r'\s+'), ' ').trim();
}

int? _firstNumber(String value) {
  final RegExpMatch? match = RegExp(r'\d+').firstMatch(value);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(0)!);
}

String _levelFrom(String? value) {
  final String text = (value ?? '').toLowerCase();
  if (text.contains('tricky') || text.contains('hard')) {
    return 'Tricky';
  }
  if (text.contains('medium')) {
    return 'Medium';
  }
  return 'Easy';
}

String? _emojiFrom(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final RegExpMatch? match = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
    unicode: true,
  ).firstMatch(value);
  return match?.group(0);
}
