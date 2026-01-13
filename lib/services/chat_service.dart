import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  }) async {
    await _db.collection('chats').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'content': content,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update last message in chat document for list view previews
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': content,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': chatId.split('_'),
    }, SetOptions(merge: true));
  }

  // Stream messages for a specific chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  // Stream users chats
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db.collection('chats')
      .where('participants', arrayContains: userId)
      .orderBy('lastTimestamp', descending: true)
      .snapshots();
  }
}
