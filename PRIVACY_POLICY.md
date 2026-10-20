# Privacy Policy for Fridge Roulette

**Effective date:** 20 October 2026

Fridge Roulette is a cooking game for children and families. This policy explains, in plain language, what the app does with information.

## The short version

- We do not collect personal information.
- We do not have a server for your photos, food lists, or recipes.
- Photos, food lists, and recipes stay on your device.
- The internet is used only once, to download the AI recipe model.
- There are no accounts, ads, analytics, or tracking tools.
- The app is free and has no in-app purchases.

**No personal data is collected. Internet is used only once to download the AI recipe model.**

## What the app uses

### Camera and photos

When you tap **Take a Photo** or **Pick from gallery**, the app opens your phone's camera app or photo picker. The picture you choose is read by the app and used only to look for food on your device. The app does not request the Android camera permission; the system camera app handles the picture.

Photos are kept in the app's temporary memory while you play. The app does not upload them, share them, or save them to a gallery. Closing the screen or the app discards them. Android may keep a temporary copy while the camera app is open so the photo can be recovered if the phone closes the app; that copy is managed by the `image_picker` plugin and stays in the app's private storage.

### Food list and recipes

The food you confirm or add is used only to write a recipe during the current session. It is not stored after you leave the screen and is never sent to us. The AI prompt is built on the phone. The generated recipe also stays on the phone.

### On-device food detection

The app includes two YOLO food models (a COCO detector and a FoodSeg103 segmenter) and ML Kit's Latin text recognizer in its own files. All detection and package-label reading happen on your device using the phone's processor. The OCR model is bundled, so label text is not sent to Google or any other company. No image or result is sent to Ultralytics, Google, or any other company.

### On-device AI recipe writing

The AI chef is a small language model called Qwen2.5 0.5B Instruct. It is not bundled with the app. When you ask for the AI chef, the app downloads the model file once and stores it in the app's private storage. The model then runs entirely on your phone. The foods, prompt, and generated recipe are not sent anywhere.

You can delete the model at any time from **Settings > Chef brain > Delete chef brain**, or by clearing the app's storage or uninstalling the app.

### Internet

The app uses the internet for one purpose only: downloading the AI recipe model from Hugging Face at `huggingface.co`. The request contains the model file address and standard connection information such as an IP address and user agent. It does not contain your name, account, photo, food list, recipe, or any app usage data. Hugging Face processes that standard connection information under its own privacy policy.

After the model is downloaded, the app does not need the internet. It works in airplane mode. If you skip or cancel the download, the app still works with the Quick chef.

There are no analytics, advertising, crash-reporting, or other background network requests.

## What we do not collect

We do not collect, request, or share:

- names, email addresses, phone numbers, or accounts;
- precise or approximate location;
- contacts, calendar, messages, or files;
- photos or videos;
- health, financial, or payment information;
- device identifiers or advertising IDs;
- app usage, searches, or crash reports;
- any data through cookies, SDKs, ads, or analytics.

The app contains no advertising SDK, no social media SDK, and no crash-reporting service.

## Children's privacy

Fridge Roulette is made for families and can be used by children. Because the app collects no personal information and has no account, it does not knowingly collect personal information from children. Parents and guardians can let children use the app without creating an account or sharing data. A grown-up can skip the one-time model download and let the child use the Quick chef.

The app shows cooking steps and a safety reminder to ask a grown-up for help with knives and hot things. It does not contain chat, user-generated content, external links, or purchases.

## Permissions

The release app declares these Android permissions:

- **INTERNET** - used only to download the AI recipe model.
- **ACCESS_NETWORK_STATE** - lets the downloader notice when the connection is lost.
- **WAKE_LOCK** - lets the phone keep working while the one-time download finishes.

It does not ask for camera, location, storage, microphone, notifications, or foreground-service access. The app also declares a private Android permission that the AndroidX library uses to protect its own broadcast receivers; it does not give access to user data.

## Third-party components

The app uses open-source packages, including:

- Flutter and Material Components (Google);
- `ultralytics_yolo` and the bundled Ultralytics YOLO model;
- `image_picker` (Flutter team);
- `flutter_edge_ai` and `flutter_edge_ai_mediapipe` (on-device AI runtime);
- the Qwen2.5 0.5B Instruct model (Apache License 2.0);
- LiteRT / MediaPipe runtime libraries.

The model file is downloaded from Hugging Face. These packages run inside the app. Their own licenses and privacy terms may apply to their source code. The app does not send them your photos, food list, or recipes.

## Data retention and deletion

We retain no data on a server. Photos and food lists exist only in memory during the current screen and are discarded when you leave it. The downloaded AI model stays in the app's private storage until you delete it.

You can delete the model in **Settings > Chef brain > Delete chef brain**. You can also clear the app's storage in Android Settings or uninstall the app. Because no personal data is sent to us, there is nothing for us to delete on a server.

## Changes to this policy

If a future version adds a feature that changes these practices, this policy will be updated before that version is released, and the effective date will change. The latest version will be available at the public privacy-policy URL listed on Google Play.

## Contact

Fridge Roulette is developed by Sarthak Gupta.

- Email: `<your-support-email@example.com>`
- Source code: <https://github.com/SarthakGupta2912/Fridge-Roulette>

If you are a parent or guardian and have a question about the app, please use the email above.

---

**Hosting note for the developer:** Google Play requires a public URL. Publish this file with GitHub Pages, Notion, or any static host, replace the contact placeholder, and paste the URL into Play Console and `STORE_LISTING.md`.
