import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/services/database_service.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupChatId;
  final String jobTitle;

  const GroupChatScreen({
    super.key,
    required this.groupChatId,
    required this.jobTitle,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) return;

    _db.sendGroupMessage(
      widget.groupChatId,
      _currentUserId!,
      _messageController.text.trim(),
      _auth.currentUser?.displayName ?? 'Team Member',
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Team', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.jobTitle, style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 12)),
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _db.getGroupMessages(widget.groupChatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 48, color: Theme.of(context).hintColor),
                        const SizedBox(height: 16),
                        Text('Project Chat', style: GoogleFonts.outfit(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                        Text('Coordinate with your project team here.', style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == _currentUserId;
                    final time = msg['timestamp'] != null ? DateFormat('hh:mm a').format((msg['timestamp'] as Timestamp).toDate()) : '';
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(20).copyWith(
                                  bottomLeft: isMe ? null : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : null,
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        msg['senderName'] ?? 'Team Member',
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                      ),
                                    ),
                                  Text(
                                    msg['text'] ?? '',
                                    style: GoogleFonts.inter(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(time, style: GoogleFonts.inter(fontSize: 10, color: Theme.of(context).hintColor)),
                          ],
                        ),
                      ).animate().fadeIn().slideX(begin: isMe ? 0.2 : -0.2, end: 0),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
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
                    hintText: 'Message team...',
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
              mini: true,
              elevation: 0,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
