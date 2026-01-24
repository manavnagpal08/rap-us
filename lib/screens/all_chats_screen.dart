import 'package:rap_app/services/chat_service.dart';
import 'package:rap_app/services/auth_service.dart';
import 'package:rap_app/screens/chat_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllChatsScreen extends StatefulWidget {
  const AllChatsScreen({super.key});

  @override
  State<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen> {
  final ChatService _chatService = ChatService();
  final DatabaseService _db = DatabaseService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please log in to see your chats.'));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserChats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Theme.of(context).hintColor.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: GoogleFonts.inter(color: Theme.of(context).hintColor, fontSize: 16)),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;
          
          // Client-side sorting
          chats.sort((a, b) {
            final tA = (a.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
            final tB = (b.data() as Map<String, dynamic>)['lastTimestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final participants = List<String>.from(chat['participants'] ?? []);
              final otherId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
              
              final displayNames = chat['displayNames'] as Map<String, dynamic>?;
              final name = displayNames?[otherId] ?? 'User';
              final lastMessage = chat['lastMessage'] ?? 'No messages yet';
              final timestamp = chat['lastTimestamp'] as Timestamp?;
              final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

              return InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                    otherUserId: otherId,
                    otherUserName: name,
                  )));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(timeStr, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).hintColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 14, color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05);
            },
          );
        },
      ),
    );
  }
}
