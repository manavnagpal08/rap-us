import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class RapGptSheet extends StatefulWidget {
  const RapGptSheet({super.key});

  @override
  State<RapGptSheet> createState() => _RapGptSheetState();
}

class _RapGptSheetState extends State<RapGptSheet> {
  final TextEditingController _controller = TextEditingController();
  final AiService _ai = AiService();
  final List<Map<String, String>> _messages = []; 
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

    if (mounted) {
      setState(() {
        _messages.add({'role': 'model', 'text': response});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism Bottom Sheet
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75, // 75% Height
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            border: Border.all(color: const Color(0xFF00FF9D).withOpacity(0.2)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00FF9D).withOpacity(0.1), blurRadius: 40, spreadRadius: 5),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle & Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                     const Icon(Icons.psychology_alt, color: Color(0xFF00FF9D), size: 28).animate(onPlay: (c) => c.repeat(reverse: true)).glow(color: const Color(0xFF00FF9D), radius: 20),
                     const SizedBox(width: 12),
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('RAP-GPT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                           Text('Expert Construction AI', style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12)),
                         ],
                       ),
                     ),
                     IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF333333)),

              // Messages
              Expanded(
                child: _messages.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.terminal, size: 64, color: const Color(0xFF00FF9D).withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text('Ready to assist.', style: GoogleFonts.inter(color: Colors.grey[500])),
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
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF00FF9D).withOpacity(0.1) : const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isUser ? Radius.zero : null,
                                bottomLeft: !isUser ? Radius.zero : null,
                              ),
                              border: Border.all(color: isUser ? const Color(0xFF00FF9D).withOpacity(0.3) : const Color(0xFF333333)),
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

              // Input
              if (_isLoading)
                const LinearProgressIndicator(color: Color(0xFF00FF9D), backgroundColor: Colors.transparent),
                
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), // More padding at bottom
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
                          hintText: 'Ask technical question...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          fillColor: const Color(0xFF222222),
                          filled: true,
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF00FF9D), width: 1)),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF00FF9D),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
