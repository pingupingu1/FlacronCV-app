// lib/modules/ai/ui/customer_chat_widget.dart
// Embeddable chat widget for customer-facing pages

import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class CustomerChatWidget extends StatefulWidget {
  final String businessId;
  final String businessName;

  const CustomerChatWidget({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<CustomerChatWidget> createState() => _CustomerChatWidgetState();
}

class _CustomerChatWidgetState extends State<CustomerChatWidget>
    with SingleTickerProviderStateMixin {
  final _aiService = AiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  List<ChatMessage> _messages = [];
  bool _isOpen = false;
  bool _isLoading = false;
  int _unreadCount = 0;
  final String _sessionId =
      'customer_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOutBack);

    // Add welcome message after short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage.assistant(
            "👋 Hi! I'm the AI assistant for ${widget.businessName}. "
            "Feel free to ask me anything about our services or pricing!",
          ));
          if (!_isOpen) _unreadCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _unreadCount = 0;
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();
    final userMsg = ChatMessage.user(trimmed);

    setState(() {
      _messages.add(userMsg);
      _messages.add(ChatMessage.loading());
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        businessId: widget.businessId,
        history: _messages.where((m) => !m.isLoading).toList(),
        userMessage: trimmed,
      );

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(ChatMessage.assistant(response));
          _isLoading = false;
          if (!_isOpen) _unreadCount++;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isLoading);
          _messages
              .add(ChatMessage.assistant("Sorry, please try again."));
          _isLoading = false;
        });
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Chat window
        if (_isOpen)
          ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: Container(
              width: 340,
              height: 480,
              margin: const EdgeInsets.only(bottom: 70, right: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[700]!,
                          Colors.orange[500]!
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.smart_toy_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.businessName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const Text('AI Assistant • Online',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: _toggleChat,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final msg = _messages[i];
                        final isUser = msg.role == MessageRole.user;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Align(
                            alignment: isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 240),
                              padding: msg.isLoading
                                  ? const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12)
                                  : const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.orange[700]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft:
                                      Radius.circular(isUser ? 14 : 4),
                                  bottomRight:
                                      Radius.circular(isUser ? 4 : 14),
                                ),
                              ),
                              child: msg.isLoading
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [1, 2, 3].map((i) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(right: 3),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: Colors.orange[300],
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: isUser
                                            ? Colors.white
                                            : Colors.grey[800],
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Input
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none),
                            ),
                            onSubmitted: _send,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _send(_textController.text),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // FAB button
        GestureDetector(
          onTap: _toggleChat,
          child: Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[700]!, Colors.orange[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isOpen
                      ? const Icon(Icons.close,
                          color: Colors.white, key: ValueKey('close'))
                      : const Icon(Icons.smart_toy_outlined,
                          color: Colors.white, key: ValueKey('open')),
                ),
              ),
              if (_unreadCount > 0 && !_isOpen)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    child: Center(
                      child: Text('$_unreadCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
