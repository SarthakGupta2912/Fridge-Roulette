# Privacy Policy for Fridge Roulette

**Effective date:** 20 October 2026

Fridge Roulette is an offline cooking game for children and families. This policy explains, in plain language, what the app does with information.

## The short version

- We do not collect personal information.
- We do not have a server and the app has no internet permission.
- Photos and food lists stay on your device.
- There are no accounts, ads, analytics, or tracking tools.
- The app is free and has no in-app purchases.

## What the app uses

### Camera and photos

When you tap **Take a Photo** or **Pick from gallery**, the app opens your phone's camera app or photo picker. The picture you choose is read by the app and used only to look for food on your device. The app does not request the Android camera permission; the system camera app handles the picture.

Photos are kept in the app's temporary memory while you play. The app does not upload them, share them, or save them to a gallery. Closing the screen or the app discards them. Android may keep a temporary copy while the camera app is open so the photo can be recovered if the phone closes the app; that copy is managed by the `image_picker` plugin and stays in the app's private storage.

### Food list and recipes

The food you confirm or add is used only to choose a recipe during the current session. It is not stored after you leave the screen and is never sent anywhere.

### On-device food detection

The app includes a YOLO object-detection model in its own files. All detection happens on your device using the phone's processor or GPU. No image or result is sent to Ultralytics, Google, or any other company.

### Internet

The release version of Fridge Roulette has **no INTERNET permission**. It cannot make network connections, even if the phone is online. The app works in airplane mode.

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

Fridge Roulette is made for families and can be used by children. Because the app collects no personal information and has no network access, it does not knowingly collect personal information from children. Parents and guardians can let children use the app without creating an account or sharing data.

The app shows cooking steps and a safety reminder to ask a grown-up for help with knives and hot things. It does not contain chat, user-generated content, external links, or purchases.

## Permissions

The release app declares no sensitive Android permissions. It does not ask for internet, camera, location, storage, microphone, notifications, or background-work access. The only manifest entry is a private Android permission that the AndroidX library uses to protect its own broadcast receivers; it does not give access to user data.

## Third-party components

The app uses open-source packages, including:

- Flutter and Material Components (Google);
- `ultralytics_yolo` and the bundled Ultralytics YOLO model;
- `image_picker` (Flutter team);
- LiteRT / TensorFlow Lite runtime libraries.

These packages run inside the app. The app does not send them any data over a network. Their own licenses and privacy terms may apply to the source code, but no data is transmitted by this app.

## Data retention and deletion

We retain no data. Photos and food lists exist only in memory during the current screen and are discarded when you leave it. Because no data is sent to us, there is nothing for us to delete on a server.

You can clear any temporary files by clearing the app's storage in Android Settings or by uninstalling the app.

## Changes to this policy

If a future version adds a feature that changes these practices, this policy will be updated before that version is released, and the effective date will change. The latest version will be available at the public privacy-policy URL listed on Google Play.

## Contact

Fridge Roulette is developed by Sarthak Gupta.

- Email: `<your-support-email@example.com>`
- Source code: <https://github.com/SarthakGupta2912/Fridge-Roulette>

If you are a parent or guardian and have a question about the app, please use the email above.

---

**Hosting note for the developer:** Google Play requires a public URL. Publish this file with GitHub Pages, Notion, or any static host, replace the contact placeholder, and paste the URL into Play Console and `STORE_LISTING.md`.
