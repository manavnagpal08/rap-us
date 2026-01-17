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
  Map<String, String> _translations = {};

  Future<void> _translateMessage(String id, String content) async {
    final target = Localizations.localeOf(context).languageCode;
    final translated = await _chatService.translateText(content, to: target);
    if (mounted) {
      setState(() {
        _translations[id] = translated;
      });
    }
  }

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
      senderName: _auth.currentUser?.displayName ?? 'User',
      receiverName: widget.otherUserName,
      receiverId: widget.otherUserId,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.otherUserName, style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text('Online', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface),
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
                          decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.05), shape: BoxShape.circle),
                          child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.outfit(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        Text('Say hello to start the conversation!', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor)),
                      ],
                    ),
                  ).animate().fadeIn();
                }

                final messages = snapshot.data!.docs;
                // Client-side sort to fix index issue
                messages.sort((a, b) {
                  final tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUserId;
                    final time = msg['timestamp'] != null ? DateFormat('hh:mm a').format((msg['timestamp'] as Timestamp).toDate()) : '...';
                    
                    final hasTranslation = _translations.containsKey(messages[index].id);
                    final displayContent = hasTranslation ? _translations[messages[index].id]! : msg['content'];

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onLongPress: () => !isMe ? _translateMessage(messages[index].id, msg['content']) : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                decoration: BoxDecoration(
                                  color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(22).copyWith(
                                    bottomLeft: isMe ? 22 : 0, 
                                    bottomRight: isMe ? 0 : 22,
                                  ),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayContent,
                                      style: GoogleFonts.inter(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.4),
                                    ),
                                    if (hasTranslation)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.translate, size: 10, color: isMe ? Colors.white70 : Theme.of(context).primaryColor),
                                            const SizedBox(width: 4),
                                            Text('Translated', style: GoogleFonts.inter(fontSize: 10, color: isMe ? Colors.white70 : Theme.of(context).primaryColor)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isMe && !hasTranslation)
                               Padding(
                                 padding: const EdgeInsets.only(top: 2, left: 4),
                                 child: GestureDetector(
                                   onTap: () => _translateMessage(messages[index].id, msg['content']),
                                   child: Text('Translate', style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                 ),
                               ),
                            const SizedBox(height: 4),
                            Text(time, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor)),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: Theme.of(context).hintColor),
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
