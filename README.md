# 🍳 Fridge Roulette

**Snap your fridge. Spin the wheel. Cook something fun.**

Fridge Roulette is a kid-friendly Android app that looks at one photo of your fridge, finds the food on the phone, and turns it into a small cooking challenge. The recipe is written live on the device by a small language model. If the model is not downloaded yet, a friendly **Quick chef** writes a recipe without AI.

There is no account, no ads, and no analytics. **No personal data is collected. Internet is used only once to download the AI recipe model.**

Made for children around 10 years old, with big buttons, short sentences, emoji, and a grown-up safety note on every recipe.

## The 3-step game

1. **Photo** - take a picture with the system camera or pick one from the gallery.
2. **Foods** - check the foods the app found. Tap a chip to remove a mistake, or add food by hand.
3. **Spin** - the wheel starts the chef. The AI chef writes a brand-new recipe from the foods you have, word by word. The Quick chef is always available as a fallback.

## The AI chef

- **Model:** `Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task`
- **Friendly name:** Qwen2.5 0.5B Instruct
- **Size:** 546,660,344 bytes (about 521 MiB)
- **License:** [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0) (commercial use allowed)
- **Model page:** <https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct>
- **Download URL:** <https://huggingface.co/litert-community/Qwen2.5-0.5B-Instruct/resolve/main/Qwen2.5-0.5B-Instruct_multi-prefill-seq_q8_ekv1280.task>

The model is **not bundled** in the APK or AAB. The app offers the download on the first recipe request or from **Settings > Chef brain**. It is stored in the app's private storage and reused offline after that. The child can delete it from Settings to free the space.

The app uses the MediaPipe engine from `flutter_edge_ai_mediapipe`, which keeps Android 7.0 (`minSdk 24`) support. The model is loaded only while a recipe is being written. It tries the GPU first and falls back to the CPU. Generation streams token by token, stops after 60 seconds or 340 tokens, and releases the model when the child leaves the recipe screen or the app stays in the background.

The prompt uses only the detected foods plus salt, pepper, oil, water, and sugar. It asks for a kid-friendly recipe, no alcohol, fully cooked meat/fish/eggs, short steps, a grown-up warning for knives and heat, and a fixed plain-text format:

```text
TITLE:
EMOJI:
TIME:
LEVEL:
STEPS:
TIP:
```

The parser is lenient. If the model writes something unusable, the screen shows the chef's raw words with friendly retry actions instead of a blank card.

## Privacy and network

- The YOLO food detector is bundled in `assets/models/food_detector.tflite` (about 2.9 MB). The app never downloads a detector.
- The only network request is the one-time AI model download from Hugging Face. It sends no account, photo, food list, recipe, or personal profile. Standard connection information such as an IP address is handled by Hugging Face as part of the download; their privacy policy applies.
- Photos, food lists, and recipes stay on the phone. No photo or recipe is uploaded.
- No analytics, ads, tracking SDKs, crash reporting, or external APIs.
- The release manifest asks for `INTERNET` (one-time model download), plus `ACCESS_NETWORK_STATE` and `WAKE_LOCK` so the download can check the connection and finish. It does not ask for camera, location, storage, microphone, notifications, or foreground-service permission.
- Airplane mode is fine after the model is downloaded. Without the model and without internet, the Quick chef still works.

## Features

- One-time on-device detection with bounding boxes on the photo.
- 48 foods in the hand-add catalog.
- Live, streaming recipe writing with a typing-style text reveal and a **Stop** button.
- Random chef style and fun twist, plus the last three recipe names are sent back so the model avoids repeats.
- Quick chef fallback using a method, a flavour, a serving idea, and the detected foods. It never repeats the same title twice in a row.
- Clear **AI chef** and **Quick chef** badges.
- Safety-first prompt and a grown-up safety card on every recipe.
- Friendly download screen with percent, MB, free-space warning, Wi-Fi hint, cancel, and retry-friendly errors for no internet, interruption, damage, low storage, or closing the app.
- Material 3 light and dark themes that follow the system.
- Responsive phone, tablet, portrait, and landscape layouts.
- Text scaling up to at least 1.5x, 56 dp minimum tap targets, and screen-reader labels.
- Friendly handling for camera/gallery failures, lost photos, model load failure, detection timeout, no food found, fewer than 2 foods, double taps, rotation, leaving the check screen, AI timeout, and AI parse failure.
- Native splash screen, adaptive launcher icon, and Android 13 themed (monochrome) icon.
- R8 minification and resource shrinking for release builds.

## Technical stack

| Part | Choice |
| --- | --- |
| Framework | Flutter 3.44.6 / Dart 3.12.2 |
| UI | Material 3, plain `StatefulWidget` + `setState` |
| Detection | [`ultralytics_yolo`](https://pub.dev/packages/ultralytics_yolo) 0.6.16 with an int8 COCO YOLO model |
| Camera / gallery | `image_picker` 1.2.4 |
| On-device AI | `flutter_edge_ai` 2.4.1 + `flutter_edge_ai_mediapipe` 1.2.2 |
| Recipe model | Qwen2.5 0.5B Instruct, Apache-2.0, downloaded once |
| Android | minSdk 24 (Android 7.0), targetSdk 36, compileSdk 36, AGP 9.0.1 |
| State | One `DetectorService`, one `ChefBrain`, and one `RecipeGenerator` created in `main.dart` |

### Food coverage

The bundled COCO model can find these foods directly:

`banana`, `apple`, `orange`, `broccoli`, `carrot`, `sandwich`, `pizza`, `hot dog`, `donut`, `cake`, and `bottle` (shown as **Juice or Drink**).

Everything else in the catalog is added by hand: milk, eggs, cheese, tomato, bread, rice, chicken, vegetables, fruit, and pantry items. Dishes and tools such as cups, bowls, forks, and the fridge itself are ignored on purpose.

## Run the app

### What you need

- Flutter 3.44 or newer with Dart 3.12.
- Android SDK 36 and NDK `28.2.13676358` (the YOLO and MediaPipe plugins use native code).
- Java 17.
- An Android phone or emulator running Android 7.0 or newer.
- Internet only for the first AI model download. A Wi-Fi connection is recommended for the 521 MiB file.

```powershell
flutter pub get
flutter run
```

The first launch loads the detector on a splash screen. The first recipe request offers the chef-brain download; the child can skip it and use the Quick chef. If the detector cannot load, the child can still add food by hand.

### Tests and analysis

```powershell
flutter analyze
flutter test
```

The suite has 28 tests:

- prompt contains the foods, basics, recent names, safety rules, and the fixed format;
- parser handles a well-formed recipe, messy stars/lowercase/missing emoji, missing `STEPS`, and broken text;
- Quick chef uses the child's foods and never repeats the same title twice in a row;
- model metadata records the small mobile model and its commercial-use license;
- widget tests cover home, check-food, roulette, live AI recipe, raw fallback, Quick chef, settings, and 360x640, 640x360, and 1024x1366 layouts at 1.5x text.

## Build for release

The project reads signing details from `android/key.properties`, which is gitignored.

```powershell
Copy-Item android\key.properties.example android\key.properties
# Put your real passwords in key.properties and place upload-keystore.jks in android\app\
flutter build apk --release
flutter build appbundle --release
```

Artifacts:

- `build\app\outputs\flutter-apk\app-release.apk` - universal APK, about 189 MB
- `build\app\outputs\bundle\release\app-release.aab` - Play bundle, about 157 MB

The AI model is not inside either file. The large size comes from the MediaPipe/Flutter AI native libraries for three ABIs. Play delivers only the needed pieces from the AAB. For a smaller direct-install APK, use:

```powershell
flutter build apk --release --split-per-abi
```

See [RELEASE.md](RELEASE.md) for the full checklist, manifest checks, and Play Console steps. See [STORE_LISTING.md](STORE_LISTING.md) for ready-to-paste store text and [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the privacy policy.

## Project layout

```text
lib/
  main.dart                 App start, global error handling, detector startup
  strings.dart              Every word the child sees
  theme.dart                Light and dark Material 3 themes
  data/
    ingredients.dart        Food catalog and COCO name mapping
    recipe.dart             Recipe model
    model_info.dart         AI model name, size, URL, and license
  services/
    detector_service.dart   Load the YOLO model once, detect food, safe boxes
    chef_brain.dart         Download, check, cancel, and delete the AI model
    recipe_generator.dart   Load the model, stream a recipe, stop, release
    recipe_prompt.dart      Prompt builder and lenient plain-text parser
    simple_recipe_generator.dart  Quick chef fallback
  screens/
    splash_screen.dart      In-app loading screen
    home_screen.dart        Step 1: photo and Chef brain banner
    check_food_screen.dart  Step 2: confirm and edit food
    roulette_screen.dart    Step 3a: spin
    recipe_screen.dart      Step 3b: live AI or Quick chef recipe
    model_download_screen.dart  One-time download and progress
    settings_screen.dart    Chef brain status, delete, About
  widgets/                  Reusable buttons, chips, dialogs, photo boxes
assets/models/
  food_detector.tflite      Bundled int8 COCO model (not the AI chef)
test/
  recipe_generator_test.dart  Prompt, parser, Quick chef, model info
  widget_test.dart            Screen layout and flow tests
android/
  app/proguard-rules.pro    Extra R8 rules for YOLO / LiteRT / WorkManager
```

### Prompt and parser

All prompt text lives in `lib/services/recipe_prompt.dart`. If you change the format, update the parser and the parser tests together. The parser must accept at least one numbered step; otherwise the recipe screen shows the model's raw text.

All visible text belongs in `lib/strings.dart`.

## Known limitations

- The AI model is a one-time 521 MiB download. On a slow connection it can take a while, and low-storage phones need free space first.
- The first AI recipe is slower because the model has to load. The app tries GPU first, then CPU. Low-end phones may take longer or fall back to the Quick chef.
- The detector is trained on COCO classes, so it cannot see every fridge item. The hand-add grid is the main fallback.
- Detection works best with good light and an open fridge door. Boxes show only the first box for each food.
- Dark, clear bottles, and some packages may be missed or labeled "Juice or Drink".
- AI recipes are generated, not reviewed one by one. The prompt restricts ingredients and gives safety rules, but a grown-up should still check allergies and cooking steps.
- The universal release APK is about 189 MB because it contains MediaPipe native libraries for `arm64-v8a`, `armeabi-v7a`, and `x86_64`. The AAB is about 157 MB. Use split APKs for smaller test installs.
- The release has been smoke-tested on a Samsung Galaxy Tab S6 Lite (Android 12) for launch, detection, food editing, roulette, recipe, landscape, and 1.5x text. The 521 MB AI download and live MediaPipe generation still need a final test on a real phone.
- The Ultralytics plugin still applies the Kotlin Gradle Plugin, so Flutter prints a future-compatibility warning at build time. Watch the plugin for an update.
- The recipe set is entertainment, not medical or allergy advice. Always check ingredients for allergies.

## Privacy

No personal data is collected. Internet is used only once to download the AI recipe model. Read [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for the full statement. The policy must be hosted at a public URL for Google Play.

## License

This project is released under the **GNU Affero General Public License v3.0**. See [LICENSE](LICENSE).

The bundled Ultralytics YOLO model and the `ultralytics_yolo` plugin are also AGPL-3.0. If you publish a modified version, keep the source available under the same license.

The Qwen2.5 0.5B Instruct model is licensed under **Apache License 2.0**, which allows commercial use. See the model page and license link above. The app downloads the model from Hugging Face; it is not part of this repository or the APK/AAB.

Repository: <https://github.com/SarthakGupta2912/Fridge-Roulette>
