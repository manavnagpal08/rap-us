import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rap_app/services/chat_service.dart';
import 'package:rap_app/services/auth_service.dart'; // Import AuthService
import 'package:rap_app/screens/chat_screen.dart';
import 'package:rap_app/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();
    final AuthService auth = AuthService(); // Instantiate AuthService
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: AppTheme.webBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatService.getUserChats(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final chat = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    final participants = List<String>.from(chat['participants'] ?? []);
                    final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => 'Unknown');
                    
                    // In a real app, fetch user details (name/avatar) using otherUserId
                    // For now, we'll try to extract it from the chat ID or use a placeholder if not stored
                    // Ideally, store participantNames in the chat document
                    String displayName = 'User';
                    if (chat['participants'] != null && chat['participants'].contains(otherUserId)) {
                         // Fallback logic or future implementation
                         displayName = 'Chat Participant'; 
                    }

                    final Timestamp? ts = chat['lastTimestamp'] as Timestamp?;
                    final time = ts != null ? DateFormat('MMM dd, hh:mm a').format(ts.toDate()) : '';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        title: Text(displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          chat['lastMessage'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                        trailing: Text(time, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400])),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                otherUserId: otherUserId,
                                otherUserName: displayName, 
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              Text('Your conversations', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}
