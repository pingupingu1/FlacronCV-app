/// ─────────────────────────────────────────────
/// FlacronCV – Application Constants
/// Central place for all fixed values
/// Keeps app clean, consistent & maintainable
/// ─────────────────────────────────────────────

class AppConstants {
  // ───────── App Info ─────────
  static const String appName = 'FlacronCV';
  static const String appVersion = '1.0.0';
  static const String companyName = 'Flacron Technologies';

  // ───────── API / Network ─────────
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int paginationLimit = 20;

  // ───────── Firestore Collections ─────────
  static const String usersCollection = 'users';
  static const String resumesCollection = 'resumes';
  static const String paymentsCollection = 'payments';

  // AI Chat
  static const String aiChatsCollection = 'ai_chats';
  static const String aiMessagesSubCollection = 'messages';

  // ───────── AI Assistant Defaults ─────────
  static const String aiDefaultModel = 'gemini-pro';
  static const int aiMaxTokens = 2048;
  static const double aiTemperature = 0.7;

  // ───────── Authentication ─────────
  static const int otpTimeoutSeconds = 60;

  // ───────── Localization / Languages ─────────
  static const String defaultLanguageCode = 'en';

  static const List<String> supportedLanguages = [
    'en', // English
    'hi', // Hindi
    'ru', // Russian
    'pt', // Portuguese
    'es', // Spanish
    'fr', // French
    'de', // German
    'ar', // Arabic
    'ur', // Urdu
  ];

  // ───────── UI Defaults ─────────
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;

  // ───────── Date & Time Formats ─────────
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy • hh:mm a';

  // ───────── Stripe / Payments ─────────
  static const String defaultCurrency = 'usd';

  // ───────── Error Messages (Fallback) ─────────
  static const String genericError =
      'Something went wrong. Please try again later.';
}
