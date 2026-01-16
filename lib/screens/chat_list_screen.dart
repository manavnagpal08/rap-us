import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rap_app/l10n/app_localizations.dart';
import 'package:rap_app/services/chat_service.dart';
import 'package:rap_app/services/auth_service.dart'; // Import AuthService
import 'package:rap_app/screens/chat_screen.dart';
import 'package:rap_app/screens/marketplace_screen.dart'; // Added import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ChatService chatService = ChatService();
    final AuthService auth = AuthService(); // Instantiate AuthService
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          final docs = snapshot.data!.docs;
          // Client-side sorting
          docs.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width > 600 ? 24 : 16,
              40, // Top Padding
              MediaQuery.of(context).size.width > 600 ? 24 : 16,
              24,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final chat = docs[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => 'Unknown');
              
              final displayNames = chat['displayNames'] as Map<String, dynamic>?;
              String displayName = displayNames?[otherUserId] ?? 'Chat Participant';

              final Timestamp? ts = chat['lastTimestamp'] as Timestamp?;
              final time = ts != null ? DateFormat('MMM dd').format(ts.toDate()) : '';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.05))
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  subtitle: Text(
                    chat['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Theme.of(context).hintColor),
                  ),
                  trailing: Text(time, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor.withValues(alpha: 0.5))),
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
    );
  }

  Widget _buildEmptyState(BuildContext context, l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mark_chat_unread_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(l10n.noMessages, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 12),
          Text(
            l10n.noMessagesSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
            icon: const Icon(Icons.add_comment_rounded, size: 20),
            label: Text(l10n.startFirstChat),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

}
