class AppConfig {
  static const _googleAppsScriptUrlFromEnv = String.fromEnvironment(
    'GOOGLE_APPS_SCRIPT_URL',
  );

  // Paste your deployed Apps Script Web App URL here if you do not want to
  // pass --dart-define every time.
  static const _googleAppsScriptUrlFallback =
      'https://script.google.com/macros/s/AKfycbwpb2KjSHhIxR7DzIgiwNhjG1GRWWGtM_ENkIOvJ7fiHz5byCYP1VwnrVfvSphocDlDCw/exec';

  static String get googleAppsScriptUrl =>
      _googleAppsScriptUrlFromEnv.trim().isNotEmpty
      ? _googleAppsScriptUrlFromEnv
      : _googleAppsScriptUrlFallback;

  static bool get hasGoogleAppsScriptUrl =>
      googleAppsScriptUrl.trim().isNotEmpty;

  static const _cardsCollectionFromEnv = String.fromEnvironment(
    'FIRESTORE_CARDS_COLLECTION',
  );

  static const _cardsCollectionFallback = 'scanned_cards';

  static String get cardsCollection => _cardsCollectionFromEnv.trim().isNotEmpty
      ? _cardsCollectionFromEnv
      : _cardsCollectionFallback;

  static const _authEmailDomainFromEnv = String.fromEnvironment(
    'AUTH_EMAIL_DOMAIN',
  );

  // Firebase email/password auth requires an email address. Usernames entered
  // in the app are converted to <username>@<domain> before sign-in.
  static const _authEmailDomainFallback = 'businesscard.local';

  static String get authEmailDomain => _authEmailDomainFromEnv.trim().isNotEmpty
      ? _authEmailDomainFromEnv.trim().toLowerCase()
      : _authEmailDomainFallback;
}
