import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/chat_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();
  String? _chatId;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _chatId = _chatService.getChatId(_currentUserId!, widget.otherUserId);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _chatId == null || _currentUserId == null) return;

    _chatService.sendMessage(
      chatId: _chatId!,
      senderId: _currentUserId!,
      content: _messageController.text.trim(),
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_chatId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not authenticated")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('Online', style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(_chatId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                   return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                        Text('Say hello to start the conversation!', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ).animate().fadeIn();
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId;
                    final Timestamp? ts = msg['timestamp'] as Timestamp?;
                    final time = ts != null ? DateFormat('hh:mm a').format(ts.toDate()) : 'Sending...';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 4, top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              gradient: isMe ? LinearGradient(colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.8)]) : null,
                              color: isMe ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              msg['content'],
                              style: GoogleFonts.inter(color: isMe ? Colors.white : const Color(0xFF1E293B), height: 1.5),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, right: 4),
                            child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                          ),
                        ],
                      ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 200.ms),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    backgroundColor: AppTheme.primary,
                    elevation: 0,
                    mini: true,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
