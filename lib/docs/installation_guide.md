# 🚀 FLACRONCONTROL - COMPLETE INSTALLATION GUIDE

## 📋 TABLE OF CONTENTS
1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Firebase Configuration](#firebase-configuration)
4. [File Installation](#file-installation)
5. [Dependencies](#dependencies)
6. [API Keys](#api-keys)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## 1️⃣ PREREQUISITES

### Required Software:
- ✅ Flutter SDK 3.2.0 or higher
- ✅ Android Studio / VS Code
- ✅ Git
- ✅ Firebase CLI (optional but recommended)

### Check Flutter Installation:
```bash
flutter --version
flutter doctor
```

---

## 2️⃣ PROJECT SETUP

### Step 1: Navigate to Project
```bash
cd D:\FlacronCV
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Clean Build (if needed)
```bash
flutter clean
flutter pub get
```

---

## 3️⃣ FIREBASE CONFIGURATION

### A. Create Firebase Project
1. Go to: https://console.firebase.google.com
2. Click "Add project"
3. Name: **FlacronControl**
4. Enable Google Analytics (optional)
5. Create project

### B. Add Android App
1. In Firebase Console → Project Settings
2. Click "Add app" → Android icon
3. Package name: `com.example.flacroncv` (or your package name)
4. Download `google-services.json`
5. Place in: `android/app/google-services.json`

### C. Add iOS App (if building for iOS)
1. Click "Add app" → iOS icon
2. Bundle ID: from `ios/Runner/Info.plist`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`

### D. Enable Firebase Services
In Firebase Console:

**Authentication:**
1. Authentication → Get Started
2. Sign-in method → Enable:
   - ✅ Email/Password
   - ✅ Google

**Firestore Database:**
1. Firestore Database → Create Database
2. Choose "Test mode" (for development)
3. Select your region
4. Click Enable

**Storage:**
1. Storage → Get Started
2. Choose "Test mode"
3. Click Done

### E. Apply Security Rules
Copy contents of `firestore_rules.txt` to:
- Firestore Database → Rules → Paste → Publish

---

## 4️⃣ FILE INSTALLATION

### Phase 1: Authentication
```
lib/
├── core/
│   ├── models/
│   │   └── user_model.dart
│   └── services/
│       └── auth_service.dart
└── features/
    └── auth/
        └── presentation/
            ├── login_screen.dart
            └── register_screen.dart
```

### Phase 2: Business Setup
```
lib/
├── core/
│   ├── models/
│   │   ├── business_model.dart
│   │   ├── service_model.dart
│   │   └── business_hours_model.dart
│   └── services/
│       └── business_service.dart
└── features/
    └── business/
        └── presentation/
            ├── business_setup_screen.dart
            ├── business_profile_screen.dart
            ├── services_screen.dart
            └── business_hours_screen.dart
```

### Phase 3: Dashboard
```
lib/
├── features/
│   └── dashboard/
│       └── dashboard_screen.dart
└── modules/
    └── admin/
        └── ui/
            └── admin_dashboard_screen.dart
```

### Phase 4: Bookings
```
lib/
├── core/
│   ├── models/
│   │   └── booking_model.dart
│   └── services/
│       └── booking_service.dart
└── features/
    └── bookings/
        └── presentation/
            ├── booking_calendar_screen.dart
            ├── create_booking_screen.dart
            └── booking_detail_screen.dart
```

### Phase 5: Payments & Invoices
```
lib/
├── core/
│   ├── models/
│   │   └── invoice_model.dart
│   └── services/
│       └── invoice_service.dart
└── features/
    ├── invoices/
    │   └── presentation/
    │       ├── invoice_list_screen.dart
    │       ├── create_invoice_screen.dart
    │       └── invoice_detail_screen.dart
    └── payments/
        └── presentation/
            └── payments_screen.dart
```

### Phase 6: Employees
```
lib/
├── core/
│   ├── models/
│   │   └── employee_model.dart
│   └── services/
│       └── employee_service.dart
└── features/
    └── employees/
        └── presentation/
            ├── employee_list_screen.dart
            ├── add_employee_screen.dart
            └── employee_detail_screen.dart
```

### Phase 7: Attendance & Payroll
```
lib/
├── core/
│   ├── models/
│   │   ├── attendance_model.dart
│   │   └── payroll_model.dart
│   └── services/
│       ├── attendance_service.dart
│       └── payroll_service.dart
└── modules/
    └── attendance/
        └── ui/
            ├── attendance_screen.dart
            └── payroll_screen.dart
```

### Phase 8: AI Chat
```
lib/
├── core/
│   ├── models/
│   │   └── chat_message_model.dart
│   └── services/
│       └── ai_chat_service.dart
└── modules/
    └── ai/
        └── ui/
            └── ai_chat_screen.dart
```

### Routes
```
lib/
└── routes/
    ├── route_names.dart
    └── app_router.dart
```

---

## 5️⃣ DEPENDENCIES

Your `pubspec.yaml` should have:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.4
  cloud_firestore: ^4.15.5
  firebase_storage: ^11.6.0
  
  # Auth
  google_sign_in: ^6.2.1
  
  # State Management
  provider: ^6.1.1
  
  # UI
  google_fonts: ^6.2.1
  
  # Calendar
  table_calendar: ^3.0.9
  
  # Image
  image_picker: ^1.0.7
  
  # HTTP
  http: ^1.2.0
  
  # Utils
  uuid: ^4.3.3
  shared_preferences: ^2.2.2
  url_launcher: ^6.2.5
  
  # Environment
  flutter_dotenv: ^5.1.0
```

Run:
```bash
flutter pub get
```

---

## 6️⃣ API KEYS

### Google Gemini API (AI Chat)
1. Get key: https://makersuite.google.com/app/apikey
2. Create `.env` file in project root:
   ```
   GEMINI_API_KEY=YOUR_KEY_HERE
   ```
3. Update `ai_chat_service.dart`:
   ```dart
   static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

### SHA-1 Fingerprint (Google Sign-In)
```bash
cd android
./gradlew signingReport
```
Copy SHA-1 → Firebase Console → Project Settings → Add fingerprint

---

## 7️⃣ TESTING

### Run on Emulator/Device
```bash
flutter run
```

### Test Features Checklist:
- [ ] Register new account
- [ ] Login with email/password
- [ ] Login with Google
- [ ] Create business profile
- [ ] Add services
- [ ] Set business hours
- [ ] Create booking
- [ ] Generate invoice
- [ ] Add employee
- [ ] Mark attendance
- [ ] Generate payroll
- [ ] Test AI chat

---

## 8️⃣ TROUBLESHOOTING

### Issue: Firebase not initialized
```dart
// In main.dart:
await Firebase.initializeApp();
```

### Issue: Google Sign-In not working
- Check SHA-1 fingerprint is added to Firebase
- Verify `google-services.json` is correct
- Enable Google Sign-In in Firebase Console

### Issue: Firestore permission denied
- Check security rules are published
- Verify user is authenticated

### Issue: Image picker not working (Android)
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### Issue: AI Chat not working
- Verify Gemini API key is correct
- Check internet connection
- Ensure `.env` file is loaded in `main.dart`:
```dart
await dotenv.load();
```

---

## 🎉 CONGRATULATIONS!

Your FlacronControl app is now ready to use!

### Next Steps:
1. Customize branding (logo, colors)
2. Add app icon & splash screen
3. Test on real devices
4. Build release version
5. Deploy to stores

---

## 📞 SUPPORT

For issues:
1. Check Firebase Console logs
2. Run `flutter doctor`
3. Check `flutter run --verbose` output
4. Review Firestore security rules

---

**Built with ❤️ using Flutter**