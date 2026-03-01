# Module 3: AI Assistant — Setup Instructions

## Files Included
- `lib/modules/ai/models/chat_message.dart` — Message model with Gemini format conversion
- `lib/modules/ai/services/ai_service.dart` — Gemini API integration + business context builder
- `lib/modules/ai/ui/ai_chat_screen.dart` — Full admin chat screen
- `lib/modules/ai/ui/customer_chat_widget.dart` — Embeddable customer chat bubble

---

## STEP 1: Get Your Gemini API Key

1. Go to: https://aistudio.google.com/app/apikey
2. Click "Create API Key"
3. Copy the key

---

## STEP 2: Add Key to ai_service.dart

Open `lib/modules/ai/services/ai_service.dart` and replace:

```dart
static const String _apiKey = 'YOUR_GEMINI_API_KEY';
```

With your actual key:

```dart
static const String _apiKey = 'AIzaSy...your_actual_key...';
```

---

## STEP 3: Add http package to pubspec.yaml

Add this under `dependencies:` in pubspec.yaml:

```yaml
dependencies:
  http: ^1.2.0
```

Then run:
```
flutter pub get
```

---

## STEP 4: Add Customer Chat Widget to Welcome Screen

In `lib/features/home/presentation/welcome_screen.dart`, wrap your Scaffold body in a Stack and add the widget:

```dart
import '../../../modules/ai/ui/customer_chat_widget.dart';

// In your build method:
return Scaffold(
  body: Stack(
    children: [
      // Your existing content...
      YourExistingWidget(),
      
      // Add chat bubble bottom-right:
      Positioned(
        bottom: 20,
        right: 20,
        child: CustomerChatWidget(
          businessId: 'YOUR_BUSINESS_ID',
          businessName: 'Your Business Name',
        ),
      ),
    ],
  ),
);
```

---

## HOW IT WORKS

1. Customer opens chat bubble
2. AI loads business context from Firestore (services, hours, info)
3. Customer asks questions
4. Gemini generates contextual responses
5. Conversation saved to Firestore under `businesses/{id}/chat_sessions/`

---

## FEATURES
- ✅ Business-aware AI (reads your services, hours, contact info)
- ✅ Conversation history (persisted in Firestore)
- ✅ Suggested quick questions by business category
- ✅ Loading typing indicator
- ✅ Customer chat bubble widget
- ✅ Admin full-screen chat view
- ✅ Error handling & timeouts
- ✅ Safety filters via Gemini settings
