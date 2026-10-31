/// The one place for sizes that should look the same on every screen.
///
/// Font sizes live in [AppTheme]. These values are for spacing, icons,
/// rounded corners, and big touch targets.
abstract final class AppSizes {
  static const double touchTarget = 56;
  static const double minTouchTarget = 48;

  static const double iconSmall = 18;
  static const double iconStep = 22;
  static const double icon = 24;
  static const double iconLarge = 30;
  static const double iconHero = 54;

  static const double emojiSmall = 18;
  static const double emoji = 24;
  static const double emojiMedium = 30;
  static const double emojiLarge = 48;
  static const double emojiHero = 68;
  static const double emojiMascot = 78;

  static const double maxContentWidth = 820;
  static const double stepDot = 36;
}

/// The small steps we use between widgets.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Rounded corners. Cards use one size so the app feels calm and tidy.
abstract final class AppRadius {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 18;
  static const double card = 22;
  static const double image = 24;
  static const double hero = 30;
  static const double dialog = 28;
  static const double pill = 999;
}
