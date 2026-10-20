# Google Play store listing

Ready-to-paste text for Fridge Roulette. Replace the placeholders in angle brackets before submitting.

## App identity

| Field | Value |
| --- | --- |
| App name | Fridge Roulette |
| Package | `com.sarthakgupta.fridgeroulette` |
| Category | Education (alternative: Entertainment) |
| Tags | Cooking, Kids, Offline, Food, Family |
| Pricing | Free |
| Ads | No |
| In-app purchases | No |
| Default language | English (India) or English (US) |
| Contact email | `<your-support-email@example.com>` |
| Privacy policy | `<https://your-domain.example/privacy-policy>` |
| Website | `https://github.com/SarthakGupta2912/Fridge-Roulette` |

## Short description (80 characters max)

```text
Snap your fridge, spin the wheel, and cook a kid-friendly recipe offline!
```

Character count: 72.

## Full description

```text
What is in your fridge? Turn one photo into a fun cooking challenge!

Fridge Roulette is a playful cooking game for kids and families. Take a photo of your fridge, and the app finds the food right on your phone. Spin the wheel and get a simple recipe made from what you already have. No account. No ads. No internet needed.

HOW IT WORKS
1. Snap a photo of your fridge or pick one from your gallery.
2. Check the food list. Tap a food to remove it, or add anything the app missed.
3. Spin the wheel and cook the recipe challenge!

BUILT FOR KIDS
* Big buttons and short, easy steps
* Friendly emoji and cheerful messages
* A grown-up safety note on every recipe
* No reading levels above age 10
* Works in light and dark mode
* Looks great on phones and tablets, portrait or landscape

REAL FOOD, REAL IDEAS
* 70 family-friendly recipes
* 48 foods you can add by hand
* Recipes only use food you actually have
* The wheel avoids repeating the last three recipes
* If no full recipe fits, it invents a simple two-food snack
* Pantry basics like salt, oil, and water are assumed

FULLY OFFLINE AND PRIVATE
* The food finder is inside the app
* The app has no internet permission
* Photos stay on your device
* No accounts, no tracking, no analytics, no ads
* No camera permission needed: your phone's camera app takes the picture

IMPORTANT
The food finder knows common foods like bananas, apples, oranges, broccoli, carrots, sandwiches, pizza, hot dogs, donuts, cake, and drinks. It may miss other items, so the hand-add list is always there. Always check food for allergies and ask a grown-up for help with knives and hot things.

Fridge Roulette is a cooking game, not medical or nutrition advice.

Made with Flutter and an on-device YOLO model. Source code is available under the AGPL-3.0 license.
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
4. "Simple steps made for kids"
5. "Works offline, even in airplane mode"
6. "Big buttons, friendly words"

## Data safety answers

| Question | Answer |
| --- | --- |
| Does your app collect or share any required user data types? | No |
| Is all user data encrypted in transit? | Not applicable, no data is transmitted |
| Does your app provide a way for users to request data deletion? | Not applicable, no data is stored off-device |
| Photos | Accessed on-device only, never uploaded |
| Approximate location, precise location | Not collected |
| Personal info, financial info, health info | Not collected |
| Messages, contacts, calendar | Not collected |
| App activity, in-app search history | Not collected |
| Device or other IDs | Not collected by the app |
| Crash logs / diagnostics | Not collected (no crash reporting SDK) |
| Advertising or tracking | None |

The only permission in the release manifest is the app's own dynamically generated receiver permission. There is no INTERNET, CAMERA, location, storage, notification, or background-service permission.

## Content rating questionnaire notes

- Violence, blood, sexual content, nudity, profanity, drugs, alcohol, tobacco, gambling: **No**.
- User-generated content, chat, sharing, external links: **No** (the Home screen has no links; only the store description links to source).
- Simulated gambling: **No**. The "wheel" is a recipe picker, not a betting mechanic.
- Ads: **No**.
- Purchases: **No**.
- The app gives cooking instructions; it is not medical advice. Add "Ask a grown-up" context in the review notes if asked.

## Target audience and Families

The app is designed for children around 6-12 and their families.

- Select the **Families** target audience only if you are ready to follow the Families policy. The app already meets the main requirements: no ads, no purchases, no data collection, no external links, and a privacy policy.
- Do not use the "Teacher approved" badge unless you apply separately.
- Keep the store listing free of links to social media or external websites if you want the simplest review.

## Release notes

### 1.0.0 (versionCode 1)

```text
First release!
* Snap a fridge photo and find food on-device
* Check and edit the food list
* Spin for one of 70 kid-friendly recipes
* Works fully offline with no ads or accounts
* Light, dark, phone, and tablet layouts
```

## ASO keyword ideas

fridge, recipe, cooking, kids cooking, food detective, what's in my fridge, offline recipe app, family cooking, food waste, leftover ideas, cooking game for kids, kitchen helper, pantry, snack ideas

Do not stuff keywords into the full description; the paragraph above is already readable and keyword-aware.
