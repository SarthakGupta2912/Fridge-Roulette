# Fridge Roulette - Progress

This file is my checklist. I update it after every phase.

## Phase 1 - Plan
- [x] Read the starting project
- [x] Create PROGRESS.md
- [x] Set up git, .gitignore and remote
- [x] First commit

## Phase 2 - Project setup
- [x] Add ultralytics_yolo 0.5.1 and image_picker 1.2.4
- [x] Bundle the offline COCO model in assets/models (2.86 MB)
- [x] Add theme, strings and app start
- [x] Add navigation between the 3 steps

## Phase 3 - Detection and foods
- [x] Write the ingredient list with emoji (48 foods)
- [x] Write the detector service (load once, predict, timeout)
- [x] Map YOLO class names to foods
- [x] Ignore non-food classes such as cup, bowl, and fork

## Phase 4 - Recipes
- [x] Add 60+ recipes (70 total)
- [x] Write the recipe picker (match, no repeat, fallback)
- [x] Write unit tests for the picker

## Phase 5 - Screens
- [x] Home screen
- [x] Check food screen
- [x] Roulette screen
- [x] Recipe screen
- [x] Responsive layouts for phone and tablet

## Phase 6 - Friendly errors and edge cases
- [x] Model loading / failed states
- [x] Camera and gallery problems
- [x] Empty detection and fewer than 2 foods
- [x] Double taps, rotation, back button
- [x] Global error handler
- [x] Lost photo recovery
- [x] Add food by hand with no photo
- [x] Mix-and-match snack fallback and no-recipe message

## Phase 7 - Play Store setup
- [x] App id, label and version
- [x] Icon and splash screen
- [x] Adaptive + monochrome launcher icon
- [x] Release signing with ignored key.properties
- [x] R8 and resource shrinking
- [x] Remove INTERNET permission
- [x] Remove camera and unused library permissions
- [x] minSdk 24, targetSdk 36, compileSdk 36
- [x] Android 12+ splash screen themes

## Phase 8 - Test, build and docs
- [x] flutter analyze clean
- [x] flutter test passing (25 tests)
- [x] Debug APK built
- [x] Release APK built
- [x] Release AAB built
- [x] Merged manifest checked
- [x] README, RELEASE, STORE_LISTING and PRIVACY_POLICY docs
- [x] Release APK installed and smoke tested on a real device
- [x] All work committed and pushed

## Current status

| Item | Result |
| --- | --- |
| Flutter / Dart | 3.44.6 / 3.12.2 |
| Analyze | No issues |
| Tests | 25 passed |
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` (203.52 MB) |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` (74.59 MB) |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` (64.52 MB) |
| Release permissions | No INTERNET, CAMERA, network state, or background permissions |
| Release signer | Upload key shared with invoice_management_system, CN=Sarthak, OU=PathKosh |
| Device check | Samsung SM-T865, Android 12: launch, detection, spin, recipe, landscape, 1.5x text |

## Decisions I made along the way

- **Model:** The app bundles the official Ultralytics COCO int8 nano model (`yolo26n_int8.tflite`, 2,859,718 bytes) as `assets/models/food_detector.tflite`. Python LiteRT export is not supported on this Windows machine, so the official release asset is the offline substitute. The app never downloads a model.
- **Mapping:** COCO `bottle` becomes **Juice or Drink**. Cups, bowls, utensils, people, and appliances are ignored so the food list stays clean.
- **Fallback:** If no full recipe matches, the picker makes a two-food snack only from ingredients marked `isSnackSafe`. If fewer than two safe foods exist, it returns null and the app shows a friendly message.
- **Safety:** Recipes assume salt, pepper, oil, water, and sugar. Every recipe asks for a grown-up with knives and heat.
- **Recipes:** Split across `recipes_a.dart`, `recipes_b.dart`, and `recipes_c.dart` so each file stays readable.
- **UI:** Plain `StatefulWidget` + `setState`, one screen per file, every string in `strings.dart`, and shared widgets in `lib/widgets/`.
- **Layout:** One breakpoint (`600 dp`) for wide layouts. Tests cover 360x640, 640x360, and 1024x1366 at 1.5x text.
- **Icons:** The fridge icon is drawn as a vector for the adaptive/monochrome icon and rendered to PNG for Android 7 devices; no icon-generation package was added.
- **Splash:** A native Android splash plus a short in-app splash while the model loads; no extra package.
- **Build fix:** Kotlin incremental compilation is disabled because the pub cache is on `C:` and the project is on `D:`, which caused cache-root build failures.
- **Signing:** The upload keystore was replaced with the one from `invoice_management_system` (alias `upload`). `android/key.properties` and the JKS are gitignored and must be backed up; they are not in the repository.

## Still to do outside the codebase

- [ ] Back up `android/app/upload-keystore.jks` and `android/key.properties`.
- [ ] Run the release build on a real phone and repeat the smoke test in RELEASE.md.
- [ ] Capture phone and tablet screenshots; create a 1024x500 feature graphic and 512x512 store icon.
- [ ] Host PRIVACY_POLICY.md and replace the contact email placeholder.
- [ ] Complete Play Console data safety, content rating, and Families declarations.
- [ ] Upload the AAB to internal testing, then production.
