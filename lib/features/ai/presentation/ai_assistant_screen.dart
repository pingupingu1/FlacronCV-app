// lib/features/ai/presentation/ai_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
class AiAssistantScreen extends StatefulWidget {
  final String businessId;
  const AiAssistantScreen({super.key, required this.businessId});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}
class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isLoading = false;
  GenerativeModel? _model;
  ChatSession? _chat;
  String _businessContext = '';
  static const _apiKey = 'YOUR_GEMINI_API_KEY';
  @override
  void initState() { super.initState(); _initAI(); }
  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }
  Future<void> _initAI() async {
    await _loadBusinessContext();
    _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);
    _chat = _model!.startChat(history: [
      Content.text('You are a helpful AI assistant. Business info: $_businessContext. Help customers with services, pricing, bookings. Be friendly and professional.'),
      Content.model([TextPart('Understood! Ready to help customers.')]),
    ]);
    setState(() { _messages.add(_ChatMessage(text: 'Hi! I am your AI assistant. How can I help you today?', isUser: false)); });
  }
  Future<void> _loadBusinessContext() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final snap = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).collection('services').get();
      final services = snap.docs.map((d) { final s = d.data(); return s['name'].toString() + ' - ' + s['price'].toString(); }).join(', ');
      _businessContext = 'Business: ${data['businessName']}, Services: $services';
    } catch (_) {}
  }
  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading || _chat == null) return;
    setState(() { _messages.add(_ChatMessage(text: text, isUser: true)); _isLoading = true; _msgCtrl.clear(); });
    _scrollToBottom();
    try {
      final response = await _chat!.sendMessage(Content.text(text));
      setState(() { _messages.add(_ChatMessage(text: response.text ?? 'Sorry, try again.', isUser: false)); _isLoading = false; });
    } catch (e) {
      setState(() { _messages.add(_ChatMessage(text: 'Connection error. Please try again.', isUser: false)); _isLoading = false; });
    }
    _scrollToBottom();
  }
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('AI Assistant'), backgroundColor: Colors.orange[700], foregroundColor: Colors.white),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_isLoading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == _messages.length) return const Padding(padding: EdgeInsets.all(8), child: Row(children: [SizedBox(width: 8), CircularProgressIndicator(strokeWidth: 2)]));
            final msg = _messages[i];
            return Align(
              alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isUser ? Colors.orange[700] : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                ),
                child: Text(msg.text, style: TextStyle(color: msg.isUser ? Colors.white : Colors.black87, fontSize: 14)),
              ),
            );
          },
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: Colors.white,
          child: Row(children: [
            Expanded(child: TextField(controller: _msgCtrl, onSubmitted: (_) => _sendMessage(), decoration: InputDecoration(hintText: 'Ask me anything...', filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
            const SizedBox(width: 10),
            GestureDetector(onTap: _sendMessage, child: Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.orange[700], shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
          ]),
        ),
      ]),
    );
  }
}
class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

