import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ─────────────────────────────────────────────
/// Stripe Configuration
/// ─────────────────────────────────────────────
/// • Loads keys from .env
/// • Initializes Stripe safely
/// • No secrets hardcoded
/// ─────────────────────────────────────────────
class StripeConfig {
  StripeConfig._(); // Prevent instantiation

  /// Initialize Stripe SDK
  static Future<void> init() async {
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];

    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception(
        '❌ STRIPE_PUBLISHABLE_KEY is missing in .env file',
      );
    }

    Stripe.publishableKey = publishableKey;

    // Optional but recommended
    Stripe.merchantIdentifier = 'merchant.flacroncv';
    Stripe.urlScheme = 'flacroncv';

    await Stripe.instance.applySettings();
  }
}
