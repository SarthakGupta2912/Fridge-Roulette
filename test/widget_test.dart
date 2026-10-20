import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fridge_roulette/data/ingredients.dart';
import 'package:fridge_roulette/data/recipe.dart';
import 'package:fridge_roulette/screens/check_food_screen.dart';
import 'package:fridge_roulette/screens/home_screen.dart';
import 'package:fridge_roulette/screens/model_download_screen.dart';
import 'package:fridge_roulette/screens/recipe_screen.dart';
import 'package:fridge_roulette/screens/roulette_screen.dart';
import 'package:fridge_roulette/screens/settings_screen.dart';
import 'package:fridge_roulette/services/chef_brain.dart';
import 'package:fridge_roulette/services/detector_service.dart';
import 'package:fridge_roulette/services/recipe_generator.dart';
import 'package:fridge_roulette/strings.dart';
import 'package:fridge_roulette/theme.dart';

/// A tiny real PNG. The code under test reads its size and draws it.
final Uint8List testPhoto = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAADCAYAAAC09K7GAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAASSURBVBhXY/i/peI/MmYgKAAAyfwl+bthmxMAAAAASUVORK5CYII=',
);

const Recipe quickRecipe = Recipe(
  title: 'Quick Banana Smile',
  emoji: '🍌',
  minutes: 5,
  level: 'Easy',
  steps: <String>[
    'Wash the fruit.',
    'Ask a grown-up to cut it.',
    'Make a funny face.',
  ],
  tip: 'Eat it with a smile.',
  foods: <String>['Banana', 'Apple'],
);

const String goodModelText = '''
TITLE: Banana Apple Sunshine
EMOJI: 🍌
TIME: 12 minutes
LEVEL: Medium
STEPS:
1. Wash the banana and the apple.
2. Ask a grown-up to cut them into small pieces.
3. Put them in a bowl and mix them together.
4. Make a smiley face on top.
TIP: Eat it with a funny story.
''';

/// A recipe writer that never touches the real on-device model.
class FakeRecipeGenerator extends RecipeGenerator {
  FakeRecipeGenerator({
    this.aiReady = false,
    this.modelText = goodModelText,
    this.quick = quickRecipe,
  });

  final bool aiReady;
  final String modelText;
  final Recipe quick;

  @override
  Future<bool> isAiReady() async => aiReady;

  @override
  Stream<String> makeRecipe(List<String> foods) async* {
    final List<String> parts = modelText.split(' ');
    for (int index = 0; index < parts.length; index++) {
      yield index == 0 ? parts[index] : ' ${parts[index]}';
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Recipe makeQuickRecipe(List<String> foods) => quick;

  @override
  Future<void> stop() async {}

  @override
  Future<void> release() async {}
}

ChefBrain readyBrain() {
  return ChefBrain(initialStatus: ChefBrainStatus.ready);
}

/// A chef brain whose download can be driven by the test.
class FakeChefBrain extends ChefBrain {
  FakeChefBrain({ChefBrainStatus initial = ChefBrainStatus.missing})
    : _fakeStatus = initial,
      super(initialStatus: initial);

  ChefBrainStatus _fakeStatus;
  int _fakeProgress = 0;
  ChefBrainProblem? _fakeProblem;
  bool downloadCalled = false;

  @override
  ChefBrainStatus get status => _fakeStatus;

  @override
  int get progress => _fakeProgress;

  @override
  ChefBrainProblem? get problem => _fakeProblem;

  @override
  bool get isDownloading => _fakeStatus == ChefBrainStatus.downloading;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> download() async {
    downloadCalled = true;
    _fakeStatus = ChefBrainStatus.downloading;
    _fakeProgress = 0;
    _fakeProblem = null;
    notifyListeners();
  }

  @override
  void cancelDownload() {
    _fakeStatus = ChefBrainStatus.missing;
    _fakeProgress = 0;
    _fakeProblem = ChefBrainProblem.cancelled;
    notifyListeners();
  }

  void setProgress(int value) {
    _fakeProgress = value;
    notifyListeners();
  }

  void failWith(ChefBrainProblem problem) {
    _fakeStatus = ChefBrainStatus.failed;
    _fakeProgress = 0;
    _fakeProblem = problem;
    notifyListeners();
  }
}

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
  return FakeDetector(<FoodDetection>[
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

/// A food finder that keeps scanning until the test finishes it, so the
/// progress overlay can be checked without a real model.
class SlowDetector extends DetectorService {
  SlowDetector() {
    status = DetectorStatus.ready;
  }

  final Completer<DetectionResult> _result = Completer<DetectionResult>();

  @override
  Future<DetectionResult> detectFoods(Uint8List imageBytes) => _result.future;

  void finish() {
    if (!_result.isCompleted) {
      _result.complete(const DetectionResult(<FoodDetection>[]));
    }
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

/// Lets the fake stream finish and the one-shot chef animation settle.
Future<void> finishRecipe(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.pumpAndSettle();
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
              chefBrain: readyBrain(),
              generator: FakeRecipeGenerator(),
            ),
            size: size,
            textScale: 1.5,
          );
          await tester.pumpAndSettle();

          expect(find.text(AppStrings.appName), findsOneWidget);
          expect(find.text(AppStrings.takePhoto), findsOneWidget);
          expect(find.byTooltip(AppStrings.settings), findsOneWidget);
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
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
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
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
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
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
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
            chefBrain: readyBrain(),
            generator: FakeRecipeGenerator(),
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
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
          photoBytes: testPhoto,
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.modelFailedTitle), findsOneWidget);
      expect(find.text(AppStrings.useHands), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('no food found shows the friendly empty card', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: FakeDetector(<FoodDetection>[]),
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
          photoBytes: testPhoto,
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.noFoodTitle), findsOneWidget);
      expect(find.text(AppStrings.addFoodByHand), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('slow scan shows a full-page progress card with Stop', (
      WidgetTester tester,
    ) async {
      final SlowDetector detector = SlowDetector();
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: detector,
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
          photoBytes: testPhoto,
        ),
        size: const Size(640, 360),
        textScale: 1.5,
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(AppStrings.lookingForFood), findsOneWidget);
      expect(find.text(AppStrings.detectingHint), findsOneWidget);
      expect(find.text(AppStrings.stopLooking), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expectNoLayoutError(tester);

      detector.finish();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.stopLooking), findsNothing);
      expect(find.text(AppStrings.noFoodTitle), findsOneWidget);
    });

    testWidgets('spins to the roulette screen', (WidgetTester tester) async {
      await pumpScreen(
        tester,
        CheckFoodScreen(
          detector: foundBananaAndApple(),
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
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
    testWidgets('spin opens the live recipe and Quick chef finishes it', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RouletteScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.spinTheWheel), findsOneWidget);
      await tapVisible(tester, find.text(AppStrings.spinTheWheel));
      await tester.pump();
      expect(find.text(AppStrings.spinning), findsWidgets);

      await tester.pump(const Duration(milliseconds: 1600));
      await finishRecipe(tester);

      expect(find.text(AppStrings.recipeTitle), findsOneWidget);
      expect(find.text(quickRecipe.title), findsOneWidget);
      expect(find.text(AppStrings.quickChef), findsOneWidget);
      expect(find.text(quickRecipe.steps.first), findsOneWidget);
      expect(find.text(AppStrings.safetyNote), findsOneWidget);
      expect(find.text(AppStrings.makeAnother), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('AI recipe streams in and gets the AI chef badge', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RecipeScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(aiReady: true),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );
      await finishRecipe(tester);

      expect(find.text(AppStrings.aiChef), findsOneWidget);
      expect(find.text('Banana Apple Sunshine'), findsOneWidget);
      expect(find.text('Wash the banana and the apple.'), findsOneWidget);
      expect(find.text('Eat it with a funny story.'), findsOneWidget);
      expect(find.text(AppStrings.safetyNote), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('broken AI text is shown as friendly raw notes', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RecipeScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(
            aiReady: true,
            modelText: 'The chef wrote a little poem about bananas.',
          ),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );
      await finishRecipe(tester);

      expect(find.text(AppStrings.rawRecipeBody), findsOneWidget);
      expect(
        find.text('The chef wrote a little poem about bananas.'),
        findsOneWidget,
      );
      expect(find.text(AppStrings.tryAiAgain), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('blank AI text falls back to Quick chef', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RecipeScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(aiReady: true, modelText: '\n\n\n'),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );
      await finishRecipe(tester);

      expect(find.text(AppStrings.quickChef), findsOneWidget);
      expect(find.text(AppStrings.aiHiccup), findsOneWidget);
      expect(find.text(quickRecipe.title), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('AI recipe with an invented food falls back to Quick chef', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        RecipeScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(
            aiReady: true,
            modelText: goodModelText.replaceFirst(
              'Wash the banana and the apple.',
              'Add the pie crust and cream.',
            ),
          ),
          foodIds: <String>['banana', 'apple'],
        ),
        textScale: 1.5,
      );
      await finishRecipe(tester);

      expect(find.text(AppStrings.quickChef), findsOneWidget);
      expect(find.text(AppStrings.aiExtraFood), findsOneWidget);
      expect(find.text(quickRecipe.title), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets(
      'missing model falls back to Quick chef with a download action',
      (WidgetTester tester) async {
        await pumpScreen(
          tester,
          RecipeScreen(
            chefBrain: readyBrain(),
            generator: FakeRecipeGenerator(aiReady: false),
            foodIds: <String>['banana', 'apple'],
          ),
          textScale: 1.5,
        );
        await finishRecipe(tester);

        expect(find.text(AppStrings.quickChef), findsOneWidget);
        expect(find.text(AppStrings.aiNoModel), findsOneWidget);
        expect(find.text(AppStrings.tryAiAgain), findsOneWidget);
        expect(find.text(quickRecipe.title), findsOneWidget);
        expectNoLayoutError(tester);
      },
    );

    for (final Size size in sizes) {
      testWidgets(
        'recipe fits ${size.width.toInt()}x${size.height.toInt()} at 1.5x text',
        (WidgetTester tester) async {
          await pumpScreen(
            tester,
            RecipeScreen(
              chefBrain: readyBrain(),
              generator: FakeRecipeGenerator(aiReady: true),
              foodIds: <String>['banana', 'apple'],
            ),
            size: size,
            textScale: 1.5,
          );
          await finishRecipe(tester);

          expect(find.text('Banana Apple Sunshine'), findsOneWidget);
          expect(find.text(AppStrings.ingredientsLabel), findsOneWidget);
          expect(find.text(AppStrings.stepsLabel), findsOneWidget);
          expect(find.text(AppStrings.chefTip), findsOneWidget);
          expect(find.text(AppStrings.makeAnother), findsOneWidget);
          expectNoLayoutError(tester);
        },
      );
    }
  });

  group('model download', () {
    testWidgets('shows a moving bar, then real progress', (
      WidgetTester tester,
    ) async {
      final FakeChefBrain brain = FakeChefBrain();
      await pumpScreen(
        tester,
        ModelDownloadScreen(chefBrain: brain),
        size: const Size(360, 640),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.downloadButton), findsOneWidget);
      await tapVisible(tester, find.text(AppStrings.downloadButton));
      await tester.pump();

      expect(brain.downloadCalled, isTrue);
      expect(find.text(AppStrings.downloadStarting), findsOneWidget);
      expect(find.text(AppStrings.downloadNotificationHint), findsOneWidget);
      LinearProgressIndicator bar = tester.widget(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, isNull);

      brain.setProgress(42);
      await tester.pump();

      expect(find.textContaining('42%'), findsOneWidget);
      bar = tester.widget(find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.42, 0.001));
      expectNoLayoutError(tester);
    });

    testWidgets('explains a missing internet connection and offers retry', (
      WidgetTester tester,
    ) async {
      final FakeChefBrain brain = FakeChefBrain()
        ..failWith(ChefBrainProblem.noInternet);
      await pumpScreen(
        tester,
        ModelDownloadScreen(chefBrain: brain),
        size: const Size(360, 640),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.downloadNoInternetTitle), findsOneWidget);
      expect(find.text(AppStrings.downloadNoInternetBody), findsOneWidget);
      expect(find.text(AppStrings.downloadTryAgain), findsOneWidget);
      expectNoLayoutError(tester);
    });

    testWidgets('explains a busy server', (WidgetTester tester) async {
      final FakeChefBrain brain = FakeChefBrain()
        ..failWith(ChefBrainProblem.server);
      await pumpScreen(
        tester,
        ModelDownloadScreen(chefBrain: brain),
        size: const Size(360, 640),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.downloadServerTitle), findsOneWidget);
      expect(find.text(AppStrings.downloadServerBody), findsOneWidget);
      expect(find.text(AppStrings.downloadTryAgain), findsOneWidget);
      expectNoLayoutError(tester);
    });
  });

  group('settings', () {
    testWidgets('shows the chef brain status and license', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        SettingsScreen(
          chefBrain: readyBrain(),
          generator: FakeRecipeGenerator(),
        ),
        size: const Size(360, 640),
        textScale: 1.5,
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.chefBrainTitle), findsOneWidget);
      expect(find.text(AppStrings.chefBrainReady), findsOneWidget);
      expect(find.text(AppStrings.deleteModel), findsOneWidget);
      expect(find.text(AppStrings.aboutTitle), findsOneWidget);
      expect(find.text(AppStrings.privacyPromise), findsOneWidget);
      expectNoLayoutError(tester);
    });
  });
}
