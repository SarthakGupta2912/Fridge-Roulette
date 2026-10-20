import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../data/ingredients.dart';

/// One food read from a package label.
class LabelFood {
  const LabelFood({required this.food, this.box});

  final Ingredient food;

  /// The label's box from 0.0 to 1.0, so we can draw it on the photo.
  final Rect? box;
}

/// Reads words on packages with ML Kit's on-device text recognizer.
///
/// A fridge is full of cartons, jars and bags. The tiny YOLO models are good at
/// fruit and vegetables, but a label such as "Philadelphia" or "Milk" is often
/// the best clue for packaged food. Nothing leaves the phone.
class LabelReader {
  TextRecognizer? _recognizer;
  bool _disposed = false;

  /// Reads the labels in one photo. [photoSize] is the photo's pixel size.
  Future<List<LabelFood>> readLabels(
    Uint8List imageBytes,
    Size photoSize,
  ) async {
    if (_disposed) {
      return const <LabelFood>[];
    }

    final TextRecognizer recognizer = _recognizer ??= TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    // ML Kit's Flutter plugin takes a file path. The app cache is private.
    final File tempFile = File(
      '${Directory.systemTemp.path}/fridge_label_'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    try {
      await tempFile.writeAsBytes(imageBytes, flush: true);
      final RecognizedText recognized = await recognizer.processImage(
        InputImage.fromFilePath(tempFile.path),
      );

      final List<LabelFood> foods = <LabelFood>[];
      for (final TextBlock block in recognized.blocks) {
        final List<Ingredient> blockFoods = _foodsInText(block.text);
        if (blockFoods.isEmpty) {
          continue;
        }
        final Rect? box = _normalizeBox(block.boundingBox, photoSize);
        for (final Ingredient food in blockFoods) {
          foods.add(LabelFood(food: food, box: box));
        }
      }
      return foods;
    } finally {
      try {
        await tempFile.delete();
      } catch (_) {
        // A leftover cache file is harmless.
      }
    }
  }

  /// Stops the recognizer when the app closes.
  void dispose() {
    _disposed = true;
    final TextRecognizer? recognizer = _recognizer;
    _recognizer = null;
    if (recognizer != null) {
      unawaited(recognizer.close());
    }
  }

  /// Returns every food named in one block of text.
  List<Ingredient> _foodsInText(String text) => foodsFromLabelText(text);

  Rect? _normalizeBox(Rect? box, Size photoSize) {
    if (box == null || photoSize.width <= 0 || photoSize.height <= 0) {
      return null;
    }
    final double left = (box.left / photoSize.width).clamp(0.0, 1.0);
    final double top = (box.top / photoSize.height).clamp(0.0, 1.0);
    final double right = (box.right / photoSize.width).clamp(0.0, 1.0);
    final double bottom = (box.bottom / photoSize.height).clamp(0.0, 1.0);
    if (right <= left || bottom <= top) {
      return null;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

/// Turns one block of package text into foods. Public so it can be tested
/// without the Android text recognizer.
List<Ingredient> foodsFromLabelText(String text) {
  final List<String> words = _words(text);
  if (words.isEmpty) {
    return const <Ingredient>[];
  }

  final Set<String> ids = <String>{};
  for (final _LabelRule rule in _rules) {
    if (_consume(words, rule.words)) {
      ids.add(rule.foodId);
    }
    if (ids.length >= 6) {
      break;
    }
  }

  final List<Ingredient> foods = <Ingredient>[];
  for (final String id in ids) {
    final Ingredient? food = findIngredient(id);
    if (food != null) {
      foods.add(food);
    }
  }
  return foods;
}

/// Finds a phrase made of whole words, then hides those words so a shorter
/// word inside it cannot match again. For example, "peanut butter" should not
/// also add "peanut" and "butter".
bool _consume(List<String> words, List<String> phrase) {
  if (phrase.isEmpty || phrase.length > words.length) {
    return false;
  }
  for (int start = 0; start <= words.length - phrase.length; start++) {
    bool matches = true;
    for (int offset = 0; offset < phrase.length; offset++) {
      if (words[start + offset] != phrase[offset]) {
        matches = false;
        break;
      }
    }
    if (!matches) {
      continue;
    }
    for (int offset = 0; offset < phrase.length; offset++) {
      words[start + offset] = '__';
    }
    return true;
  }
  return false;
}

List<String> _words(String text) {
  final String clean = text
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9àâäçéèêëîïôöùûüÿñœæ]+"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (clean.isEmpty) {
    return const <String>[];
  }
  return clean.split(' ');
}

class _LabelRule {
  const _LabelRule(this.words, this.foodId);

  final List<String> words;
  final String foodId;
}

/// Longest phrases first, so "peanut butter" wins before "butter".
final List<_LabelRule> _rules = _buildRules();

List<_LabelRule> _buildRules() {
  final List<_LabelRule> rules = <_LabelRule>[];
  for (final MapEntry<String, String> entry in _labelWords.entries) {
    final List<String> words = entry.key
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9àâäçéèêëîïôöùûüÿñœæ]+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ');
    if (words.isEmpty || words.first.isEmpty) {
      continue;
    }
    rules.add(_LabelRule(words, entry.value));
  }
  rules.sort((_LabelRule a, _LabelRule b) {
    final int length = b.words.length.compareTo(a.words.length);
    if (length != 0) {
      return length;
    }
    return b.words.join(' ').length.compareTo(a.words.join(' ').length);
  });
  return rules;
}

/// Words and brands we can turn into a food. Keep this list specific: a word
/// like "date" is skipped because it also appears in "best before date".
const Map<String, String> _labelWords = <String, String>{
  // Brands that are common in Canadian fridges.
  'philadelphia': 'cheese',
  'lactantia': 'milk',
  'natrel': 'milk',
  'silk': 'milk',
  'tropicana': 'drink',
  'yoplait': 'yogurt',
  'danone': 'yogurt',
  'activia': 'yogurt',
  'oikos': 'yogurt',
  'black diamond': 'cheese',
  'cracker barrel': 'cheese',
  'becel': 'butter',
  'imperial': 'butter',
  'hellmann': 'mayo',
  'miracle whip': 'mayo',
  'heinz': 'ketchup',
  'french s': 'mustard',
  'smucker': 'jam',
  'nutella': 'chocolate',
  'jif': 'peanut_butter',
  'skippy': 'peanut_butter',
  'quaker': 'oats',
  'oreo': 'biscuit',
  'chips ahoy': 'biscuit',
  'christie': 'biscuit',
  'dare': 'biscuit',
  'tostitos': 'chips',
  'lay s': 'chips',
  'doritos': 'chips',
  'pringles': 'chips',
  'kellogg': 'cereal',
  'campbell': 'soup',
  'uncle ben': 'rice',
  'barilla': 'pasta',
  'catelli': 'pasta',
  'classico': 'sauce',
  'prego': 'sauce',
  'ragu': 'sauce',

  // Dairy and eggs.
  'milk': 'milk',
  'buttermilk': 'milk',
  'soy milk': 'milk',
  'almond milk': 'milk',
  'oat milk': 'milk',
  'coconut milk': 'milk',
  'cream cheese': 'cheese',
  'cottage cheese': 'cheese',
  'mozzarella': 'cheese',
  'cheddar': 'cheese',
  'parmesan': 'cheese',
  'feta': 'cheese',
  'brie': 'cheese',
  'gouda': 'cheese',
  'cheese': 'cheese',
  'butter': 'butter',
  'margarine': 'butter',
  'egg': 'eggs',
  'eggs': 'eggs',
  'egg whites': 'eggs',
  'yogurt': 'yogurt',
  'yoghurt': 'yogurt',
  'sour cream': 'yogurt',

  // Bakery, meat and fish.
  'bread': 'bread',
  'bagel': 'bread',
  'tortilla': 'bread',
  'pita': 'bread',
  'naan': 'bread',
  'croissant': 'bread',
  'muffin': 'bread',
  'baguette': 'bread',
  'bun': 'bread',
  'breadcrumbs': 'bread',
  'chicken': 'chicken',
  'turkey': 'chicken',
  'beef': 'meat',
  'steak': 'meat',
  'pork': 'meat',
  'bacon': 'meat',
  'ham': 'meat',
  'lamb': 'meat',
  'meat': 'meat',
  'sausage': 'sausage',
  'hot dog': 'hot_dog',
  'fish': 'fish',
  'salmon': 'fish',
  'tuna': 'fish',
  'trout': 'fish',
  'shrimp': 'shrimp',
  'prawn': 'shrimp',
  'crab': 'seafood',
  'lobster': 'seafood',
  'seafood': 'seafood',
  'tofu': 'tofu',
  'tempeh': 'tofu',

  // Staples, vegetables and fruit.
  'rice': 'rice',
  'pasta': 'pasta',
  'spaghetti': 'pasta',
  'macaroni': 'pasta',
  'noodle': 'noodles',
  'noodles': 'noodles',
  'soup': 'soup',
  'broth': 'soup',
  'beans': 'beans',
  'chickpeas': 'beans',
  'lentils': 'beans',
  'peas': 'peas',
  'corn': 'corn',
  'tomato': 'tomato',
  'tomatoes': 'tomato',
  'ketchup': 'ketchup',
  'salsa': 'sauce',
  'sauce': 'sauce',
  'mayonnaise': 'mayo',
  'mayo': 'mayo',
  'mustard': 'mustard',
  'jam': 'jam',
  'jelly': 'jam',
  'honey': 'honey',
  'peanut butter': 'peanut_butter',
  'almond butter': 'nuts',
  'potato': 'potato',
  'sweet potato': 'potato',
  'onion': 'onion',
  'garlic': 'garlic',
  'ginger': 'ginger',
  'carrot': 'carrot',
  'broccoli': 'broccoli',
  'cauliflower': 'cauliflower',
  'cucumber': 'cucumber',
  'lettuce': 'lettuce',
  'spinach': 'spinach',
  'kale': 'spinach',
  'cabbage': 'cabbage',
  'bell pepper': 'bell_pepper',
  'red pepper': 'bell_pepper',
  'green pepper': 'bell_pepper',
  'yellow pepper': 'bell_pepper',
  'mushroom': 'mushroom',
  'avocado': 'avocado',
  'celery': 'celery',
  'radish': 'radish',
  'pumpkin': 'pumpkin',
  'eggplant': 'eggplant',
  'okra': 'okra',
  'asparagus': 'asparagus',
  'parsley': 'herbs',
  'cilantro': 'herbs',
  'basil': 'herbs',
  'mint': 'herbs',
  'apple': 'apple',
  'banana': 'banana',
  'orange': 'orange',
  'lemon': 'lemon',
  'lime': 'lemon',
  'strawberry': 'strawberry',
  'blueberry': 'blueberries',
  'raspberry': 'raspberries',
  'cherry': 'cherries',
  'grape': 'grapes',
  'mango': 'mango',
  'pineapple': 'pineapple',
  'peach': 'peach',
  'pear': 'pear',
  'kiwi': 'kiwi',
  'melon': 'melon',
  'watermelon': 'watermelon',
  'apricot': 'apricot',
  'fig': 'figs',
  'dates': 'dates',
  'olives': 'olives',
  'pickles': 'pickles',

  // Snacks, drinks and extras.
  'chocolate': 'chocolate',
  'candy': 'candy',
  'cookie': 'biscuit',
  'cookies': 'biscuit',
  'biscuit': 'biscuit',
  'cracker': 'biscuit',
  'crackers': 'biscuit',
  'popcorn': 'popcorn',
  'potato chips': 'chips',
  'tortilla chips': 'chips',
  'chips': 'chips',
  'sweet potato fries': 'fries',
  'fries': 'fries',
  'ice cream': 'ice_cream',
  'pudding': 'pudding',
  'pie': 'pie',
  'cake': 'cake',
  'donut': 'donut',
  'dumplings': 'dumplings',
  'pizza': 'pizza',
  'burger': 'burger',
  'hamburger': 'burger',
  'sandwich': 'sandwich',
  'salad': 'salad',
  'cereal': 'cereal',
  'oatmeal': 'oats',
  'granola': 'oats',
  'flour': 'flour',
  'almond': 'nuts',
  'cashew': 'nuts',
  'walnut': 'nuts',
  'peanut': 'nuts',
  'pecan': 'nuts',
  'pistachio': 'nuts',
  'dried cranberries': 'dried_fruit',
  'dried fruit': 'dried_fruit',
  'juice': 'drink',
  'juices': 'drink',
  'smoothie': 'drink',
  'milkshake': 'drink',
  'lemonade': 'drink',
  'soda': 'drink',

  // Common plural forms on packages.
  'apples': 'apple',
  'bananas': 'banana',
  'oranges': 'orange',
  'lemons': 'lemon',
  'strawberries': 'strawberry',
  'grapes': 'grapes',
  'carrots': 'carrot',
  'potatoes': 'potato',
  'onions': 'onion',
  'mushrooms': 'mushroom',
  'cucumbers': 'cucumber',
  'sausages': 'sausage',
  'burgers': 'burger',
  'sandwiches': 'sandwich',
  'pizzas': 'pizza',
  'salads': 'salad',
  'cakes': 'cake',
  'pies': 'pie',
  'puddings': 'pudding',
  'donuts': 'donut',
  'candies': 'candy',
  'cereals': 'cereal',
  'soups': 'soup',
  'sauces': 'sauce',
  'nuts': 'nuts',
  'almonds': 'nuts',
  'cashews': 'nuts',
  'walnuts': 'nuts',
  'peanuts': 'nuts',

  // French labels, common in Canada.
  'lait': 'milk',
  'fromage': 'cheese',
  'beurre': 'butter',
  'oeuf': 'eggs',
  'oeufs': 'eggs',
  'œuf': 'eggs',
  'œufs': 'eggs',
  'yaourt': 'yogurt',
  'yogourt': 'yogurt',
  'pain': 'bread',
  'poulet': 'chicken',
  'boeuf': 'meat',
  'bœuf': 'meat',
  'porc': 'meat',
  'poisson': 'fish',
  'crevette': 'shrimp',
  'crevettes': 'shrimp',
  'riz': 'rice',
  'pates': 'pasta',
  'pâtes': 'pasta',
  'soupe': 'soup',
  'pommes de terre': 'potato',
  'pomme de terre': 'potato',
  'pommes': 'apple',
  'pomme': 'apple',
  'banane': 'banana',
  'bananes': 'banana',
  'citron': 'lemon',
  'citrons': 'lemon',
  'fraise': 'strawberry',
  'fraises': 'strawberry',
  'bleuet': 'blueberries',
  'bleuets': 'blueberries',
  'framboise': 'raspberries',
  'framboises': 'raspberries',
  'raisin': 'grapes',
  'raisins': 'grapes',
  'mangue': 'mango',
  'mangues': 'mango',
  'ananas': 'pineapple',
  'peche': 'peach',
  'pêche': 'peach',
  'peches': 'peach',
  'pêches': 'peach',
  'poire': 'pear',
  'poires': 'pear',
  'pasteque': 'watermelon',
  'pastèque': 'watermelon',
  'avocat': 'avocado',
  'avocats': 'avocado',
  'tomate': 'tomato',
  'tomates': 'tomato',
  'concombre': 'cucumber',
  'concombres': 'cucumber',
  'laitue': 'lettuce',
  'epinards': 'spinach',
  'épinards': 'spinach',
  'carotte': 'carrot',
  'carottes': 'carrot',
  'brocoli': 'broccoli',
  'brocolis': 'broccoli',
  'chou fleur': 'cauliflower',
  'champignon': 'mushroom',
  'champignons': 'mushroom',
  'oignon': 'onion',
  'oignons': 'onion',
  'ail': 'garlic',
  'gingembre': 'ginger',
  'mais': 'corn',
  'maïs': 'corn',
  'petits pois': 'peas',
  'haricots': 'beans',
  'saumon': 'fish',
  'thon': 'fish',
  'jambon': 'meat',
  'saucisse': 'sausage',
  'saucisses': 'sausage',
  'chocolat': 'chocolate',
  'croustilles': 'chips',
  'confiture': 'jam',
  'miel': 'honey',
  'beurre d arachide': 'peanut_butter',
  'jus': 'drink',
};
