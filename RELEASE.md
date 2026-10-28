# Release guide

This checklist takes Fridge Roulette from source to the Google Play Console.

## Build facts

| Item | Value |
| --- | --- |
| Application id | `com.sarthakgupta.fridgeroulette` |
| Version | `1.0.1` (versionCode `2`, from `pubspec.yaml`) |
| Minimum Android | 7.0 / API 24 |
| Target Android | API 36 |
| Compile SDK | 36 |
| NDK | `28.2.13676358` |
| Signing | `android/key.properties` + `android/app/upload-keystore.jks` (both ignored) |
| Minify / shrink | R8 and resource shrinking enabled for release |
| Runtime permissions | `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, `POST_NOTIFICATIONS`, plus the app's private dynamic-receiver permission |
| Food models | COCO detector (2.9 MB) + FoodSeg103 segmenter (14.6 MB), both bundled |
| Package labels | ML Kit Latin OCR, bundled, on-device |
| AI model | Qwen2.5 0.5B Instruct, about 521 MiB, downloaded once, not bundled |
| Model license | Apache License 2.0 |

The application id is permanent after the first upload. Lock in the signing key before the first Play upload; after that, keep the same key for every update.

## 1. One-time signing setup

This project uses the upload keystore copied from the `invoice_management_system` project:

- `android/app/upload-keystore.jks` (alias `upload`, owner `CN=Sarthak, OU=PathKosh`)
- `android/key.properties` (contains the matching passwords)

Both are gitignored. **Back them up now** in a password manager or encrypted drive. If the upload key is lost, you cannot update the app unless Play App Signing lets you request an upload-key reset. The certificate SHA-256 digest is documented in section 5.

To use your own key instead:

```powershell
keytool -genkeypair -v `
  -keystore android\app\upload-keystore.jks `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storepass "YOUR_STORE_PASSWORD" -keypass "YOUR_KEY_PASSWORD" `
  -dname "CN=Fridge Roulette, OU=Mobile, O=Your Name, L=City, ST=State, C=IN"
```

Then copy `android/key.properties.example` to `android/key.properties` and fill in the same values. `storeFile` is relative to `android/app/`.

If `key.properties` is missing, the Gradle file falls back to the debug key so CI and new contributors can still build. A debug-signed release is **not** suitable for Play.

## 2. Version bump for every upload

Update the version in `pubspec.yaml`:

```yaml
version: 1.0.1+2
```

`1.0.1` is the version name shown to users. `+2` is the version code and must be higher than every previous upload. If this is truly the first Play upload, `1.0.0+1` is fine. Also update `AppStrings.appVersion` in `lib/strings.dart`.

## 3. Run the checks

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: no formatting changes, no analyzer issues, 60 passing tests.

## 4. Build the artifacts

```powershell
flutter clean
flutter pub get
flutter build apk --release

# Flutter's `build appbundle` post-check expects native .sym files. The release
# config deliberately leaves them out, so build the signed AAB with Gradle.
cd android
.\gradlew.bat bundleRelease
cd ..
```

Optional smaller test APKs:

```powershell
flutter build apk --release --split-per-abi
```

Outputs:

| Artifact | Path | Size (current build) |
| --- | --- | --- |
| Release APK (universal) | `build\app\outputs\flutter-apk\app-release.apk` | 70,174,290 bytes (66.9 MiB) |
| Release AAB | `build\app\outputs\bundle\release\app-release.aab` | 70,875,699 bytes (67.6 MiB) |

The AI recipe model is **not** in either file. The size comes from the MediaPipe/Flutter AI native libraries for `arm64-v8a` and `armeabi-v7a`, the two bundled food models, and ML Kit's bundled Latin OCR model. The AAB lets Play deliver only the needed pieces. The universal APK contains both ARM ABIs and is below the 90 MB target.

The `x86_64` libraries are excluded because they are only useful for desktop emulators and were the largest ABI. Native debug symbols are also excluded; upload them separately to Play only if native crash symbolication is needed. Both 64-bit and 32-bit ARM phones and tablets remain supported.

SHA-256 checksums for this build:

```text
app-release.apk  B68C0760AA4D0C7FE26FDD9C4CB9A59BA5077514BD0166044AB1F129B6D77045
app-release.aab  74CAFEC64AB81A4DE279C2E0DA4F8A0914A0A6BC50B664883F0124C18707E4C5
```

If you rebuild, the checksums change. Recompute with:

```powershell
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

## 5. Verify the release

### Signing certificate

```powershell
& "D:\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

The DN should be `CN=Sarthak, OU=PathKosh, O=Sarthak, L=Panchkula, ST=Haryana, C=IN`. The SHA-256 digest for the local upload key is:

```text
2b1ed35bb5137fd0b5dbecb3a43615a6ec61b4570111b16c7ea76d5ff05b79d9
```

Keep this digest. Play App Signing will show a different app-signing certificate after upload.

### Permissions

```powershell
& "D:\Android\Sdk\build-tools\36.0.0\aapt.exe" dump permissions build\app\outputs\flutter-apk\app-release.apk
```

Expected:

```text
android.permission.INTERNET
android.permission.FOREGROUND_SERVICE
android.permission.FOREGROUND_SERVICE_DATA_SYNC
android.permission.POST_NOTIFICATIONS
android.permission.WAKE_LOCK
android.permission.ACCESS_NETWORK_STATE
com.sarthakgupta.fridgeroulette.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

There must be **no** `CAMERA`, location, storage, microphone, or `RECEIVE_BOOT_COMPLETED` permission. `INTERNET` is used only for the one-time AI model download. `ACCESS_NETWORK_STATE` and `WAKE_LOCK` support that download. `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_DATA_SYNC` keep the download alive while the child leaves the app, and `POST_NOTIFICATIONS` shows the progress notification on Android 13+. The app shows its own explanation before Android's permission pop-up, and only starts the transfer after the child chooses Allow or Not now. The notification is local, contains no personal data, and is optional; denying it does not stop the download, but the download screen then tells the child to keep the app open.

The manifest uses `tools:node="remove"` for camera and boot permissions that libraries add. It also declares `androidx.work.impl.foreground.SystemForegroundService` with `android:foregroundServiceType="dataSync"`. Android 14 and newer throw a `MissingForegroundServiceTypeException` and close the app when WorkManager starts the download notification without that declaration. Keep this service entry when changing download packages. The debug and profile manifests still add `INTERNET` so Flutter's hot-reload connection works; that is normal and does not affect the release build.

### R8 keep rules

LiteRT and MediaPipe run model methods through JNI and reflection. WorkManager opens its Room database by name at startup, and the JNI bridge loads Kotlin coroutine and `Result` classes by their original names. `android/app/proguard-rules.pro` keeps the YOLO, LiteRT, MediaPipe, Room, WorkManager, SnakeYAML, Kotlin coroutine/Result/Unit, shared-preferences/path-provider, and `background_downloader` classes. It also keeps the ML Kit component registrars that are discovered from manifest metadata, and suppresses R8 warnings for the Chinese, Devanagari, Japanese, and Korean OCR options that are not bundled; only the Latin recognizer is used. Without these rules, the release build fails at `minifyReleaseWithR8` or crashes at startup. Re-test the release APK whenever dependencies or ProGuard rules change.

### Package details

```powershell
& "D:\Android\Sdk\build-tools\36.0.0\aapt.exe" dump badging build\app\outputs\flutter-apk\app-release.apk
```

Check:

- package name `com.sarthakgupta.fridgeroulette`
- version name `1.0.1`, version code `2`
- `sdkVersion:'24'`, `targetSdkVersion:'36'`
- label `Fridge Roulette`
- `uses-feature-not-required` for camera and autofocus
- native code for `arm64-v8a` and `armeabi-v7a` (no `x86_64`)

### Install and smoke test

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

The AAB cannot be installed directly. Use Play internal testing, or `bundletool build-apks` / `bundletool install-apks`.

Do this on at least one real phone before uploading:

- [ ] First launch shows the native splash, then the in-app splash, then Home.
- [ ] Both YOLO models load and the detector reaches the ready state (no sleepy banner).
- [ ] Take a photo of a fridge with a banana, apple, bottle, or other COCO food; boxes appear.
- [ ] Take a photo with milk, eggs, bread, cheese, or a labelled package; the FoodSeg103 model and the label reader find it.
- [ ] Watch the scan progress bar and step counter; a full scan may take up to two minutes. Tap **Stop** once and confirm the scan ends without an error card.
- [ ] Remove a wrong chip; add food by hand; the list updates.
- [ ] Spin with 2 foods; the roulette opens the recipe screen.
- [ ] First recipe request offers the chef-brain download, with the size, license, storage warning, and Wi-Fi hint.
- [ ] Cancel the download; the Quick chef recipe still appears and the app stays usable.
- [ ] Download the 521 MiB model on Wi-Fi; percent and MB update; the screen survives rotation and a pause.
- [ ] A foreground notification shows the model name and a moving progress bar; it disappears when the download finishes.
- [ ] On Android 13+, tap Download and confirm the app first explains the notification permission in its own dialog, then Android's pop-up appears. Tapping Allow should start the download without a long "starting" wait.
- [ ] On Android 14 or newer, tap Allow and confirm the app stays open, the progress notification appears, and the percent starts moving. This checks the `dataSync` foreground-service declaration.
- [ ] On Android 13+, choose Not now (or deny the system permission); the download still starts, shows the keep-this-screen-open hint, and finishes while the screen stays open.
- [ ] Block the network before tapping Download; the No internet card appears quickly instead of an endless "starting" spinner; restore the network and confirm Try again resumes.
- [ ] Interrupt the download (airplane mode) after it starts; the downloader waits or reports a friendly error, and Try Again works. A server error is covered by the unit tests.
- [ ] Let the AI chef write a recipe; text appears word by word; the AI chef badge is visible; the live text contains real line breaks and no literal `\n`, `<br>`, or other HTML tags.
- [ ] Tap **Stop**; the partial raw text or a friendly stopped card appears.
- [ ] Test a second AI recipe with the same foods; the title and idea should differ.
- [ ] Tap **Make another one** and **Change foods**.
- [ ] Open Settings; confirm the model is listed as downloaded with its size and license; delete it and confirm the space is freed.
- [ ] After the model is deleted, a recipe uses the Quick chef badge and the Get the AI chef action.
- [ ] Put the app in the background during a recipe, wait, then return; the model is released safely.
- [ ] Turn on airplane mode after the model is downloaded and repeat the whole flow. It must still work.
- [ ] Rotate every screen; no overflow and the layout switches at 600 dp.
- [ ] Set system font size to the largest setting; no clipped text or buttons.
- [ ] Press back on Check Food; the "Leave this page?" dialog appears.
- [ ] Kill the app while the system camera is open; reopen and confirm the lost photo is recovered.
- [ ] Test a fridge photo with no recognizable food; the friendly "I could not see any food" card appears.
- [ ] Check TalkBack reads the buttons, chips, steps, badges, download progress, and photo description.
- [ ] Check dark mode.

## 6. Upload to Play Console

1. Create the app in Play Console with the name **Fridge Roulette**, default language English (India) or English (US), app, free.
2. Complete **App content**:
   - Privacy policy URL (host `PRIVACY_POLICY.md`; GitHub Pages is enough).
   - Ads: **No ads**.
   - In-app purchases: **No**.
   - Data safety: **No personal data collected, no data shared**. Internet is used only once to download the AI recipe model. Photos and food lists are processed on-device and are not sent anywhere.
   - Content rating questionnaire: choose the category that fits "casual cooking challenge"; answer no to violence, sex, profanity, drugs, gambling, and user-generated content.
   - Target audience: if you select ages 6-12, the app falls under the **Families** policy. It has no ads, no purchases, no personal data collection, and no external links, so it is a good fit. Complete the Families declaration and confirm the privacy policy.
   - News app: no.
   - COVID-19 apps: no.
   - Government app: no.
   - Financial features: no.
   - Health features: no.
3. Upload `app-release.aab` under **Testing > Internal testing** first.
4. Add yourself and one or two testers, install from the opt-in link, and run the smoke test above.
5. Promote to **Closed testing** if needed, then **Production**.
6. Complete the store listing with the text and graphics from [STORE_LISTING.md](STORE_LISTING.md).
7. Set the countries/regions, pricing (free), and content declarations.
8. Submit for review.

### Play App Signing

The first upload can register the local upload key. Let Play generate and manage the app-signing key. Keep the upload keystore safe: every future AAB must be signed with it.

**The signing key changed.** Earlier local artifacts were signed with a different key. This AAB is signed with the PathKosh key documented above. If an AAB was not yet uploaded, this is fine: upload this one and register the new key. If a build was already uploaded under the old key, Play will reject this AAB; request an upload-key reset in Play Console, or rebuild with the old key. Do not mix AABs signed by different keys.

## 7. Store assets still needed

These cannot be generated from code alone:

- [ ] 2-8 phone screenshots (minimum 2), 1080x1920 or similar 9:16.
- [ ] 2-8 tablet screenshots (optional but recommended; the app supports tablets).
- [ ] 1024x500 feature graphic.
- [ ] 512x512 high-resolution icon (the adaptive icon is in the APK, but Play asks for a separate PNG).
- [ ] Short description (80 characters) and full description from `STORE_LISTING.md`.
- [ ] Hosted privacy policy URL.
- [ ] Support email address.

Suggested shot list: Home, detection result with boxes, food chips, spinning wheel, download progress, live AI recipe, recipe steps, dark mode, tablet layout.

## 8. After release

- Watch Android vitals for crashes and ANRs.
- Test every model/plugin update on a device before shipping.
- Keep the AGPL source link in the listing or app description if you distribute binaries. The repository is <https://github.com/SarthakGupta2912/Fridge-Roulette>.
- Never commit `key.properties`, the `.jks`, `android/local.properties`, or build outputs.

## Current warnings

- Flutter prints a warning that `ultralytics_yolo` still applies the Kotlin Gradle Plugin. The build succeeds today; upgrade the plugin when it supports Flutter's built-in Kotlin.
- Kotlin incremental compilation is disabled in `android/gradle.properties` because the pub cache and project are on different drives, which otherwise breaks the build with a "different roots" cache error.
- The universal APK is 70,174,290 bytes (66.9 MiB) and the AAB is 70,875,699 bytes (67.6 MiB). Both are below the 90 MB target. `x86_64` emulator/Chromebook support and native debug symbols were removed to reach this size; keep an ARM device for release smoke tests.
- `flutter build appbundle --release` stops after Gradle with "failed to strip debug symbols" because Flutter expects `.sym` files, while the release config deliberately sets `debugSymbolLevel = "none"`. The signed AAB is already produced; use `cd android` and `.\gradlew.bat bundleRelease`. Re-enabling full symbols would add about 65 MB and push the AAB over 90 MB.
- ML Kit OCR is bundled for Latin script only. The other script options are referenced by the plugin but intentionally not shipped; the ProGuard rules suppress their missing-class warnings.
- The dual-model scan, label reader, 521 MiB download, foreground notification, in-app notification explanation, no-internet card, retry, live MediaPipe generation, and plain-text streaming cleanup were verified on a Samsung SM-T865 tablet. The 1.0.1+2 delete-and-redownload flow was re-tested end to end on that tablet: 0% to 100%, progress notification, ready screen, and no crash. The tablet runs Android 12, so the Android 13+ system permission pop-up and the Android 14+ foreground-service declaration still need a newer phone. Still needed before publishing: a low-end phone, TalkBack, the system-camera path, and a real low-storage test. The AI recipe generator was switched to CPU-first because the GPU path returned broken tokens on the test tablet.
