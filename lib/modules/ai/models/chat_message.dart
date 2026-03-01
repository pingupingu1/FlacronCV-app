// lib/modules/ai/models/chat_message.dart

enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );

  factory ChatMessage.assistant(String content, {bool isLoading = false}) =>
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isLoading: isLoading,
      );

  factory ChatMessage.loading() => ChatMessage(
        id: 'loading',
        content: '',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        isLoading: true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'role': role.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] ?? '',
        content: map['content'] ?? '',
        role: MessageRole.values.firstWhere(
          (r) => r.name == map['role'],
          orElse: () => MessageRole.user,
        ),
        timestamp: DateTime.parse(
            map['timestamp'] ?? DateTime.now().toIso8601String()),
      );

  // Convert to Gemini API format
  Map<String, dynamic> toGeminiPart() => {
        'role': role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': content}
        ],
      };
}
