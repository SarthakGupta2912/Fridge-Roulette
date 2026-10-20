# Fridge Roulette - Progress

This file is my checklist. I update it after every phase.

## Phase 1 - Plan
- [x] Read the starting project
- [x] Create PROGRESS.md
- [x] Set up git, .gitignore and remote
- [x] First commit

## Phase 2 - Project setup
- [x] Add ultralytics_yolo and image_picker
- [x] Bundle the offline COCO detector in assets/models (2.86 MB)
- [x] Add theme, strings and app start
- [x] Add navigation between the 3 steps

## Phase 3 - Detection and foods
- [x] Write the ingredient list with emoji (48 foods)
- [x] Write the detector service (load once, predict, timeout)
- [x] Map YOLO class names to foods
- [x] Ignore non-food classes such as cup, bowl, and fork

## Phase 4 - Recipes
- [x] Replace the old static recipe list with on-device AI recipes
- [x] Add the Quick chef fallback (method + flavour + serving idea)
- [x] Keep the last three AI recipe names to avoid repeats
- [x] Write prompt, parser, Quick chef, and model-info tests

## Phase 5 - Screens
- [x] Home screen with Chef brain banner and Settings
- [x] Check food screen with first-recipe download prompt
- [x] Roulette screen
- [x] Live streaming recipe screen with Stop and raw-text fallback
- [x] Model download screen with progress, cancel, storage and Wi-Fi hints
- [x] Settings/About with model status, size, license, and Delete
- [x] Responsive layouts for phone and tablet

## Phase 6 - Friendly errors and edge cases
- [x] Model loading / failed states
- [x] Camera and gallery problems
- [x] Empty detection and fewer than 2 foods
- [x] Double taps, rotation, back button
- [x] Global error handler
- [x] Lost photo recovery
- [x] Add food by hand with no photo
- [x] AI missing / timeout / parse failure / stopped states
- [x] Download no internet, interruption, damage, low storage, cancel

## Phase 7 - Play Store setup
- [x] App id, label and version
- [x] Icon and splash screen
- [x] Adaptive + monochrome launcher icon
- [x] Release signing with ignored key.properties
- [x] R8 and resource shrinking
- [x] INTERNET allowed only for the one-time AI model download
- [x] Remove camera, foreground-service, and background-boot permissions
- [x] minSdk 24, targetSdk 36, compileSdk 36
- [x] Android 12+ splash screen themes

## Phase 8 - Test, build and docs
- [x] flutter analyze clean
- [x] flutter test passing (28 tests)
- [x] Release APK built
- [x] Release AAB built
- [x] Split APKs built for smaller test installs
- [x] Merged manifest checked
- [x] README, RELEASE, STORE_LISTING, PRIVACY_POLICY, and PROGRESS docs updated
- [x] Release APK installed and smoke tested on a real device for the original flow
- [ ] Full 521 MB AI download and live MediaPipe generation tested on a real phone
- [ ] All work committed and pushed

## Current status

| Item | Result |
| --- | --- |
| Flutter / Dart | 3.44.6 / 3.12.2 |
| Analyze | No issues |
| Tests | 28 passed |
| Release APK (universal) | `build/app/outputs/flutter-apk/app-release.apk` (189.2 MB) |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` (157.1 MB) |
| Split APKs | `app-arm64-v8a-release.apk` 93.6 MB, `app-armeabi-v7a-release.apk` 42.4 MB, `app-x86_64-release.apk` 63.8 MB |
| Release permissions | INTERNET (one-time model download), ACCESS_NETWORK_STATE, WAKE_LOCK, private receiver permission |
| Release signer | Upload key shared with invoice_management_system, CN=Sarthak, OU=PathKosh |
| AI model | Qwen2.5 0.5B Instruct, 521 MiB, Apache-2.0, downloaded once, not bundled |
| Device check | Samsung SM-T865, Android 12: launch, detection, spin, recipe, landscape, 1.5x text |

## Decisions I made along the way

- **Detector:** The app bundles the official Ultralytics COCO int8 nano model (`yolo26n_int8.tflite`, 2,859,718 bytes) as `assets/models/food_detector.tflite`. The detector is never downloaded.
- **AI engine:** `flutter_gemma` is discontinued and was replaced with `flutter_edge_ai` 2.4.1 and the MediaPipe engine 1.2.2. MediaPipe keeps Android 7 (`minSdk 24`) support; LiteRT-LM would require API 30 and arm64 only.
- **AI model:** Qwen2.5 0.5B Instruct, 546,660,344 bytes (about 521 MiB), Apache-2.0. It is downloaded once from Hugging Face, stored in app storage, and reused offline. It is never put in the APK/AAB.
- **Model loading:** GPU first, CPU fallback. MediaPipe ignores `maxOutputTokens`, so generation is capped manually at 340 tokens. A 60-second timeout and a Stop button protect the child from a stuck screen.
- **Prompt safety:** Only detected foods plus salt, pepper, oil, water, and sugar. No alcohol. Meat, fish, and eggs must be fully cooked. A grown-up is required for knives, hot pans, ovens, and stoves.
- **Prompt variety:** Random chef style, random fun twist, and the last three recipe names. The fixed plain-text format is TITLE, EMOJI, TIME, LEVEL, STEPS, TIP.
- **Parser:** Lenient about stars, lowercase labels, missing emoji, and a missing STEPS label. It requires at least one numbered step; otherwise the screen shows the raw model text.
- **Quick chef:** A method + flavour + serving idea + detected foods. It never repeats the same title twice in a row and works without any model.
- **Mapping:** COCO `bottle` becomes **Juice or Drink**. Cups, bowls, utensils, people, and appliances are ignored so the food list stays clean.
- **Safety:** Every recipe asks for a grown-up with knives and heat. The generated recipe is entertainment, not medical or allergy advice.
- **UI:** Plain `StatefulWidget` + `setState`, one screen per file, every string in `strings.dart`, and shared widgets in `lib/widgets/`.
- **Layout:** One breakpoint (`600 dp`) for wide layouts. Tests cover 360x640, 640x360, and 1024x1366 at 1.5x text.
- **Icons:** The fridge icon is drawn as a vector for the adaptive/monochrome icon and rendered to PNG for Android 7 devices; no icon-generation package was added.
- **Splash:** A native Android splash plus a short in-app splash while the detector loads; no extra package.
- **Build fix:** Kotlin incremental compilation is disabled because the pub cache is on `C:` and the project is on `D:`, which caused cache-root build failures.
- **Signing:** The upload keystore was replaced with the one from `invoice_management_system` (alias `upload`). `android/key.properties` and the JKS are gitignored and must be backed up; they are not in the repository.
- **Size:** The universal APK is about 189 MB because MediaPipe ships native libraries for three ABIs. The AAB is split by Play. Split APKs are available for smaller test installs.

## Still to do outside the codebase

- [ ] Back up `android/app/upload-keystore.jks` and `android/key.properties`.
- [ ] Test the 521 MB download, AI streaming, Stop, delete, and low-memory behavior on a real phone.
- [ ] Capture phone and tablet screenshots; create a 1024x500 feature graphic and 512x512 store icon.
- [ ] Host PRIVACY_POLICY.md and replace the contact email placeholder.
- [ ] Complete Play Console data safety, content rating, and Families declarations.
- [ ] Upload the AAB to internal testing, then production.
