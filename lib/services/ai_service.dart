// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  // Get Cloud Functions endpoint from .env
  static final String _endpoint = dotenv.env['API_BASE_URL'] ?? 
      'https://us-central1-flacroncv.cloudfunctions.net';
  
  static const String _geminiChatFunction = '/geminiChat';

  /// Send a message to the AI assistant and get a response
  /// 
  /// [message] - User's message
  /// [language] - Language code (en, es, ar, etc.)
  /// [businessData] - Business context (services, hours, prices)
  /// [conversationHistory] - Previous messages for context (optional)
  static Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String language,
    required Map<String, dynamic> businessData,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      final url = Uri.parse('$_endpoint$_geminiChatFunction');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'language': language,
          'businessData': businessData,
          'conversationHistory': conversationHistory ?? [],
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('AI service timeout - please try again');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'reply': data['reply'] ?? 'I apologize, I could not generate a response.',
          'suggestedActions': data['suggestedActions'] ?? [],
          'requiresBooking': data['requiresBooking'] ?? false,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to get AI response: ${response.statusCode}',
          'reply': 'I\'m having trouble connecting right now. Please try again.',
        };
      }
    } catch (e) {
      print('AI Service Error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'reply': 'I\'m having trouble connecting right now. Please try again.',
      };
    }
  }

  /// Get suggested questions for the user based on business context
  static Future<List<String>> getSuggestedQuestions({
    required String businessId,
    required String language,
  }) async {
    try {
      final url = Uri.parse('$_endpoint/getSuggestedQuestions');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'businessId': businessId,
          'language': language,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['questions'] ?? []);
      }
      return [];
    } catch (e) {
      print('Error getting suggested questions: $e');
      return [];
    }
  }

  /// Analyze user intent to determine if they want to book
  static bool detectBookingIntent(String message) {
    final bookingKeywords = [
      'book', 'appointment', 'schedule', 'reserve', 'availability',
      'available', 'time', 'slot', 'reservation', 'when can i',
    ];
    
    final lowerMessage = message.toLowerCase();
    return bookingKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Format business data for AI context
  static Map<String, dynamic> formatBusinessContext({
    required String businessName,
    required List<Map<String, dynamic>> services,
    required Map<String, dynamic> businessHours,
    String? location,
    String? phone,
  }) {
    return {
      'businessName': businessName,
      'services': services.map((s) => {
        'name': s['name'],
        'price': s['price'],
        'duration': s['duration'],
        'description': s['description'],
      }).toList(),
      'businessHours': businessHours,
      'location': location ?? 'Not specified',
      'phone': phone ?? 'Not specified',
    };
  }
}