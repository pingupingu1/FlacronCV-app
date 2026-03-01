// lib/core/services/ai_chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message_model.dart';

class AiChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Replace with your actual Google Gemini API key
  // Get it from: https://makersuite.google.com/app/apikey
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // ═══════════════════════════════════════════════════════
  // SEND MESSAGE TO AI
  // ═══════════════════════════════════════════════════════
  Future<String> sendMessage(String message, String conversationId) async {
    try {
      // Get conversation history for context
      final history = await getConversationHistory(conversationId);
      
      // Build context
      final contextMessages = history
          .map((msg) => '${msg.role.name}: ${msg.content}')
          .join('\n');

      // System prompt for business assistant
      final systemPrompt = '''
You are FlacronControl AI Assistant, a helpful business management assistant.
You help business owners with:
- Managing bookings and appointments
- Tracking employee attendance and payroll
- Handling invoices and payments
- Business insights and recommendations
- General business queries

Be concise, professional, and helpful. Provide actionable advice.

Conversation history:
$contextMessages

User: $message
''';

      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': systemPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return aiResponse.trim();
      } else {
        throw Exception('AI API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get AI response: $e');
    }
  }

  // ═══════════════════════════════════════════════════════
  // SAVE MESSAGE TO FIRESTORE
  // ═══════════════════════════════════════════════════════
  Future<ChatMessageModel> saveMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    bool isError = false,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .doc();

    final message = ChatMessageModel(
      id: docRef.id,
      conversationId: conversationId,
      role: role,
      content: content,
      timestamp: DateTime.now(),
      isError: isError,
    );

    await docRef.set(message.toMap());
    return message;
  }

  // ═══════════════════════════════════════════════════════
  // STREAM CONVERSATION
  // ═══════════════════════════════════════════════════════
  Stream<List<ChatMessageModel>> streamConversation(String conversationId) {
    final userId = _auth.currentUser?.uid ?? 'guest';
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  // ═══════════════════════════════════════════════════════
  // GET CONVERSATION HISTORY
  // ═══════════════════════════════════════════════════════
  Future<List<ChatMessageModel>> getConversationHistory(
      String conversationId) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .limit(10) // Last 10 messages for context
        .get();

    return snap.docs
        .map((d) => ChatMessageModel.fromMap(d.data(), d.id))
        .toList();
  }

  // ═══════════════════════════════════════════════════════
  // DELETE CONVERSATION
  // ═══════════════════════════════════════════════════════
  Future<void> deleteConversation(String conversationId) async {
    final userId = _auth.currentUser?.uid ?? 'guest';
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_messages')
        .where('conversationId', isEqualTo: conversationId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════
  // SUGGESTED PROMPTS
  // ═══════════════════════════════════════════════════════
  List<String> getSuggestedPrompts() => [
        'How do I track employee attendance?',
        'Show me today\'s bookings summary',
        'What are my pending invoices?',
        'How can I improve my business revenue?',
        'Help me with payroll calculations',
      ];
}