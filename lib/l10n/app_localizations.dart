import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('it'),
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'FlacronCV'**
  String get appTitle;

  /// Main welcome heading
  ///
  /// In en, this message translates to:
  /// **'Automate Your Business with AI'**
  String get welcomeTitle;

  /// Welcome page subtitle
  ///
  /// In en, this message translates to:
  /// **'One powerful platform replacing Calendly, Gusto, Stripe, WhatsApp & more'**
  String get welcomeSubtitle;

  /// Get started button text
  ///
  /// In en, this message translates to:
  /// **'Get Started Free'**
  String get getStartedFree;

  /// Login link for existing users
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccountLogin;

  /// Features section heading
  ///
  /// In en, this message translates to:
  /// **'Everything Your Business Needs'**
  String get everythingYourBusinessNeeds;

  /// Features section subheading
  ///
  /// In en, this message translates to:
  /// **'One platform. Zero hassle.'**
  String get onePlatformZeroHassle;

  /// AI customer assistant feature title
  ///
  /// In en, this message translates to:
  /// **'AI Customer Assistant'**
  String get aiCustomerAssistant;

  /// AI customer assistant feature description
  ///
  /// In en, this message translates to:
  /// **'24/7 intelligent chatbot that answers questions, suggests services and closes bookings'**
  String get aiCustomerAssistantDesc;

  /// Smart bookings feature title
  ///
  /// In en, this message translates to:
  /// **'Smart Bookings'**
  String get smartBookings;

  /// Smart bookings feature description
  ///
  /// In en, this message translates to:
  /// **'Effortless scheduling, availability checks, reminders and calendar sync'**
  String get smartBookingsDesc;

  /// Online payments feature title
  ///
  /// In en, this message translates to:
  /// **'Online Payments'**
  String get onlinePayments;

  /// Online payments feature description
  ///
  /// In en, this message translates to:
  /// **'Secure Stripe deposits & full payments - instant & hassle-free'**
  String get onlinePaymentsDesc;

  /// Auto invoicing feature title
  ///
  /// In en, this message translates to:
  /// **'Auto Invoicing'**
  String get autoInvoicing;

  /// Auto invoicing feature description
  ///
  /// In en, this message translates to:
  /// **'Professional invoices generated automatically after every booking or service'**
  String get autoInvoicingDesc;

  /// Employee attendance feature title
  ///
  /// In en, this message translates to:
  /// **'Employee & Attendance'**
  String get employeeAttendance;

  /// Employee attendance feature description
  ///
  /// In en, this message translates to:
  /// **'Clock-in/out tracking, hours calculation and simple attendance dashboard'**
  String get employeeAttendanceDesc;

  /// Payroll summary feature title
  ///
  /// In en, this message translates to:
  /// **'Payroll Summary'**
  String get payrollSummary;

  /// Payroll summary feature description
  ///
  /// In en, this message translates to:
  /// **'Instant overview of employee hours x rates - no more manual math'**
  String get payrollSummaryDesc;

  /// Pricing section heading
  ///
  /// In en, this message translates to:
  /// **'Simple, Transparent Pricing'**
  String get pricingTitle;

  /// Pricing section subheading
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that fits your business'**
  String get pricingSubtitle;

  /// Starter pricing plan name
  ///
  /// In en, this message translates to:
  /// **'Starter'**
  String get starterPlan;

  /// Growth pricing plan name
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get growthPlan;

  /// Pro pricing plan name
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get proPlan;

  /// Enterprise pricing plan name
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get enterprisePlan;

  /// Per month pricing suffix
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// Most popular plan badge
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// Choose plan button text
  ///
  /// In en, this message translates to:
  /// **'Choose Plan'**
  String get choosePlan;

  /// Trusted by businesses section heading
  ///
  /// In en, this message translates to:
  /// **'Trusted by Businesses Like Yours'**
  String get trustedByBusinesses;

  /// Call to action heading
  ///
  /// In en, this message translates to:
  /// **'Ready to Automate Your Business?'**
  String get readyToAutomate;

  /// Call to action subheading
  ///
  /// In en, this message translates to:
  /// **'Join hundreds of businesses saving time and money every day.'**
  String get joinHundreds;

  /// Start free trial button text
  ///
  /// In en, this message translates to:
  /// **'Start Your Free Trial'**
  String get startFreeTrial;

  /// Copyright notice
  ///
  /// In en, this message translates to:
  /// **'© 2026 FlacronCV • All rights reserved'**
  String get copyright;

  /// Create account page title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Join FlacronControl heading
  ///
  /// In en, this message translates to:
  /// **'Join FlacronControl'**
  String get joinFlacronControl;

  /// Registration page subheading
  ///
  /// In en, this message translates to:
  /// **'Start automating your business today'**
  String get startAutomatingToday;

  /// Full name form field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Business name form field label
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Email form field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Phone number form field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Password form field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password form field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// Login link on registration page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// Required field validation message
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// Invalid email validation message
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// Password minimum length validation message
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordMinLength;

  /// Password mismatch validation message
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Account created success dialog title
  ///
  /// In en, this message translates to:
  /// **'Account Created!'**
  String get accountCreatedTitle;

  /// Account created success dialog message
  ///
  /// In en, this message translates to:
  /// **'Welcome to FlacronCV! Your profile has been saved.\nPlease verify your email and log in.'**
  String get accountCreatedMessage;

  /// Go to login button text
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Attendance navigation label
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// Payroll navigation label
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// Settings navigation label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language settings label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['it', 'ar', 'de', 'en', 'es', 'fr', 'hi', 'ko', 'pt', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'it': return AppLocalizationsIt();
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'ko': return AppLocalizationsKo();
    case 'pt': return AppLocalizationsPt();
    case 'ru': return AppLocalizationsRu();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
