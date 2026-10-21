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
- [x] Write the ingredient list with emoji (96 foods)
- [x] Bundle the COCO detector and the FoodSeg103 segmenter
- [x] Scan one full photo plus nine overlapping close-ups
- [x] Read package labels with bundled on-device ML Kit OCR
- [x] Map COCO and FoodSeg103 class names to foods
- [x] Use per-food thresholds, box sanity filters, a 24-food cap, and progress/Stop
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
- [x] Keep foreground-service and notification permissions only for the one-time model download
- [x] Remove camera and background-boot permissions
- [x] minSdk 24, targetSdk 36, compileSdk 36
- [x] Android 12+ splash screen themes

## Phase 8 - Test, build and docs
- [x] flutter analyze clean
- [x] flutter test passing (60 tests)
- [x] Release APK built (98,774,817 bytes, under 100 MB)
- [x] Release AAB built (160,653,775 bytes)
- [x] Split APKs built for smaller test installs
- [x] Merged manifest checked
- [x] README, RELEASE, STORE_LISTING, PRIVACY_POLICY, and PROGRESS docs updated
- [x] Release APK installed and smoke tested on a real device for the original flow
- [x] Dual-model scan + ML Kit label reader smoke tested on the SM-T865 tablet
- [x] Full 521 MB AI download, progress notification, no-internet card, retry, and live MediaPipe generation tested on the SM-T865 tablet
- [x] In-app notification explanation, Allow/Not now path, and keep-screen-open hint implemented
- [x] Live recipe text cleans literal `\n`, HTML tags, and half-finished model tokens
- [x] 1.0.1+2 APK installed on the SM-T865; delete-and-download re-tested from 0% to 100% with notification and ready screen
- [ ] Low-end phone, TalkBack, Android 13+ permission pop-up, and system-camera path tested
- [ ] All work committed and pushed

## Current status

| Item | Result |
| --- | --- |
| Flutter / Dart | 3.44.6 / 3.12.2 |
| Analyze | No issues |
| Tests | 60 passed |
| Release APK (universal) | `build/app/outputs/flutter-apk/app-release.apk` (98,774,817 bytes / 94.2 MiB) |
| Release AAB | `build/app/outputs/bundle/release/app-release.aab` (160,653,775 bytes / 153.2 MiB) |
| Release permissions | INTERNET (one-time model download), ACCESS_NETWORK_STATE, WAKE_LOCK, FOREGROUND_SERVICE, FOREGROUND_SERVICE_DATA_SYNC, POST_NOTIFICATIONS, private receiver permission |
| Release signer | Upload key shared with invoice_management_system, CN=Sarthak, OU=PathKosh |
| Food models | COCO detector 2.9 MB + FoodSeg103 segmenter 14.6 MB, bundled |
| Package labels | ML Kit Latin OCR, bundled, on-device |
| AI model | Qwen2.5 0.5B Instruct, 521 MiB, Apache-2.0, downloaded once, not bundled |
| Device check | Samsung SM-T865 (Android 12): dual-model scan, OCR, live AI recipe generation, and the 1.0.1+2 delete-and-redownload flow verified end to end (0% to 100%, foreground notification, ready screen, no crash); low-end phone, TalkBack, Android 13+ permission pop-up, Android 14+ foreground-service fix, and system camera still pending |

## Decisions I made along the way

- **Detector:** The app bundles the official Ultralytics COCO int8 nano model (`yolo26n_int8.tflite`, 2,859,718 bytes) as `assets/models/food_detector.tflite` and a FoodSeg103 YOLOv8-seg nano model (14,624,447 bytes, metadata appended) as `assets/models/food_detector_foodseg.tflite`. Neither detector is ever downloaded.
- **Scan strategy:** COCO runs once on the full photo. FoodSeg103 runs on the full photo and on nine overlapping 60% close-ups. ML Kit then reads package labels once. Results are merged to the best box per food, thin/tiny boxes are dropped, and the list is capped at 24. This is slower (up to two minutes) but much better for small and packaged foods.
- **Label reader:** `google_mlkit_text_recognition` 0.17.1 with the bundled Latin model. It maps brands and English/French food words to catalog ids. It is fully on-device and adds no network permission beyond the existing model download.
- **Confidence:** Per-class thresholds are 0.08 for milk, cheese/butter, eggs, and bread, and 0.22 for everything else. Low-confidence boxes are still filtered by size and aspect ratio.
- **AI engine:** `flutter_gemma` is discontinued and was replaced with `flutter_edge_ai` 2.4.1 and the MediaPipe engine 1.2.2. MediaPipe keeps Android 7 (`minSdk 24`) support; LiteRT-LM would require API 30 and arm64 only.
- **AI model:** Qwen2.5 0.5B Instruct, 546,660,344 bytes (about 521 MiB), Apache-2.0. It is downloaded once from Hugging Face, stored in app storage, and reused offline. It is never put in the APK/AAB.
- **Model loading:** CPU first, GPU fallback. The test tablet's GPU path started but returned broken tokens, so the CPU is the safe default. The prompt is wrapped in Qwen ChatML markers and decoded greedily; MediaPipe ignores `maxOutputTokens`, so generation is capped manually at 340 tokens. A 60-second timeout and a Stop button protect the child from a stuck screen.
- **Prompt safety:** Only detected foods plus salt, pepper, oil, water, and sugar. No alcohol. Meat, fish, and eggs must be fully cooked. A grown-up is required for knives, hot pans, ovens, and stoves.
- **Prompt variety:** Random chef style, random fun twist, and the last three recipe names. The fixed plain-text format is TITLE, EMOJI, TIME, LEVEL, STEPS, TIP.
- **Parser:** Lenient about stars, lowercase labels, missing emoji, a missing STEPS label, literal `\n` text, HTML tags, and a repeated word in the title. The live streaming text uses the same cleaner so the child never sees escape codes or half-finished tags while the chef writes. It requires at least one numbered step; otherwise the screen shows the raw model text. If the AI mentions a food that was not detected, the screen uses the Quick chef instead.
- **Quick chef:** A method + flavour + serving idea + detected foods. It never repeats the same title twice in a row and works without any model.
- **Download:** A DNS preflight gives an instant no-internet card, the plugin retries only 3 times, and the transfer runs in a foreground service with a progress notification. The manifest declares WorkManager's `SystemForegroundService` with `foregroundServiceType="dataSync"`, which Android 14+ requires; without it the app closes as soon as the notification starts. A 60-second first-progress guard plus a 30-second engine startup guard turn a silent worker into a friendly error with a working **Try again** button. On Android 13+ the app explains notification permission before starting, then shows Android's pop-up; Allow uses the foreground notification, Not now downloads without one and shows a keep-screen-open hint. This avoids the downloader making a hidden permission request in the middle of "starting".
- **Mapping:** COCO `bottle` becomes **Juice or Drink**. Cups, bowls, utensils, people, and appliances are ignored so the food list stays clean.
- **Safety:** Every recipe asks for a grown-up with knives and heat. The generated recipe is entertainment, not medical or allergy advice.
- **UI:** Plain `StatefulWidget` + `setState`, one screen per file, every string in `strings.dart`, and shared widgets in `lib/widgets/`.
- **Layout:** One breakpoint (`600 dp`) for wide layouts. Tests cover 360x640, 640x360, and 1024x1366 at 1.5x text.
- **Icons:** The fridge icon is drawn as a vector for the adaptive/monochrome icon and rendered to PNG for Android 7 devices; no icon-generation package was added.
- **Splash:** A native Android splash plus a short in-app splash while the detector loads; no extra package.
- **Build fix:** Kotlin incremental compilation is disabled because the pub cache is on `C:` and the project is on `D:`, which caused cache-root build failures.
- **Signing:** The upload keystore was replaced with the one from `invoice_management_system` (alias `upload`). `android/key.properties` and the JKS are gitignored and must be backed up; they are not in the repository.
- **Size:** The universal APK is 98,774,817 bytes (94.2 MiB). Native libraries are stored compressed, and three unused MediaPipe image-generator libraries are excluded. The AAB is 160,653,775 bytes and Play splits it by device. Split APKs are available for smaller test installs. The APK is under 100 MB but has little room for another model.
- **R8:** ML Kit's plugin mentions optional Chinese, Devanagari, Japanese, and Korean recognizers that are not bundled. `proguard-rules.pro` suppresses those missing-class warnings and keeps Kotlin coroutine/Result classes, the downloader, and the ML Kit registrars that JNI and manifest metadata load by name. Only Latin OCR ships.

## Still to do outside the codebase

- [ ] Back up `android/app/upload-keystore.jks` and `android/key.properties`.
- [ ] Test a low-end phone, TalkBack, the system-camera path, and a real low-storage download.
- [ ] Test the Android 13+ notification explanation and system permission pop-up on a real phone.
- [ ] Test the AI Stop button, delete, and low-memory behavior on a phone.
- [ ] Capture phone and tablet screenshots; create a 1024x500 feature graphic and 512x512 store icon.
- [ ] Host PRIVACY_POLICY.md and replace the contact email placeholder.
- [ ] Complete Play Console data safety, content rating, and Families declarations.
- [ ] Upload the AAB to internal testing, then production.
