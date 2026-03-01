// lib/modules/ai/services/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class AiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Replace with your actual Gemini API key ───────────────
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  // ─── Build business context for AI ─────────────────────────
  Future<String> _buildBusinessContext(String businessId) async {
    try {
      // Fetch business info
      final bizDoc =
          await _firestore.collection('businesses').doc(businessId).get();
      final biz = bizDoc.data();
      if (biz == null) return 'You are a helpful business assistant.';

      // Fetch services
      final servicesSnap = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .get();

      final services = servicesSnap.docs.map((d) {
        final s = d.data();
        return '- ${s['name']}: \$${s['price']} (${s['durationMinutes']} min)${s['description'] != null ? ' — ${s['description']}' : ''}';
      }).join('\n');

      // Fetch business hours
      final hoursDoc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('hours')
          .get();

      String hoursText = '';
      if (hoursDoc.exists) {
        final h = hoursDoc.data()!;
        final days = [
          'monday', 'tuesday', 'wednesday', 'thursday',
          'friday', 'saturday', 'sunday'
        ];
        hoursText = days.map((day) {
          final d = h[day] as Map<String, dynamic>?;
          if (d == null) return '';
          final isOpen = d['isOpen'] as bool? ?? false;
          if (!isOpen) return '- ${day[0].toUpperCase()}${day.substring(1)}: Closed';
          return '- ${day[0].toUpperCase()}${day.substring(1)}: ${d['openTime']} - ${d['closeTime']}';
        }).where((s) => s.isNotEmpty).join('\n');
      }

      return '''
You are an AI customer assistant for ${biz['name']}, a ${biz['category']} business.

BUSINESS INFORMATION:
- Name: ${biz['name']}
- Category: ${biz['category']}
- Description: ${biz['description'] ?? 'N/A'}
- Phone: ${biz['phone'] ?? 'N/A'}
- Email: ${biz['email'] ?? 'N/A'}
- Address: ${[biz['address'], biz['city'], biz['state']].where((v) => v != null && v.toString().isNotEmpty).join(', ')}
- Website: ${biz['website'] ?? 'N/A'}

SERVICES OFFERED:
${services.isEmpty ? 'No services listed yet.' : services}

BUSINESS HOURS:
${hoursText.isEmpty ? 'Hours not set.' : hoursText}

YOUR JOB:
- Answer customer questions about services, prices, and availability
- Be friendly, professional, and helpful
- Guide customers toward booking an appointment
- If asked about booking, tell them to use the "Book Now" button
- Keep responses concise and conversational
- If you don't know something, say so honestly
- Always represent the business in a positive way

IMPORTANT: You only answer questions related to this business. For unrelated topics, politely redirect to business topics.
''';
    } catch (e) {
      return 'You are a helpful business assistant. Be friendly and professional.';
    }
  }

  // ─── Send message to Gemini ─────────────────────────────────
  Future<String> sendMessage({
    required String businessId,
    required List<ChatMessage> history,
    required String userMessage,
  }) async {
    try {
      final systemContext = await _buildBusinessContext(businessId);

      // Build conversation history for Gemini
      final contents = <Map<String, dynamic>>[];

      // Add history (skip loading messages)
      for (final msg in history) {
        if (!msg.isLoading && msg.content.isNotEmpty) {
          contents.add(msg.toGeminiPart());
        }
      }

      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ],
      });

      final body = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemContext}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 512,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
        ],
      });

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
        return text?.trim() ??
            "I'm sorry, I couldn't generate a response. Please try again.";
      } else if (response.statusCode == 400) {
        return "I'm having trouble understanding that. Could you rephrase your question?";
      } else if (response.statusCode == 429) {
        return "I'm getting too many requests right now. Please try again in a moment.";
      } else {
        return "I'm temporarily unavailable. Please try again shortly.";
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return "The request timed out. Please check your connection and try again.";
      }
      return "I'm having technical difficulties. Please try again.";
    }
  }

  // ─── Save chat history to Firestore ────────────────────────
  Future<void> saveChatHistory({
    required String businessId,
    required String sessionId,
    required List<ChatMessage> messages,
  }) async {
    try {
      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('chat_sessions')
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'businessId': businessId,
        'messages': messages
            .where((m) => !m.isLoading)
            .map((m) => m.toMap())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messageCount': messages.where((m) => !m.isLoading).length,
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-critical — don't throw
    }
  }

  // ─── Load chat history ──────────────────────────────────────
  Future<List<ChatMessage>> loadChatHistory({
    required String businessId,
    required String sessionId,
  }) async {
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('chat_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) return [];
      final messages = doc.data()?['messages'] as List<dynamic>? ?? [];
      return messages
          .map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Get suggested questions based on business ─────────────
  List<String> getSuggestedQuestions(String category) {
    final Map<String, List<String>> suggestions = {
      'Beauty & Wellness': [
        'What services do you offer?',
        'How much does a haircut cost?',
        'Do you offer appointments on weekends?',
        'How long does a color treatment take?',
      ],
      'Health & Fitness': [
        'What classes do you have?',
        'What are your membership options?',
        'Do you offer personal training?',
        'What are your opening hours?',
      ],
      'Medical & Dental': [
        'Do you accept new patients?',
        'What insurance do you accept?',
        'How do I book an appointment?',
        'What are your office hours?',
      ],
      'default': [
        'What services do you offer?',
        'What are your hours?',
        'How can I book an appointment?',
        'What are your prices?',
      ],
    };
    return suggestions[category] ?? suggestions['default']!;
  }
}
