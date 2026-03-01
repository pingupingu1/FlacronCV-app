// lib/modules/ai/ui/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/chat_message_model.dart';
import '../../../core/services/ai_chat_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _chatService = AiChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late String _conversationId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _conversationId = const Uuid().v4();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() => _isLoading = true);
    _messageController.clear();

    try {
      // Save user message
      await _chatService.saveMessage(
        conversationId: _conversationId,
        role: MessageRole.user,
        content: message.trim(),
      );

      // Get AI response
      final aiResponse = await _chatService.sendMessage(
        message.trim(),
        _conversationId,
      );

      // Save AI response
      await _chatService.saveMessage(
        conversationId: _conversationId,
        role: MessageRole.assistant,
        content: aiResponse,
      );

      _scrollToBottom();
    } catch (e) {
      // Save error message
      await _chatService.saveMessage(
        conversationId: _conversationId,
        role: MessageRole.assistant,
        content:
            'Sorry, I encountered an error. Please check your API key and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text(
            'This will delete all messages in this conversation.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _chatService.deleteConversation(_conversationId);
      setState(() => _conversationId = const Uuid().v4());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, size: 22),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.streamConversation(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.orange));
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return _buildWelcome();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) => _buildMessageBubble(messages[i]),
                );
              },
            ),
          ),

          // ── Loading indicator ──
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('AI is thinking...',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),

          // ── Input field ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: Colors.orange[700]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLoading,
                    onSubmitted: (v) => _sendMessage(v),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.orange[700],
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy_outlined,
                size: 80, color: Colors.orange[300]),
            const SizedBox(height: 16),
            const Text('Hi! I\'m your AI Assistant',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Ask me anything about managing your business!',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Text('Try asking:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            ..._chatService
                .getSuggestedPrompts()
                .map((prompt) => _suggestedPromptChip(prompt)),
          ],
        ),
      ),
    );
  }

  Widget _suggestedPromptChip(String prompt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _sendMessage(prompt),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline,
                  color: Colors.orange[700], size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(prompt,
                    style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: Colors.orange[300], size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.role == MessageRole.user;
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor:
                  isError ? Colors.red[100] : Colors.orange[100],
              radius: 16,
              child: Icon(
                isError ? Icons.error_outline : Icons.smart_toy,
                color: isError ? Colors.red[700] : Colors.orange[700],
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.orange[700]
                        : isError
                            ? Colors.red[50]
                            : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isUser ? 16 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : isError
                              ? Colors.red[700]
                              : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.formattedTime,
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 16,
              child: Icon(Icons.person, color: Colors.blue[700], size: 18),
            ),
          ],
        ],
      ),
    );
  }
}