# Release guide

This checklist takes Fridge Roulette from source to the Google Play Console.

## Build facts

| Item | Value |
| --- | --- |
| Application id | `com.sarthakgupta.fridgeroulette` |
| Version | `1.0.0` (versionCode `1`, from `pubspec.yaml`) |
| Minimum Android | 7.0 / API 24 |
| Target Android | API 36 |
| Compile SDK | 36 |
| NDK | `28.2.13676358` |
| Signing | `android/key.properties` + `android/app/upload-keystore.jks` (both ignored) |
| Minify / shrink | R8 and resource shrinking enabled for release |
| Permissions in release APK | Only the app's own `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` |

The application id and signing key are permanent for this Play listing. Do not change the id after the first upload.

## 1. One-time signing setup

A local upload keystore was created for this build:

- `android/app/upload-keystore.jks`
- `android/key.properties` (contains the random passwords)

Both are gitignored. **Back them up now** in a password manager or encrypted drive. If the upload key is lost, you cannot update the app unless Play App Signing lets you request an upload-key reset.

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

`1.0.1` is the version name shown to users. `+2` is the version code and must be higher than every previous upload.

## 3. Run the checks

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Expected: no formatting changes, no analyzer issues, 25 passing tests.

## 4. Build the artifacts

```powershell
flutter clean
flutter pub get
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Outputs:

| Artifact | Path | Size (v1.0.0) |
| --- | --- | --- |
| Debug APK | `build\app\outputs\flutter-apk\app-debug.apk` | 203.52 MB |
| Release APK (universal) | `build\app\outputs\flutter-apk\app-release.apk` | 74.59 MB |
| Release AAB | `build\app\outputs\bundle\release\app-release.aab` | 64.52 MB |

The debug APK is large because it contains every ABI and no shrinking. Use the universal release APK for direct installs and the AAB for Play.

SHA-256 checksums for this build:

```text
app-release.apk  BB89EE4613C1A46497F6422BD17B8A3CF2CE0F88A85CB407D512F369C102DED0
app-release.aab  A1FF912B889E3CB6C86BB00621873095A582E480B4BCB0CC7C331D89EDA4056C
```

Verified on 20 Oct 2026 on a Samsung Galaxy Tab S6 Lite (SM-T865, Android 12) over wireless ADB: the release APK installs and launches, the model loads, a banana photo is detected and boxed, add-food, the roulette spin, "Banana Shake" and the recipe screen work, and landscape plus 1.5x text render correctly.

If you rebuild, the checksums change. Recompute with:
```powershell
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256
Get-FileHash build\app\outputs\bundle\release\app-release.aab -Algorithm SHA256
```

Optional smaller APKs for testers:

```powershell
flutter build apk --release --split-per-abi
```

Those files land in `build\app\outputs\flutter-apk\` with `arm64-v8a`, `armeabi-v7a`, and `x86_64` suffixes.

## 5. Verify the release

### Signing certificate

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --print-certs build\app\outputs\flutter-apk\app-release.apk
```

(On this machine the SDK is `D:\Android\Sdk`, so use `D:\Android\Sdk\build-tools\36.0.0\apksigner.bat`.)

The DN should be `CN=Fridge Roulette`. The SHA-256 digest for the local upload key is:

```text
7e459aacd83adcd53a2f908c1397ef86dba375c550a2cb68792a758bff512eaf
```

Keep this digest. Play App Signing will show a different app-signing certificate after upload.

### Permissions

```powershell
& "D:\Android\Sdk\build-tools\36.0.0\aapt.exe" dump permissions build\app\outputs\flutter-apk\app-release.apk
```

Expected: only `com.sarthakgupta.fridgeroulette.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. There must be **no** `INTERNET`, `CAMERA`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE*`, or `RECEIVE_BOOT_COMPLETED`.

The manifest uses `tools:node="remove"` for permissions that library dependencies add. The debug and profile manifests still add `INTERNET` so Flutter's hot-reload connection works; that is normal and does not affect the release build.

### R8 keep rules

LiteRT 2.x pulls in Play Asset Delivery, which pulls in WorkManager. WorkManager opens its Room database by name at startup, so `android/app/proguard-rules.pro` keeps `androidx.work.impl.WorkDatabase*`. Without those rules, the release build crashes on launch while the debug build works, with `Failed to create an instance of ...WorkDatabase`. Re-test the release APK whenever dependencies or ProGuard rules change.

### Package details

```powershell
& "D:\Android\Sdk\build-tools\36.0.0\aapt.exe" dump badging build\app\outputs\flutter-apk\app-release.apk
```

Check:

- package name `com.sarthakgupta.fridgeroulette`
- version name `1.0.0`, version code `1`
- `sdkVersion:'24'`, `targetSdkVersion:'36'`
- label `Fridge Roulette`
- `uses-feature-not-required` for camera and autofocus
- native code for `arm64-v8a`, `armeabi-v7a`, `x86_64`

### Install and smoke test

```powershell
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

The AAB cannot be installed directly. Use Play internal testing, or `bundletool build-apks` / `bundletool install-apks`.

Do this on at least one real phone before uploading:

- [ ] First launch shows the native splash, then the in-app splash, then Home.
- [ ] The model reaches the ready state (no sleepy banner).
- [ ] Take a photo of a fridge with a banana, apple, bottle, or other COCO food; boxes appear.
- [ ] Remove a wrong chip; add food by hand; the list updates.
- [ ] Spin with 2 foods; a recipe appears with confetti and haptics.
- [ ] Read a recipe; Spin Again returns to the wheel; New Photo returns to Home.
- [ ] Turn on airplane mode and repeat the whole flow. It must still work.
- [ ] Rotate every screen; no overflow and the layout switches at 600 dp.
- [ ] Set system font size to the largest setting; no clipped text or buttons.
- [ ] Press back on Check Food; the "Leave this page?" dialog appears.
- [ ] Kill the app while the system camera is open; reopen and confirm the lost photo is recovered.
- [ ] Test a fridge photo with no recognizable food; the friendly "I could not see any food" card appears.
- [ ] Test 2 foods that need cooking (for example onion + potato) to see the mix-and-match/no-recipe message.
- [ ] Check TalkBack reads the buttons, chips, steps, and photo description.
- [ ] Check dark mode.

## 6. Upload to Play Console

1. Create the app in Play Console with the name **Fridge Roulette**, default language English (India) or English (US), app, free.
2. Complete **App content**:
   - Privacy policy URL (host `PRIVACY_POLICY.md`; GitHub Pages is enough).
   - Ads: **No ads**.
   - In-app purchases: **No**.
   - Data safety: **No data collected, no data shared**. Photos are processed on-device and are not sent anywhere.
   - Content rating questionnaire: utility/education/reference or game? Choose the category that fits "casual cooking challenge"; answer no to violence, sex, profanity, drugs, gambling, and user-generated content.
   - Target audience: if you select ages 6-12, the app falls under the **Families** policy. It has no ads, no purchases, no data collection, and no external links, so it is a good fit. Complete the Families declaration and confirm the privacy policy.
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

## 7. Store assets still needed

These cannot be generated from code alone:

- [ ] 2-8 phone screenshots (minimum 2), 1080x1920 or similar 9:16.
- [ ] 2-8 tablet screenshots (optional but recommended; the app supports tablets).
- [ ] 1024x500 feature graphic.
- [ ] 512x512 high-resolution icon (the adaptive icon is in the APK, but Play asks for a separate PNG).
- [ ] Short description (80 characters) and full description from `STORE_LISTING.md`.
- [ ] Hosted privacy policy URL.
- [ ] Support email address.

Suggested shot list: Home, detection result with boxes, food chips, spinning wheel, recipe challenge, recipe steps, dark mode, tablet layout.

## 8. After release

- Watch Android vitals for crashes and ANRs.
- Test every model/plugin update on a device before shipping.
- Keep the AGPL source link in the listing or app description if you distribute binaries. The repository is <https://github.com/SarthakGupta2912/Fridge-Roulette>.
- Never commit `key.properties`, the `.jks`, `android/local.properties`, or build outputs.

## Current warnings

- Flutter prints a warning that `ultralytics_yolo` still applies the Kotlin Gradle Plugin. The build succeeds today; upgrade the plugin when it supports Flutter's built-in Kotlin.
- Kotlin incremental compilation is disabled in `android/gradle.properties` because the pub cache and project are on different drives, which otherwise breaks the build with a "different roots" cache error.
