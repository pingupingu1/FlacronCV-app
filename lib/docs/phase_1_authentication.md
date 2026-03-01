# FLACRONCONTROL - PHASE 1: AUTHENTICATION SYSTEM
## Complete Implementation Guide

---

## 📦 **FILES CREATED (Phase 1)**

```
lib/
├── core/
│   ├── models/
│   │   └── user_model.dart          ✅ User model with roles
│   └── services/
│       └── auth_service.dart        ✅ Complete authentication service
└── features/
    └── auth/
        └── presentation/
            ├── login_screen.dart    ✅ Login UI
            └── register_screen.dart ✅ Registration UI
```

---

## 🚀 **INSTALLATION STEPS**

### **Step 1: Copy Files to Your Project**

Copy these files to your FlacronCV project:

1. **user_model.dart** → `D:\FlacronCV\lib\core\models\user_model.dart`
2. **auth_service.dart** → `D:\FlacronCV\lib\core\services\auth_service.dart`
3. **login_screen.dart** → `D:\FlacronCV\lib\features\auth\presentation\login_screen.dart`
4. **register_screen.dart** → `D:\FlacronCV\lib\features\auth\presentation\register_screen.dart`

---

### **Step 2: Update pubspec.yaml**

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.6.0
  firebase_messaging: ^14.7.10
  
  # Google Sign In
  google_sign_in: ^6.2.1
  
  # State Management (optional)
  provider: ^6.1.1
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
```

Run:
```bash
flutter pub get
```

---

### **Step 3: Update route_names.dart**

Add new routes:

```dart
// lib/routes/route_names.dart

class RouteNames {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String employeeDashboard = '/employee-dashboard';
  static const String businessSetup = '/business-setup';
}
```

---

### **Step 4: Update app_router.dart**

```dart
// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/welcome_screen.dart';
import '../features/splash/splash_screen.dart';
import 'route_names.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      
      case RouteNames.businessSetup:
        return MaterialPageRoute(builder: (_) => const BusinessSetupScreen());
      
      case RouteNames.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
```

---

### **Step 5: Update main.dart**

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlacronControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
```

---

### **Step 6: Configure Firebase**

1. **Go to Firebase Console:** https://console.firebase.google.com
2. **Select your project:** `flacroncv`
3. **Enable Authentication:**
   - Go to: Authentication > Sign-in method
   - Enable: Email/Password
   - Enable: Google
4. **Enable Firestore:**
   - Go to: Firestore Database
   - Click: Create database
   - Select: Start in test mode
5. **Get Firebase config:**
   - Go to: Project Settings
   - Add Web app (if not done)
   - Copy configuration

---

### **Step 7: Update Firebase Security Rules**

Go to Firestore > Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Users can read their own document
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Users can create their own document during registration
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Users can update their own document
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Only super admins can delete
      allow delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'superAdmin';
    }
    
    // More rules will be added in future phases
  }
}
```

---

### **Step 8: Update Welcome Screen Login Button**

In `welcome_screen.dart`, update the Login button action:

```dart
// Replace line where login button opens sidebar
// OLD:
onPressed: _toggleLoginPanel,

// NEW:
onPressed: () {
  Navigator.pushNamed(context, RouteNames.login);
},
```

Also update the "Free Account" button:

```dart
// NEW:
onPressed: () {
  Navigator.pushNamed(context, RouteNames.register);
},
```

---

### **Step 9: Update Sidebar Login Widget**

Replace the entire login widget with navigation:

```dart
// lib/features/home/presentation/widgets/sidebar_login_widget.dart

import 'package:flutter/material.dart';
import '../../../../routes/route_names.dart';

class SidebarLoginWidget extends StatelessWidget {
  const SidebarLoginWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_rounded, size: 80, color: Colors.orange[700]),
            const SizedBox(height: 24),
            const Text(
              'Ready to get started?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.register);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange[700]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Create Account', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### **Step 10: Create Placeholder Screens**

Create these temporary screens (we'll build them later):

```dart
// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: const Center(child: Text('Coming in Phase 1B')),
    );
  }
}
```

```dart
// lib/features/business/presentation/business_setup_screen.dart
import 'package:flutter/material.dart';

class BusinessSetupScreen extends StatelessWidget {
  const BusinessSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Setup')),
      body: const Center(child: Text('Coming in Phase 2')),
    );
  }
}
```

```dart
// lib/features/dashboard/presentation/dashboard_screen.dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Coming in Phase 3')),
    );
  }
}
```

---

## ✅ **TESTING PHASE 1**

### **Test 1: Registration**
1. Run the app
2. Click "Free Account" or "Create Account"
3. Fill in the form
4. Click "Create Account"
5. Check if Firebase Authentication created the user
6. Check if Firestore created the user document

### **Test 2: Login**
1. Click "Sign In"
2. Enter credentials
3. Click "Sign In"
4. Should navigate to dashboard placeholder

### **Test 3: Google Sign-In**
1. Click "Continue with Google"
2. Select Google account
3. Should create user in Firestore
4. Should navigate to business setup

---

## 📊 **WHAT'S COMPLETED**

✅ User authentication (email/password)
✅ Google Sign-In
✅ User roles (Super Admin, Business Owner, Employee, Customer)
✅ Registration flow with validation
✅ Login flow with error handling
✅ Password visibility toggle
✅ Terms & conditions checkbox
✅ Email verification setup
✅ Firestore user document creation
✅ Role-based navigation
✅ Clean UI with proper validation

---

## 🎯 **NEXT: PHASE 2 - BUSINESS SETUP**

In the next phase, we'll build:
- Business registration form
- Service management (CRUD)
- Operating hours configuration
- Business profile page
- Logo upload

---

## 🆘 **TROUBLESHOOTING**

**Error: Firebase not initialized**
- Make sure you ran `flutterfire configure`
- Check `firebase_options.dart` exists

**Error: Google Sign-In failed**
- Enable Google provider in Firebase Console
- Add SHA-1 fingerprint for Android

**Error: User document not created**
- Check Firestore security rules
- Make sure Firestore is enabled

---

**Phase 1 is complete! Ready to test?** 🚀