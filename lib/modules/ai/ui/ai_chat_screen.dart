// lib/modules/ai/ui/ai_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? businessId;
  const AiChatScreen({super.key, this.businessId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _aiService = AiService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _businessId;
  String? _businessName;
  String? _businessCategory;
  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId =
        'session_${DateTime.now().millisecondsSinceEpoch}';
    _init();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Resolve businessId
    String? bizId = widget.businessId;
    if (bizId == null || bizId.isEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        bizId = userDoc.data()?['businessId'] as String?;
      }
    }

    if (bizId != null && bizId.isNotEmpty) {
      final bizDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(bizId)
          .get();
      final biz = bizDoc.data();
      if (mounted) {
        setState(() {
          _businessId = bizId;
          _businessName = biz?['name'] as String? ?? 'Your Business';
          _businessCategory = biz?['category'] as String? ?? 'default';
        });
      }

      // Load previous session or show welcome
      final history = await _aiService.loadChatHistory(
        businessId: bizId,
        sessionId: _sessionId,
      );

      if (mounted) {
        if (history.isEmpty) {
          _addWelcomeMessage();
        } else {
          setState(() => _messages = history);
        }
      }
    } else {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcome = ChatMessage.assistant(
      "👋 Hi! I'm your AI assistant for ${_businessName ?? 'this business'}. "
      "I can help answer questions about our services, pricing, and availability. "
      "How can I help you today?",
    );
    if (mounted) setState(() => _messages = [welcome]);
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _textController.clear();
    _focusNode.requestFocus();

    final userMsg = ChatMessage.user(trimmed);
    final loadingMsg = ChatMessage.loading();

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        businessId: _businessId ?? '',
        history: _messages
            .where((m) => !m.isLoading)
            .toList()
          ..removeLast(), // remove user msg since we pass it separately
        userMessage: trimmed,
      );

      final assistantMsg = ChatMessage.assistant(response);

      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(assistantMsg);
          _isLoading = false;
        });
      }

      // Save to Firestore
      if (_businessId != null) {
        await _aiService.saveChatHistory(
          businessId: _businessId!,
          sessionId: _sessionId,
          messages: _messages,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.removeWhere((m) => m.isLoading);
          _messages.add(ChatMessage.assistant(
              "I'm sorry, something went wrong. Please try again."));
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    });
    _addWelcomeMessage();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _aiService.getSuggestedQuestions(
        _businessCategory ?? 'default');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Assistant',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                Row(children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _businessName ?? 'Online',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ]),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear chat',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Clear Chat'),
                content: const Text(
                    'Start a new conversation? Your current chat will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearChat();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessage(msg);
                    },
                  ),
          ),

          // Suggested questions (show when few messages)
          if (_messages.length <= 2 && !_isLoading)
            _buildSuggestions(suggestions),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.smart_toy_outlined,
                size: 48, color: Colors.orange[700]),
          ),
          const SizedBox(height: 16),
          const Text('AI Assistant',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Ask me anything about our services',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_outlined,
                  color: Colors.orange[700], size: 16),
            ),
          ],
          Flexible(
            child: Container(
              padding: msg.isLoading
                  ? const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.orange[700] : Colors.white,
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
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: msg.isLoading
                  ? _buildTypingIndicator()
                  : Text(
                      msg.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF1A1A1A),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.person, color: Colors.orange[700], size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.4, end: 1.0),
          duration: Duration(milliseconds: 400 + (i * 150)),
          curve: Curves.easeInOut,
          builder: (_, value, __) => Container(
            margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.orange[300]!.withValues(alpha: value),
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuggestions(List<String> suggestions) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested questions',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500],
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((q) {
                return GestureDetector(
                  onTap: () => _sendMessage(q),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text(q,
                        style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      BorderSide(color: Colors.orange[300]!, width: 1.5),
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(_textController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey[300] : Colors.orange[700],
                shape: BoxShape.circle,
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
