// lib/core/models/chat_message_model.dart

enum MessageRole { user, assistant, system }

class ChatMessageModel {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
  });

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      isError: map['isError'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'conversationId': conversationId,
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}