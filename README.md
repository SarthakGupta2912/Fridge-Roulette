# 🍳 Fridge Roulette

**Snap your fridge. Spin the wheel. Cook something fun.**

Fridge Roulette is a kid-friendly Android app that looks at one photo of your fridge, finds the food on the phone, and turns it into a small cooking challenge. Everything happens on the device. There is no account, no ads, no analytics, and no internet permission.

Made for children around 10 years old, with big buttons, short sentences, emoji, and a grown-up safety note on every recipe.

## The 3-step game

1. **Photo** - take a picture with the system camera or pick one from the gallery.
2. **Foods** - check the foods the app found. Tap a chip to remove a mistake, or add food by hand.
3. **Spin** - the slot machine picks one of 70 recipes that fits the food you have. Read the steps, then cook!

If no full recipe fits, the app makes a two-food snack from foods that are safe to eat raw. If there is not even enough for that, it says so in a friendly way and helps the child add more food.

## Offline promise

- The YOLO food detector is bundled in `assets/models/food_detector.tflite` (about 2.9 MB). The app never downloads a model.
- The merged **release** manifest has **no INTERNET permission**, no camera permission, and no background-work permissions.
- The system camera app takes the photo, so Fridge Roulette itself does not need camera access.
- No photo, food list, or recipe choice ever leaves the phone.

## Features

- One-time on-device detection with bounding boxes on the photo.
- 48 foods in the hand-add catalog and 70 recipes.
- No-repeat recipe picks (the last three are avoided when possible).
- Mix-and-match snack fallback using only raw-safe foods.
- Material 3 light and dark themes that follow the system.
- Responsive phone, tablet, portrait, and landscape layouts.
- Text scaling up to at least 1.5x, 56 dp minimum tap targets, and screen-reader labels.
- Friendly handling for: camera/gallery failures, lost photos, model load failure, detection timeout, no food found, fewer than 2 foods, double taps, rotation, and leaving the check screen.
- Native splash screen, adaptive launcher icon, and Android 13 themed (monochrome) icon.
- R8 minification and resource shrinking for release builds.

## Technical stack

| Part | Choice |
| --- | --- |
| Framework | Flutter 3.44.6 / Dart 3.12.2 |
| UI | Material 3, plain `StatefulWidget` + `setState` |
| Detection | [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) 0.5.1 with an int8 COCO YOLO model |
| Camera / gallery | `image_picker` 1.2.4 |
| Android | minSdk 24 (Android 7.0), targetSdk 36, compileSdk 36, AGP 9.0.1 |
| State | One `DetectorService` and one `RecipePicker` created in `main.dart` |

### Food coverage

The bundled COCO model can find these foods directly:

`banana`, `apple`, `orange`, `broccoli`, `carrot`, `sandwich`, `pizza`, `hot dog`, `donut`, `cake`, and `bottle` (shown as **Juice or Drink**).

Everything else in the catalog is added by hand: milk, eggs, cheese, tomato, bread, rice, chicken, vegetables, fruit, and pantry items. Dishes and tools such as cups, bowls, forks, and the fridge itself are ignored on purpose.

## Run the app

### What you need

- Flutter 3.44 or newer with Dart 3.12.
- Android SDK 36 and NDK `28.2.13676358` (the YOLO plugin uses native code).
- Java 17.
- An Android phone or emulator running Android 7.0 or newer.

```powershell
flutter pub get
flutter run
```

The first launch loads the model on a splash screen. If the model cannot load, the app still works: the child can add food by hand.

### Tests and analysis

```powershell
flutter analyze
flutter test
```

The test suite has 23 tests:

- recipe count, unique ids, valid ingredient ids;
- recipe eligibility and missing-food rules;
- no-repeat picks and the mix-and-match fallback;
- widget tests for all four screens at 360x640, 640x360, and 1024x1366 with 1.5x text;
- detection results, chip removal, the hand-add grid, back confirmation, the model-error card, and a full spin-to-recipe flow.

## Build for release

The project reads signing details from `android/key.properties`, which is gitignored.

```powershell
Copy-Item android\key.properties.example android\key.properties
# Put your real passwords in key.properties and place upload-keystore.jks in android\app\
flutter build apk --release
flutter build appbundle --release
```

Artifacts:

- `build\app\outputs\flutter-apk\app-release.apk`
- `build\app\outputs\bundle\release\app-release.aab`

See [RELEASE.md](RELEASE.md) for the full checklist, manifest checks, and Play Console steps. See [STORE_LISTING.md](STORE_LISTING.md) for ready-to-paste store text and [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the privacy policy.

## Project layout

```text
lib/
  main.dart                 App start, global error handling, model loading
  strings.dart              Every word the child sees
  theme.dart                Light and dark Material 3 themes
  data/
    ingredients.dart        Food catalog and COCO name mapping
    recipe.dart             Recipe model
    recipes*.dart           70 recipes in three readable files
  services/
    detector_service.dart   Load the model once, detect food, safe boxes
    recipe_picker.dart      Eligibility, no repeats, snack fallback
  screens/
    splash_screen.dart      In-app loading screen
    home_screen.dart        Step 1: photo
    check_food_screen.dart  Step 2: confirm and edit food
    roulette_screen.dart    Step 3a: spin
    recipe_screen.dart      Step 3b: recipe challenge
  widgets/                  Reusable buttons, chips, dialogs, photo boxes
assets/models/
  food_detector.tflite      Bundled int8 COCO model
test/
  recipe_picker_test.dart   Recipe logic tests
  widget_test.dart          Screen layout and flow tests
android/
  app/proguard-rules.pro    Extra R8 rules for LiteRT / YOLO
```

### Adding a recipe

1. Add a `Recipe` to `lib/data/recipes_a.dart`, `recipes_b.dart`, or `recipes_c.dart`.
2. Use ingredient ids from `lib/data/ingredients.dart` in `requiredFoods`.
3. Keep steps short, numbered in order, and mention asking a grown-up for knives or heat.
4. Run `flutter test`; the data test checks for duplicate ids and unknown foods.

All visible text belongs in `lib/strings.dart`.

## Known limitations

- The bundled model is trained on COCO classes, so it cannot see every fridge item. The hand-add grid is the main fallback.
- Detection works best with good light and an open fridge door. Boxes show only the first box for each food.
- Dark, clear bottles, and some packages may be missed or labeled "Juice or Drink".
- Model inference and release APK size have not been checked on a physical phone in this development environment. Test on at least one low-end and one high-end device before publishing.
- The release build currently contains native libraries for all Android ABIs, so the universal APK is large (about 75 MB). The AAB is about 64 MB and Play delivers only the needed pieces.
- The Ultralytics plugin still applies the Kotlin Gradle Plugin, so Flutter prints a future-compatibility warning at build time. Watch the plugin for an update.
- The recipe set is entertainment, not medical or allergy advice. Always check ingredients for allergies.

## Privacy

Fridge Roulette collects nothing and sends nothing. Read [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full statement. The policy must be hosted at a public URL for Google Play.

## License

This project is released under the **GNU Affero General Public License v3.0**. See [LICENSE](LICENSE).

The bundled Ultralytics YOLO model and the `ultralytics_yolo` plugin are also AGPL-3.0. If you publish a modified version, keep the source available under the same license.

Repository: <https://github.com/SarthakGupta2912/Fridge-Roulette>
