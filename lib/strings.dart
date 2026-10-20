/// All the words the child sees, in one place.
/// Change text here and it changes everywhere in the app.
class AppStrings {
  const AppStrings._();

  static const String appName = 'Fridge Roulette';
  static const String homeTitle = 'What is in your fridge?';
  static const String homeSubtitle =
      'Snap one photo. I will find the food. Then we spin a fun recipe!';
  static const String takePhoto = 'Take a Photo';
  static const String pickGallery = 'Pick from gallery';
  static const String howItWorks = 'How it works';
  static const String stepSnap = 'Snap your fridge';
  static const String stepCheck = 'Check your food';
  static const String stepSpin = 'Spin the wheel';
  static const String stepShortSnap = 'Photo';
  static const String stepShortCheck = 'Foods';
  static const String stepShortSpin = 'Spin';
  static const String stepSnapEmoji = '📸';
  static const String stepCheckEmoji = '🧺';
  static const String stepSpinEmoji = '🎡';
  static const String homeHint =
      'Tip: Open the fridge door and take one clear photo.';
  static const String offlineBadge =
      'Works offline after the one-time AI chef download.';
  static const String noCameraHint =
      'No camera? Use the gallery or add food by hand.';

  static const String settings = 'Settings';
  static const String settingsTitle = 'Settings';
  static const String chefBrainTitle = 'Chef brain';
  static const String chefBrainChecking = 'Checking the chef brain...';
  static const String chefBrainReady = 'AI chef is ready';
  static const String chefBrainMissing = 'AI chef is not downloaded';
  static const String chefBrainFailed = 'The chef brain needs a check';
  static const String chefBrainReadyBody =
      'New recipes are written on this phone, even without internet.';
  static const String chefBrainMissingBody =
      'Download the chef brain once to get a new AI recipe every time. The '
      'Quick chef still works without it.';
  static const String downloadAiChef = 'Download AI chef';
  static const String modelSize = 'Size';
  static const String modelLicense = 'License';
  static const String modelName = 'Model';
  static const String deleteModel = 'Delete chef brain';
  static const String deleteModelTitle = 'Delete the chef brain?';
  static const String deleteModelBody =
      'This frees about 521 MB. You can download it again later.';
  static const String delete = 'Delete';
  static const String modelDeleted = 'The chef brain was deleted.';
  static const String aboutTitle = 'About';
  static const String aboutBody =
      'Fridge Roulette is a kid-friendly cooking game. No account, no ads, '
      'no analytics. The internet is used only once to download the AI chef.';
  static const String appVersion = 'Version 1.0.0';
  static const String privacyPromise =
      'No personal data is collected. Your photos and food list stay on this '
      'phone.';

  static const String downloadTitle = 'Give your chef a brain';
  static const String downloadHeroTitle = 'A little chef can live in this app';
  static const String downloadHeroBody =
      'The AI chef writes a brand-new recipe from your food. Download it once, '
      'then it works offline.';
  static const String downloadWifiHint =
      'Tip: Wi-Fi makes this faster. Keep this screen open until it finishes.';
  static const String downloadStorageTitle = 'Make a little room';
  static const String downloadStorageBody =
      'Please keep about 750 MB free. You can delete the chef brain later.';
  static const String downloadButton = 'Download AI chef';
  static const String downloadCancel = 'Cancel download';
  static const String downloadReadyTitle = 'Your AI chef is ready!';
  static const String downloadReadyBody =
      'The chef can now write recipes without internet.';
  static const String downloadDone = 'Start cooking';
  static const String useQuickChef = 'Use Quick chef';
  static const String downloadErrorTitle = 'The download did not finish';
  static const String downloadNoInternetBody =
      'Please check your internet and try again. The Quick chef still works.';
  static const String downloadStorageErrorBody =
      'There is not enough space. Free some room and try again.';
  static const String downloadCorruptBody =
      'The file got damaged. Tap Try Again for a fresh copy.';
  static const String downloadGenericBody =
      'Something stopped the download. You can try again.';
  static const String downloadCancelled =
      'Download cancelled. You can try again anytime.';
  static const String leaveDownloadTitle = 'Stop the download?';
  static const String leaveDownloadBody =
      'The chef brain will not finish downloading. You can try again later.';
  static const String keepDownloading = 'Keep downloading';
  static const String cancelAndLeave = 'Cancel and leave';
  static const String downloadedLabel = 'Downloaded';
  static const String notDownloadedLabel = 'Not downloaded';
  static const String chefBrainDownloading = 'Downloading the chef brain...';

  static const String quickChef = 'Quick chef';
  static const String aiChef = 'AI chef';
  static const String writingRecipeTitle = 'Your chef is writing...';
  static const String writingRecipeBody =
      'A fresh recipe is coming out of the chef brain.';
  static const String quickChefWriting = 'Quick chef is mixing an idea...';
  static const String recipeReadyBadge = 'Recipe ready';
  static const String makeAnother = 'Make another one';
  static const String changeFoods = 'Change foods';
  static const String stopChef = 'Stop';
  static const String stoppedTitle = 'The chef stopped';
  static const String stoppedBody =
      'You can try again or let the Quick chef finish.';
  static const String tryAiAgain = 'Try AI again';
  static const String useQuickChefAction = 'Use Quick chef';
  static const String aiHiccup =
      'The AI chef got a little tired, so Quick chef made this one.';
  static const String aiNoModel =
      'The AI chef is not downloaded, so Quick chef made this one.';
  static const String timeoutTitle = 'The chef is thinking too hard';
  static const String timeoutBody =
      'That took too long. Try one more time, or ask the Quick chef.';
  static const String rawRecipeTitle = 'Chef notes';
  static const String rawRecipeBody =
      'The chef wrote this in a funny way. Here are the words.';
  static const String chefBrainDownloadHint =
      'Want a new recipe every time? Get the AI chef.';
  static const String getAiChef = 'Get the AI chef';
  static const String recipeForFoods = 'Made with your foods';
  static const String loadingChefBrain = 'Waking up the chef...';

  static const String checkTitle = 'Check your food';
  static const String checkSubtitle =
      'Tap a food to remove it. Did I miss something? Add it below!';
  static const String yourFoods = 'Your foods';
  static const String noFoodsYet = 'No foods yet. Tap Add food below!';
  static const String noPhotoYet = 'No photo yet. Add your food by hand!';
  static const String addFood = '+ Add food';
  static const String addFoodTitle = 'What else is in the fridge?';
  static const String addFoodSubtitle =
      'Tap a food to add it. Tap again to remove it.';
  static const String done = 'Done';
  static const String lookingForFood = 'Looking closely at your fridge...';
  static const String foundFoods = 'Here is what I found!';
  static const String helpModel = 'My food finder is getting ready!';
  static const String stopLooking = 'Stop looking';

  static const String spinTheWheel = 'Spin the Wheel!';
  static const String spin = 'Spin!';
  static const String spinning = 'Spinning...';
  static const String spinAgain = 'Spin Again';
  static const String spinHint = 'Tap Spin and see what we cook!';
  static const String letsCook = 'Let\'s Cook!';
  static const String addMoreFood = 'Add More Food';
  static const String foodsInFridge = 'Foods in your fridge';
  static const String newPhoto = 'New Photo';
  static const String retakePhoto = 'Retake';
  static const String addFoodByHand = 'Add Food';
  static const String rouletteTitle = 'Spin the wheel';
  static const String rouletteReady = 'Ready? Tap the big button!';
  static const String rouletteSubtitle =
      'Your food is ready. Let us find a fun recipe!';
  static const String rouletteNoRecipe = 'Let us add a few more foods!';
  static const String rouletteNoRecipeBody =
      'I need a little more to make a recipe. Add 1 or 2 foods and spin again.';
  static const String roulettePickTitle = 'I picked...';
  static const String rouletteTada = 'Ta-da!';
  static const String recipeReady = 'Your recipe is ready!';
  static const String spinningForYou = 'Spinning for you...';

  static const String recipeTitle = 'Your challenge';
  static const String challengeTwist = 'Challenge twist';
  static const String timeLabel = 'Time';
  static const String difficultyLabel = 'How hard?';
  static const String ingredientsLabel = 'What you need';
  static const String stepsLabel = 'How to make it';
  static const String chefTip = 'Chef tip';
  static const String liveRecipe = 'Chef is writing';
  static const String safetyNote =
      'Ask a grown-up for help with knives and hot things.';
  static const String fromYourFridge = 'From your fridge';
  static const String extraFood = 'Extra idea';
  static const String pantryNote =
      'We pretend you have salt, pepper, oil, water and sugar.';
  static const String easy = 'Easy';
  static const String medium = 'Medium';
  static const String tricky = 'Tricky';
  static const String minutesShort = 'min';
  static const String recipeNotFound = 'I could not find that recipe.';
  static const String mixAndMatch = 'Mix and Match';

  static const String loadingTitle = 'Getting ready...';
  static const String loadingBody =
      'I am waking up my food finder. One little moment!';
  static const String getReady = 'Getting ready...';
  static const String modelFailedTitle = 'My food finder is sleepy';
  static const String modelFailedBody =
      'I could not wake up my food finder. You can still add food by hand!';
  static const String retry = 'Try Again';
  static const String useHands = 'Add Food by Hand';
  static const String cameraProblemTitle = 'Oops! The camera did not open';
  static const String cameraProblemBody =
      'You can pick a photo from your gallery instead, or add food by hand.';
  static const String galleryProblemTitle = 'Oops! I could not open that photo';
  static const String galleryProblemBody =
      'Please try another photo, or add your food by hand.';
  static const String noFoodTitle = 'I could not see any food';
  static const String noFoodBody =
      'Try more light, or get closer. You can also add food by hand!';
  static const String noFoodTitleShort = 'No food found';
  static const String noFoodBodyShort = 'Let us try again or add food by hand.';
  static const String tooLongTitle = 'That took too long';
  static const String tooLongBody =
      'Let us try again. A smaller photo is faster.';
  static const String photoProblemTitle = 'That photo looks tricky';
  static const String photoProblemBody =
      'Let us try one more photo, or add food by hand.';
  static const String notEnoughTitle = 'Add one more food';
  static const String notEnoughBody =
      'Pick at least 2 foods so I can spin a recipe.';
  static const String notEnoughHint = 'Add 1 more food to spin!';
  static const String needFoods = 'I need 2 foods to spin.';
  static const String leaveTitle = 'Leave this page?';
  static const String leaveBody = 'Your photo and food list will be lost.';
  static const String stay = 'Stay';
  static const String leave = 'Leave';
  static const String okay = 'OK';
  static const String cancel = 'Cancel';
  static const String pickPhotoTitle = 'Let us try that again';
  static const String pickPhotoBody =
      'Take a new photo or pick one from your gallery.';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';
  static const String detectingHint =
      'This can take up to 2 minutes. Thanks for waiting!';
  static const String foodsReady = 'foods ready';
  static const String oneFoodReady = 'food ready';
  static const String retryLoad = 'Wake it up';
  static const String errorTitle = 'Oops! Something went wrong';
  static const String errorBody = 'Please go back and try again.';
  static const String close = 'Close';
  static const String listeningHint = 'Tap a food to remove it.';
  static const String removeFood = 'Remove';
  static const String addFoodSemantic = 'Add another food';
  static const String photoSemantic = 'Photo of your fridge with food boxes';
  static const String wheelSemantic = 'Recipe roulette wheel';
  static const String mascotSemantic = 'A happy cook with food';

  /// "3 foods ready" or "1 food ready".
  static String foodCount(int count) {
    return '$count ${count == 1 ? oneFoodReady : foodsReady}';
  }

  /// "Checking part 3 of 11" while the close-up scan runs.
  static String scanningStep(int done, int total) {
    return 'Checking part $done of $total';
  }

  static String downloadProgress(int percent, int doneMb, int totalMb) {
    return 'Downloading $percent% · $doneMb of $totalMb MB';
  }

  static String oneTimeDownload(String size) => 'One-time download: $size';

  static String finePrint(String label, String value) => '$label: $value';

  /// The Done button in the add-food sheet. It shows how many foods are picked.
  static String doneWithCount(int count) => '$done ($count)';

  /// Read by a screen reader on the three step circles.
  static String stepSemantic(int number, String label) {
    return 'Step $number of 3: $label';
  }

  /// Read by a screen reader on a food tile in the add-food sheet.
  static String addedFoodSemantic(String name) => '$name, added';

  /// Read by a screen reader on a food tile that is not picked.
  static String notAddedFoodSemantic(String name) => '$name, not added';
}
