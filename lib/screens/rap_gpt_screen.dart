import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class RapGptScreen extends StatefulWidget {
  const RapGptScreen({super.key});

  @override
  State<RapGptScreen> createState() => _RapGptScreenState();
}

class _RapGptScreenState extends State<RapGptScreen> {
  final TextEditingController _controller = TextEditingController();
  final AiService _ai = AiService();
  final List<Map<String, String>> _messages = []; // {role: 'user'|'model', text: '...'}
  bool _isLoading = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();

    final response = await _ai.chatWithExpert(text, _messages);

    setState(() {
      _messages.add({'role': 'model', 'text': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark/Technical theme
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            const Icon(Icons.psychology_alt, color: Color(0xFF00FF9D)),
            const SizedBox(width: 8),
            Text('RAP-GPT', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, size: 60, color: Color(0xFF00FF9D)),
                      const SizedBox(height: 16),
                      Text('Ask me anything about repairs.', style: GoogleFonts.inter(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('"How do I fix a leaky p-trap?"', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic)),
                    ],
                  ).animate().fadeIn(),
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0055FF) : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? Radius.zero : null,
                        bottomLeft: !isUser ? Radius.zero : null,
                      ),
                      border: !isUser ? Border.all(color: const Color(0xFF333333)) : null,
                    ),
                    child: isUser 
                      ? Text(_messages[index]['text']!, style: GoogleFonts.inter(color: Colors.white))
                      : MarkdownBody(
                          data: _messages[index]['text']!,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(color: Colors.white),
                            strong: GoogleFonts.inter(color: const Color(0xFF00FF9D), fontWeight: FontWeight.bold),
                            listBullet: GoogleFonts.inter(color: const Color(0xFF00FF9D)),
                          ),
                        ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFF00FF9D), backgroundColor: Colors.transparent),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(top: BorderSide(color: Color(0xFF333333))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF00FF9D)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
