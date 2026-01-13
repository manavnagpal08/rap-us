import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get or Create a Chat ID between two users
  String getChatId(String userA, String userB) {
    return userA.compareTo(userB) < 0 ? '${userA}_$userB' : '${userB}_$userA';
  }

  // Send a message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
    String? senderName,
    String? receiverName,
    String? receiverId,
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'content': content,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document for list view previews
    final Map<String, dynamic> updateData = {
      'lastMessage': content,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': chatId.split('_'),
    };

    if (senderName != null && receiverName != null && receiverId != null) {
      updateData['displayNames'] = {
        senderId: senderName,
        receiverId: receiverName,
      };
    }

    await _db.collection('chats').doc(chatId).set(updateData, SetOptions(merge: true));
  }

  // Stream messages for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots();
  }
  // Stream users chats
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db.collection('chats')
      .where('participants', arrayContains: userId)
      .snapshots();
  }
}
