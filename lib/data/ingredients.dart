/// One food that the app understands.
class Ingredient {
  const Ingredient(
    this.id,
    this.name,
    this.emoji, {
    this.cocoName,
    this.isSnackSafe = false,
  });

  final String id;
  final String name;
  final String emoji;

  /// The name YOLO uses for this food. Null for foods we only add by hand.
  final String? cocoName;

  /// Safe to eat raw in a simple snack plate. Used by the mix-and-match fallback.
  final bool isSnackSafe;
}

/// Foods the model can find, plus foods a child can add by hand.
const List<Ingredient> allIngredients = [
  Ingredient('banana', 'Banana', '🍌', cocoName: 'banana', isSnackSafe: true),
  Ingredient('apple', 'Apple', '🍎', cocoName: 'apple', isSnackSafe: true),
  Ingredient('orange', 'Orange', '🍊', cocoName: 'orange', isSnackSafe: true),
  Ingredient(
    'broccoli',
    'Broccoli',
    '🥦',
    cocoName: 'broccoli',
    isSnackSafe: true,
  ),
  Ingredient('carrot', 'Carrot', '🥕', cocoName: 'carrot', isSnackSafe: true),
  Ingredient(
    'sandwich',
    'Sandwich',
    '🥪',
    cocoName: 'sandwich',
    isSnackSafe: true,
  ),
  Ingredient('pizza', 'Pizza', '🍕', cocoName: 'pizza', isSnackSafe: true),
  Ingredient(
    'hot_dog',
    'Hot Dog',
    '🌭',
    cocoName: 'hot dog',
    isSnackSafe: true,
  ),
  Ingredient('donut', 'Donut', '🍩', cocoName: 'donut', isSnackSafe: true),
  Ingredient('cake', 'Cake', '🍰', cocoName: 'cake', isSnackSafe: true),
  Ingredient(
    'drink',
    'Juice or Drink',
    '🥤',
    cocoName: 'bottle',
    isSnackSafe: true,
  ),
  Ingredient('milk', 'Milk', '🥛', isSnackSafe: true),
  Ingredient('eggs', 'Eggs', '🥚'),
  Ingredient('cheese', 'Cheese', '🧀', isSnackSafe: true),
  Ingredient('butter', 'Butter', '🧈'),
  Ingredient('tomato', 'Tomato', '🍅', isSnackSafe: true),
  Ingredient('lettuce', 'Lettuce', '🥬', isSnackSafe: true),
  Ingredient('potato', 'Potato', '🥔'),
  Ingredient('onion', 'Onion', '🧅'),
  Ingredient('rice', 'Rice', '🍚'),
  Ingredient('bread', 'Bread', '🍞', isSnackSafe: true),
  Ingredient('chicken', 'Chicken', '🍗'),
  Ingredient('fish', 'Fish', '🐟'),
  Ingredient('yogurt', 'Yogurt', '🥣', isSnackSafe: true),
  Ingredient('cucumber', 'Cucumber', '🥒', isSnackSafe: true),
  Ingredient('pasta', 'Pasta', '🍝'),
  Ingredient('corn', 'Corn', '🌽'),
  Ingredient('peas', 'Peas', '🫛'),
  Ingredient('spinach', 'Spinach', '🍃', isSnackSafe: true),
  Ingredient('mushroom', 'Mushroom', '🍄'),
  Ingredient('bell_pepper', 'Bell Pepper', '🫑', isSnackSafe: true),
  Ingredient('garlic', 'Garlic', '🧄'),
  Ingredient('lemon', 'Lemon', '🍋', isSnackSafe: true),
  Ingredient('strawberry', 'Strawberry', '🍓', isSnackSafe: true),
  Ingredient('grapes', 'Grapes', '🍇', isSnackSafe: true),
  Ingredient('watermelon', 'Watermelon', '🍉', isSnackSafe: true),
  Ingredient('pineapple', 'Pineapple', '🍍', isSnackSafe: true),
  Ingredient('mango', 'Mango', '🥭', isSnackSafe: true),
  Ingredient('avocado', 'Avocado', '🥑', isSnackSafe: true),
  Ingredient('cabbage', 'Cabbage', '🥬', isSnackSafe: true),
  Ingredient('flour', 'Flour', '🌾'),
  Ingredient('noodles', 'Noodles', '🍜'),
  Ingredient('oats', 'Oats', '🥣'),
  Ingredient('honey', 'Honey', '🍯', isSnackSafe: true),
  Ingredient('chocolate', 'Chocolate', '🍫', isSnackSafe: true),
  Ingredient('peanut_butter', 'Peanut Butter', '🥜', isSnackSafe: true),
  Ingredient('beans', 'Beans', '🫘'),
  Ingredient('soup', 'Soup', '🍲'),
];

/// The foods we show first when a child taps "Add food".
const List<String> commonFoodIds = [
  'milk',
  'eggs',
  'cheese',
  'butter',
  'tomato',
  'lettuce',
  'cucumber',
  'potato',
  'onion',
  'carrot',
  'broccoli',
  'rice',
  'bread',
  'pasta',
  'chicken',
  'fish',
  'yogurt',
  'banana',
  'apple',
  'orange',
  'strawberry',
  'grapes',
  'avocado',
  'corn',
  'peas',
  'bell_pepper',
  'mushroom',
  'spinach',
  'cabbage',
  'garlic',
  'lemon',
  'mango',
  'pineapple',
  'watermelon',
  'oats',
  'honey',
  'chocolate',
  'peanut_butter',
  'beans',
  'soup',
  'flour',
  'noodles',
];

/// Every ingredient the app knows, found by id.
Ingredient? findIngredient(String id) {
  for (final Ingredient food in allIngredients) {
    if (food.id == id) {
      return food;
    }
  }
  return null;
}

/// Turns a YOLO class name such as "hot dog" into one of our foods.
Ingredient? findFoodFromCocoClass(String className) {
  final String name = className.toLowerCase().trim();
  for (final Ingredient food in allIngredients) {
    if (food.cocoName == name) {
      return food;
    }
  }
  return null;
}

/// Dishes and tools the model may see. They are not food, so we hide them.
const List<String> ignoredCocoClasses = [
  'cup',
  'bowl',
  'wine glass',
  'fork',
  'knife',
  'spoon',
  'person',
  'chair',
  'refrigerator',
  'dining table',
  'microwave',
  'oven',
  'sink',
];
