# AI CHAT SETUP - GOOGLE GEMINI API

## 🔑 **GET YOUR API KEY:**

1. Go to: **https://makersuite.google.com/app/apikey**
2. Sign in with your Google account
3. Click **"Get API key"** or **"Create API key"**
4. Copy your API key

---

## 📝 **ADD API KEY TO YOUR PROJECT:**

### **Option 1: Environment Variable (.env file)**

1. Open/create `.env` file in project root:
   ```
   D:\FlacronCV\.env
   ```

2. Add this line:
   ```
   GEMINI_API_KEY=YOUR_ACTUAL_API_KEY_HERE
   ```

3. Update `ai_chat_service.dart`:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   static String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
   ```

### **Option 2: Direct Replacement (Quick Test)**

1. Open `ai_chat_service.dart`
2. Replace this line:
   ```dart
   static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
   ```
   
   With:
   ```dart
   static const String _geminiApiKey = 'AIzaSyC...'; // Your actual key
   ```

⚠️ **IMPORTANT:** Never commit API keys to Git! Add `.env` to `.gitignore`

---

## 🧪 **TEST THE AI:**

1. Run the app
2. Navigate to **AI Assistant** from the dashboard
3. Try these prompts:
   - "How do I track employee attendance?"
   - "Show me today's bookings summary"
   - "What are my pending invoices?"

---

## 💰 **PRICING (as of 2024):**

Google Gemini API Free Tier:
- **60 requests per minute**
- **Free for testing & development**
- Pay-as-you-go after free tier

Check current pricing: https://ai.google.dev/pricing

---

## 🔧 **TROUBLESHOOTING:**

### Error: "API key not valid"
- Double-check your API key is correct
- Make sure there are no extra spaces
- Verify the key is enabled in Google AI Studio

### Error: "Network error"
- Check internet connection
- Verify firewall/proxy settings
- Ensure `http` package is in `pubspec.yaml`

### Error: "Rate limit exceeded"
- You've hit the 60 requests/min limit
- Wait a minute and try again
- Consider upgrading to paid tier

---

## 🚀 **ADVANCED: Using Claude API Instead**

If you prefer Claude API (Anthropic):

1. Get API key: https://console.anthropic.com/
2. Replace endpoint in `ai_chat_service.dart`:
   ```dart
   static const String _apiEndpoint = 
       'https://api.anthropic.com/v1/messages';
   ```

---

## 📚 **RESOURCES:**

- Google AI Studio: https://makersuite.google.com
- Gemini API Docs: https://ai.google.dev/docs
- Flutter dotenv: https://pub.dev/packages/flutter_dotenv