# Google Play store listing

Ready-to-paste text for Fridge Roulette. Replace the placeholders in angle brackets before submitting.

## App identity

| Field | Value |
| --- | --- |
| App name | Fridge Roulette |
| Package | `com.sarthakgupta.fridgeroulette` |
| Category | Education (alternative: Entertainment) |
| Tags | Cooking, Kids, Recipes, Food, Family |
| Pricing | Free |
| Ads | No |
| In-app purchases | No |
| Default language | English (India) or English (US) |
| Contact email | `<your-support-email@example.com>` |
| Privacy policy | `<https://your-domain.example/privacy-policy>` |
| Website | `https://github.com/SarthakGupta2912/Fridge-Roulette` |

## Short description (80 characters max)

```text
Snap your fridge, spin the wheel, and get a kid-friendly recipe!
```

Character count: 64.

## Full description

```text
What is in your fridge? Turn one photo into a fun cooking challenge!

Fridge Roulette is a playful cooking game for kids and families. Take a photo of your fridge, and the app finds the food right on your phone. Spin the wheel and the AI chef writes a brand-new recipe from what you already have. No account. No ads. No tracking.

HOW IT WORKS
1. Snap a photo of your fridge or pick one from your gallery.
2. Check the food list. Tap a food to remove it, or add anything the app missed.
3. Spin the wheel and watch the chef write a recipe just for you!

A FRESH RECIPE EVERY TIME
The AI chef is a small language model that runs on your phone. It mixes your foods with a silly chef style and a fun twist every time. It remembers the last three recipe names so it does not repeat the same idea. If you skip the one-time download, the Quick chef still makes a simple recipe without AI.

BUILT FOR KIDS
* Big buttons and short, easy steps
* Friendly emoji and cheerful messages
* A grown-up safety note on every recipe
* No reading levels above age 10
* Works in light and dark mode
* Looks great on phones and tablets, portrait or landscape

REAL FOOD, REAL IDEAS
* 96 foods you can add by hand
* Recipes only use food you actually have
* Pantry basics like salt, oil, and water are assumed
* No alcohol, and meat, fish, and eggs must be fully cooked
* A grown-up is reminded to help with knives and hot things
* If the AI is unavailable, the Quick chef saves the day

ONE SMALL DOWNLOAD, THEN OFFLINE
The AI chef is about 521 MB and is not inside the app. Download it once on Wi-Fi, keep some free space, and then it works without internet. You can delete it anytime in Settings to free the space. The food finder is already inside the app, so it never needs a download.

PRIVATE BY DESIGN
* No personal data is collected
* Internet is used only once to download the AI recipe model
* Photos and food lists stay on your device
* No accounts, no tracking, no analytics, no ads
* No camera permission needed: your phone's camera app takes the picture

IMPORTANT
The food finder checks the whole photo, nine close-ups, and package labels. It knows common foods like bananas, apples, oranges, broccoli, carrots, sandwiches, pizza, hot dogs, donuts, cake, drinks, milk, eggs, cheese, bread, meat, fish, rice, pasta, and many vegetables. It may still miss items and can confuse similar foods, so the hand-add list is always there. AI recipes are generated on the device and should be checked by a grown-up. Always check food for allergies and ask a grown-up for help with knives and hot things.

Fridge Roulette is a cooking game, not medical or nutrition advice.

Made with Flutter, two on-device YOLO food models, on-device ML Kit label reading, and the Qwen2.5 0.5B Instruct model (Apache-2.0). Source code is available under the AGPL-3.0 license.
```

## Graphics checklist

| Asset | Requirement | Status |
| --- | --- | --- |
| App icon | 512x512 PNG, 32-bit, no transparency | Use a rendered version of the adaptive fridge icon |
| Feature graphic | 1024x500 PNG/JPEG, no transparency | Needed |
| Phone screenshots | 2-8, 16:9 or 9:16, min 320 px | Needed |
| Tablet screenshots | 2-8, recommended | Needed |
| Promo video | Optional YouTube URL | Not planned |

Screenshot captions to use in the listing:

1. "One photo is all it takes"
2. "Check the food, fix the list"
3. "Spin for a surprise recipe"
4. "The AI chef writes it live"
5. "Simple steps made for kids"
6. "Big buttons, friendly words"

## Data safety answers

| Question | Answer |
| --- | --- |
| Does your app collect or share any required user data types? | No |
| Is all user data encrypted in transit? | The only network request is the model download over HTTPS; no user data is sent |
| Does your app provide a way for users to request data deletion? | Yes, the downloaded model can be deleted in Settings. No user data is stored off-device |
| Photos | Accessed on-device only, never uploaded |
| Approximate location, precise location | Not collected |
| Personal info, financial info, health info | Not collected |
| Messages, contacts, calendar | Not collected |
| App activity, in-app search history | Not collected |
| Device or other IDs | Not collected by the app |
| Crash logs / diagnostics | Not collected (no crash reporting SDK) |
| Advertising or tracking | None |
| Internet use | One-time download of the AI recipe model from Hugging Face only |

**Data Safety text to use:** “No personal data is collected. Internet is used only once to download the AI recipe model.”

The release manifest asks for `INTERNET`, `ACCESS_NETWORK_STATE`, and `WAKE_LOCK` for the one-time model download. It also asks for `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, and `POST_NOTIFICATIONS` only to keep that download alive and show its progress notification. It does not ask for camera, location, storage, or microphone permission. The app also declares a private Android permission that AndroidX uses to protect its own broadcast receivers.

## Content rating questionnaire notes

- Violence, blood, sexual content, nudity, profanity, drugs, alcohol, tobacco, gambling: **No**.
- User-generated content, chat, sharing, external links: **No** (the app has no external links; only the store description links to source).
- Simulated gambling: **No**. The "wheel" is a recipe picker, not a betting mechanic.
- Ads: **No**.
- Purchases: **No**.
- The app gives cooking instructions; it is not medical advice. Add "Ask a grown-up" context in the review notes if asked.
- AI-generated recipes: explain in the review notes that the model runs on-device and a grown-up should check allergies and cooking steps.

## Target audience and Families

The app is designed for children around 6-12 and their families.

- Select the **Families** target audience only if you are ready to follow the Families policy. The app already meets the main requirements: no ads, no purchases, no personal data collection, and a privacy policy.
- Do not use the "Teacher approved" badge unless you apply separately.
- Keep the store listing free of links to social media or external websites if you want the simplest review.

## Release notes

### 1.0.1 (versionCode 2)

```text
Small polish update.
* Download progress starts faster and explains the notification choice first
* Choose Allow for a progress notification, or Not now to keep the screen open
* Clearer download errors and retry
* Recipe text now shows plain English while it is being written
* No more visible \n codes or HTML tags in the live recipe
```

### 1.0.0 (versionCode 1)

```text
First release!
* Snap a fridge photo and find food on-device
* Check and edit the food list
* Spin for a live AI recipe written on your phone
* The AI chef downloads once, then works offline
* Quick chef fallback works without the AI model
* Kid-friendly safety notes and a grown-up reminder
* Light, dark, phone, and tablet layouts
```
