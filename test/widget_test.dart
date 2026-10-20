import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fridge_roulette/data/ingredients.dart';
import 'package:fridge_roulette/data/recipe.dart';
import 'package:fridge_roulette/screens/check_food_screen.dart';
import 'package:fridge_roulette/screens/home_screen.dart';
import 'package:fridge_roulette/screens/recipe_screen.dart';
import 'package:fridge_roulette/screens/roulette_screen.dart';
import 'package:fridge_roulette/services/detector_service.dart';
import 'package:fridge_roulette/services/recipe_picker.dart';
import 'package:fridge_roulette/strings.dart';
import 'package:fridge_roulette/theme.dart';

/// A tiny real PNG. The code under test reads its size and draws it.
final Uint8List testPhoto = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAYAAAC09K7GAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAASSURBVBhXY/i/peI/MmYgKAAAyfwl+bthmxMAAAAASUVORK5CYII=',
);

/// A recipe with short steps, so the tests are easy to read.
const Recipe testRecipe = Recipe(
  id: 'test_banana_apple',
  name: 'Banana Apple Smile',
  emoji: '🍌',
  requiredFoods: ['banana', 'apple'],
  minutes: 5,
  difficulty: 1,
  twist: 'Make a funny face on your plate.',
  steps: [
    'Wash the fruit.',
    'Ask a grown-up to cut it.',
    'Make a funny face.',
    'Eat your snack!',
  ],
);

/// A food finder that answers right away without loading a real model.
class FakeDetector extends DetectorService {
  FakeDetector(this.foods) {
    status = DetectorStatus.ready;
  }

  final List<FoodDetection> foods;

  @override
  Future<void> loadModel() async {
    status = DetectorStatus.ready;
    notifyListeners();
  }

  @override
  Future<DetectionResult> detectFoods(Uint8List imageBytes) async {
    return DetectionResult(foods);
  }
}

FakeDetector foundBananaAndApple() {
  return FakeDetector([
    FoodDetection(
      food: findIngredient('banana')!,
      confidence: 0.9,
      box: const Rect.fromLTRB(0.1, 0.1, 0.5, 0.5),
    ),
    FoodDetection(
      food: findIngredient('apple')!,
      confidence: 0.8,
      box: const Rect.fromLTRB(0.5, 0.4, 0.9, 0.9),
    ),
  ]);
}

/// A food finder that never wakes up, to test the friendly error card.
class BrokenDetector extends DetectorService {
  BrokenDetector() {
    status = DetectorStatus.failed;
  }

  @override
  Future<void> loadModel() async {
    status = DetectorStatus.failed;
    notifyListeners();
  }
}

/// Pumps one screen at a real phone or tablet size.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(360, 640),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Builder(
        builder: (BuildContext context) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: screen,
          );
        },
      ),
    ),
  );
  await tester.pump();
}

void expectNoLayoutError(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

/// Scrolls a widget into view before tapping, like a child would.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// A tiny first page so we can test the back button on a pushed screen.
class TestHost extends StatelessWidget {
  const TestHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Builder(
          builder: (BuildContext context) {
            return FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => child,
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );
  }
}

void main() {
  final List<Size> sizes = <Size>[
    const Size(360, 640),
    const Size(640, 360),
    const Size(1024, 1366),
  ];

  group('home screen layout', () {
    for (final Size size in sizes) {
      testWidgets(
        'fits ${size.width.toInt()}x${size.height.toInt()} at 1.5x text',
        (WidgetTester tester) async {
          await pumpScreen(
            tester,
            HomeScreen(
              detector: FakeDetector(<FoodDetection>[]),
              picker: RecipePicker(recipes: <Recipe>[testRecipe]),
            ),
            size: size,
            textScale: 1.5,
          );
          await tester.pumpAndSettle();

          expect(find.text(AppStrings.appName), findsOneWidget);
          expect(find.text(AppStrings.takePhoto), findsOneWidget);
          expectNoLayoutError(tester);
        },
      );
    }
  });

  group('check food screen', () {
    testWidgets('shows found food and enables the spin with 2 foods', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: foundBananaAndApple(),
          picker: RecipePicker(recipes: <Recipe>[testRecipe]),
          photoBytes: testPhoto,
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.yourFoods), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text(AppStrings.foodCount(2)), findsOneWidget);

      final FilledButton spin = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.spinTheWheel),
      );
      expect(spin.onPressed, isNotNull);
      expectNoLayoutError(tester);
    });

    testWidgets('removing a food disables the spin', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: foundBananaAndApple(),
          picker: RecipePicker(recipes: <Recipe>[testRecipe]),
          photoBytes: testPhoto,
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Banana'));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
      expect(find.text(AppStrings.notEnoughHint), findsOneWidget);
      final FilledButton spin = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.spinTheWheel),
      );
      expect(spin.onPressed, isNull);
      expectNoLayoutError(tester);
    });

    testWidgets('add food by hand opens the grid and adds a chip', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: FakeDetector(<FoodDetection>[]),
          picker: RecipePicker(recipes: <Recipe>[testRecipe]),
          autoDetect: false,
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.addFoodTitle), findsOneWidget);
      await tester.tap(find.text('Milk'));
      await tester.pump();
      await tester.tap(find.text(AppStrings.doneWithCount(1)));
      await tester.pumpAndSettle();

      expect(find.text('Milk'), findsOneWidget);
      expect(find.text(AppStrings.noPhotoYet), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('back button asks before leaving', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        TestHost(
          child: CheckFoodScreen(
            detector: foundBananaAndApple(),
            picker: RecipePicker(recipes: <Recipe>[testRecipe]),
            photoBytes: testPhoto,
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.checkTitle), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.leaveTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.stay));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.checkTitle), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.leave));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('model problem card fits small screens at 1.5x text', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: BrokenDetector(),
          picker: RecipePicker(recipes: <Recipe>[testRecipe]),
          photoBytes: testPhoto,
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.modelFailedTitle), findsOneWidget);
      expect(find.text(AppStrings.useHands), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('spins to the roulette screen', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: foundBananaAndApple(),
          picker: RecipePicker(recipes: <Recipe>[testRecipe]),
          photoBytes: testPhoto,
        ),
      );
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text(AppStrings.spinTheWheel));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.rouletteTitle), findsOneWidget);
      expectNoLayoutError(tester);
    });
  });

  group('roulette and recipe', () {
    testWidgets('spin reveals a recipe and opens the challenge', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RouletteScreen(
          picker: RecipePicker(
            recipes: <Recipe>[testRecipe],
            random: Random(7),
          ),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );

      expect(find.text(AppStrings.spinTheWheel), findsOneWidget);
      await tapVisible(tester, find.text(AppStrings.spinTheWheel));
      await tester.pump();
      expect(find.text(AppStrings.spinning), findsWidgets);

      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      expect(find.text(testRecipe.name), findsOneWidget);
      expect(find.text(AppStrings.letsCook), findsOneWidget);
      expectNoLayoutError(tester);

      await tapVisible(tester, find.text(AppStrings.letsCook));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.recipeTitle), findsOneWidget);
      expect(find.text(testRecipe.steps.first), findsOneWidget);
      expect(find.text(AppStrings.safetyNote), findsOneWidget);
      expectNoLayoutError(tester);
    });

    for (final Size size in sizes) {
      testWidgets(
        'recipe fits ${size.width.toInt()}x${size.height.toInt()} at 1.5x text',
        (WidgetTester tester) async {
          await pumpScreen(
            tester,
            const RecipeScreen(
              recipe: testRecipe,
              availableFoodIds: <String>['banana', 'apple'],
            ),
            size: size,
            textScale: 1.5,
          );

          expect(find.text(testRecipe.name), findsOneWidget);
          expect(find.text(AppStrings.challengeTwist), findsOneWidget);
          expect(find.text(AppStrings.ingredientsLabel), findsOneWidget);
          expect(find.text(AppStrings.stepsLabel), findsOneWidget);
          expect(find.text(AppStrings.spinAgain), findsOneWidget);
          expectNoLayoutError(tester);
        },
      );
    }
  });
}
