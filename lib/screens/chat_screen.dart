import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/chat_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  
  String? _chatId;
  String? _currentUserId;
  bool _isSendingImage = false;
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

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || _chatId == null || _currentUserId == null) return;

    setState(() => _isSendingImage = true);

    try {
      final String path = 'chats/$_chatId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      String? imageUrl;
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        imageUrl = await _db.uploadData(path, bytes);
      } else {
        imageUrl = await _db.uploadFile(path, File(image.path));
      }

      if (imageUrl != null) {
        _chatService.sendMessage(
          chatId: _chatId!,
          senderId: _currentUserId!,
          senderName: _auth.currentUser?.displayName ?? 'User',
          receiverName: widget.otherUserName,
          receiverId: widget.otherUserId,
          content: imageUrl,
          type: 'image',
        );
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(_chatId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    final messages = snapshot.data!.docs;
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
                        final String? type = msg['type'];
                        
                        return _buildMessageBubble(messages[index].id, msg, isMe, type);
                      },
                    );
                  },
                ),
              ),
              if (_isSendingImage)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SpinKitThreeBounce(color: Color(0xFF0055FF), size: 20),
                      const SizedBox(width: 12),
                      Text('Sending photo...', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                    ],
                  ),
                ),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildMessageBubble(String docId, Map<String, dynamic> msg, bool isMe, String? type) {
    final time = msg['timestamp'] != null ? DateFormat('hh:mm a').format((msg['timestamp'] as Timestamp).toDate()) : '...';
    final hasTranslation = _translations.containsKey(docId);
    final displayContent = hasTranslation ? _translations[docId]! : msg['content'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (type == 'image')
              _buildImageMessage(msg['content'], isMe)
            else
              _buildTextMessage(docId, msg['content'], displayContent, isMe, hasTranslation),
            
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0),
              child: Text(time, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildTextMessage(String docId, String originalContent, String displayContent, bool isMe, bool hasTranslation) {
    return GestureDetector(
      onLongPress: () => !isMe ? _translateMessage(docId, originalContent) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          gradient: isMe ? const LinearGradient(colors: [Color(0xFF0055FF), Color(0xFF0088FF)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: isMe ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomLeft: isMe ? const Radius.circular(24) : Radius.zero, 
            bottomRight: isMe ? Radius.zero : const Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(color: (isMe ? const Color(0xFF0055FF) : Colors.black).withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 5)),
          ],
          border: isMe ? null : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayContent,
              style: GoogleFonts.inter(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.5, fontSize: 15),
            ),
            if (hasTranslation)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate, size: 12, color: isMe ? Colors.white70 : Theme.of(context).primaryColor),
                    const SizedBox(width: 6),
                    Text('Translated', style: GoogleFonts.inter(fontSize: 10, color: isMe ? Colors.white70 : Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage(String url, bool isMe) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: url,
          placeholder: (context, url) => Container(
            height: 200, width: 200, 
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            child: const Center(child: SpinKitPulse(color: Color(0xFF0055FF))),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _pickAndSendImage,
              icon: Icon(Icons.add_photo_alternate_rounded, color: Theme.of(context).primaryColor, size: 28),
              tooltip: 'Send Photo',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurface),
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
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0055FF), Color(0xFF0088FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF0055FF).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
