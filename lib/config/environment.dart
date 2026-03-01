import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ─────────────────────────────────────────────
/// FlacronCV – Environment Configuration
/// Handles dev / prod modes & secure env values
/// ─────────────────────────────────────────────

enum AppEnvironment {
  development,
  production,
}

class Environment {
  /// Change this if you want to switch environment
  static const AppEnvironment current =
      AppEnvironment.production;

  // ───────── App Mode ─────────
  static bool get isProduction =>
      current == AppEnvironment.production;

  static bool get isDevelopment =>
      current == AppEnvironment.development;

  // ───────── App Info ─────────
  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'FlacronCV';

  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'production';

  // ───────── AI Keys ─────────
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static String get openAiApiKey =>
      dotenv.env['OPENAI_API_KEY'] ?? '';

  // ───────── Firebase ─────────
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseRegion =>
      dotenv.env['FIREBASE_REGION'] ?? 'us-central1';

  // ───────── Stripe ─────────
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get stripeSecretKey =>
      dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  // ───────── Validation ─────────
  static void validate() {
    if (geminiApiKey.isEmpty) {
      throw Exception('❌ GEMINI_API_KEY is missing in .env');
    }

    if (firebaseProjectId.isEmpty) {
      throw Exception('❌ FIREBASE_PROJECT_ID is missing in .env');
    }
  }
}
