import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // File Upload to Firebase Storage
  Future<String?> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage Error: $e');
      return null;
    }
  }

  // Generic Data Upload (for Signature Bytes)
  Future<String?> uploadData(String path, Uint8List data) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putData(data);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Storage Error: $e');
      return null;
    }
  }
  // Estimates History
  Future<void> saveEstimate(Map<String, dynamic> estimateData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('Firestore Error: No authenticated user found.');
      return;
    }
    
    await _db.collection('users').doc(user.uid).collection('estimates').add({
      ...estimateData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Job Management
  Future<void> createJob(Map<String, dynamic> jobData) async {
    await _db.collection('jobs').add({
      ...jobData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getEstimateHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('estimates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // User Profile & Roles
  Future<void> createUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'role': data['role'] ?? 'user',
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Contractor Marketplace
  Stream<List<Map<String, dynamic>>> getContractors({String? city, String? category}) {
    Query query = _db.collection('contractors');
    if (city != null) query = query.where('city', isEqualTo: city);
    if (category != null) query = query.where('category', isEqualTo: category);
    
    return query.snapshots().map((snapshot) => snapshot.docs.map((doc) => {
      ...doc.data() as Map<String, dynamic>,
      'id': doc.id
    }).toList());
  }

  Future<void> registerContractor(Map<String, dynamic> contractorData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Create contractor document
    await _db.collection('contractors').doc(user.uid).set({
      ...contractorData,
      'userId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': false,
    });

    // Update user role to contractor
    await _db.collection('users').doc(user.uid).update({
      'role': 'contractor',
    });
  }

  // Contractor Features
  Future<Map<String, dynamic>> getContractorStats(String uid) async {
    // In a real app, these would be aggregated queries or counters
    // For now, we will return some mock data stored in the user profile or just calculate it
    final jobs = await _db.collection('jobs').where('contractorId', isEqualTo: uid).get();
    final pendingJobs = jobs.docs.where((doc) => doc.data()['status'] == 'pending').length;
    final activeJobs = jobs.docs.where((doc) => doc.data()['status'] == 'in_progress').length;
    final totalEarnings = jobs.docs.fold(0.0, (currentSum, doc) => currentSum + (doc.data()['amount'] ?? 0.0));

    return {
      'leads': pendingJobs,
      'active': activeJobs,
      'earnings': totalEarnings,
    };
  }

  Stream<List<Map<String, dynamic>>> getContractorJobs(String uid) {
    return _db.collection('jobs')
        .where('contractorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id
          }).toList();
          
          // Sort client-side to avoid composite index requirement
          docs.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime == null) return -1;
            if (bTime == null) return 1;
            // Handle Timestamp or String (if passed as string/date)
            // Assuming Timestamp from Firestore
            try {
              return bTime.compareTo(aTime);
            } catch (e) {
              return 0; 
            }
          });
          
          return docs;
        });
  }

  Stream<List<Map<String, dynamic>>> getCustomerJobs(String customerId) {
    return _db.collection('jobs')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
           final docs = snapshot.docs.map((doc) => {
            ...doc.data(),
            'id': doc.id
          }).toList();
          
          docs.sort((a, b) {
             // Basic sort by descending creation time if available
             return (b['createdAt'] as Timestamp?)?.compareTo(a['createdAt'] as Timestamp? ?? Timestamp.now()) ?? 0;
          });
          return docs;
        });
  }

  Future<void> updateContractorJobStatus(String jobId, String status) async {
    await _db.collection('jobs').doc(jobId).update({'status': status});
  }

  // Profile Management
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    // Update user collection
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
    
    // If contractor, also update contractor collection
    final user = await getUserProfile(uid);
    if (user != null && user['role'] == 'contractor') {
       await _db.collection('contractors').doc(uid).set({
         'name': data['fullName'], 
         // Add other fields if necessary
       }, SetOptions(merge: true));
    }
  }

  // Admin Dashboard Stats
  Future<Map<String, dynamic>> getAdminStats() async {
    final estimates = await _db.collectionGroup('estimates').count().get();
    final contractors = await _db.collection('contractors').count().get();
    
    return {
      'total_estimates': estimates.count,
      'total_contractors': contractors.count,
    };
  }

  // AI Configuration Management
  Future<Map<String, dynamic>> getAiSettings() async {
    final doc = await _db.collection('settings').doc('ai_config').get();
    return doc.data() ?? {
      'active_provider': 'gemini',
      'openai_key': '',
      'gemini_key': '',
      'system_prompt': 'You are a RAP cost estimation assistant...',
    };
  }

  Future<void> updateAiSettings(Map<String, dynamic> settings) async {
    await _db.collection('settings').doc('ai_config').set(settings, SetOptions(merge: true));
  }

  // Prompt Tuning (Dynamic Prompt)
  Future<String?> getSystemPrompt() async {
    final doc = await _db.collection('settings').doc('ai_config').get();
    return doc.data()?['system_prompt'];
  }

  // Insurance & License Verification
  Future<void> requestVerification(String uid, Map<String, dynamic> docs) async {
    await _db.collection('contractors').doc(uid).update({
      'verificationDocs': docs,
      'verificationStatus': 'pending', 
      'isVerified': false, // Now requires admin review
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Digital Contracts
  Future<void> saveDigitalContract(String jobId, Map<String, dynamic> contractData) async {
    await _db.collection('jobs').doc(jobId).update({
      'contract': {
        ...contractData,
        'signedAt': FieldValue.serverTimestamp(),
      }
    });
  }

  // Bidding System
  Future<void> submitBid(String jobId, Map<String, dynamic> bidData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('jobs').doc(jobId).collection('bids').add({
      ...bidData,
      'contractorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<List<Map<String, dynamic>>> getBidsForJob(String jobId) {
    return _db.collection('jobs').doc(jobId).collection('bids')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id
        }).toList());
  }

  Future<void> acceptBid(String jobId, String bidId, String contractorId, double amount) async {
    // 1. Mark bid as accepted
    await _db.collection('jobs').doc(jobId).collection('bids').doc(bidId).update({'status': 'accepted'});
    
    // 2. Reject other bids
    final otherBids = await _db.collection('jobs').doc(jobId).collection('bids').where(FieldPath.documentId, isNotEqualTo: bidId).get();
    for (var doc in otherBids.docs) {
      await doc.reference.update({'status': 'rejected'});
    }

    // 3. Update job with contractor and amount
    await _db.collection('jobs').doc(jobId).update({
      'contractorId': contractorId,
      'amount': amount,
      'status': 'in_progress',
      'acceptedBidId': bidId,
    });
  }

  // Marketplace: Get Public Jobs (Jobs without a contractor)
  Stream<List<Map<String, dynamic>>> getPublicJobs() {
    return _db.collection('jobs')
        .where('contractorId', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id
        }).toList());
  }

  // Referral & Loyalty Systems
  Future<void> generateReferralCode(String uid) async {
    final code = 'RAP${uid.substring(0, 5).toUpperCase()}';
    await _db.collection('users').doc(uid).update({
      'referralCode': code,
    });
  }

  Future<bool> applyReferral(String referralCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if code exists
    final query = await _db.collection('users').where('referralCode', isEqualTo: referralCode).get();
    if (query.docs.isEmpty) return false;

    final referrerId = query.docs.first.id;
    if (referrerId == user.uid) return false; // Can't refer self

    // Award points to both
    await updateUserLoyalty(referrerId, 100); // 100 points for referrer
    await updateUserLoyalty(user.uid, 50);    // 50 points for referred user

    // Save referral record
    await _db.collection('referrals').add({
      'referrerId': referrerId,
      'referredId': user.uid,
      'code': referralCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<void> updateUserLoyalty(String uid, int points) async {
    final doc = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final currentPoints = (snapshot.data()?['loyaltyPoints'] ?? 0) as int;
      transaction.update(doc, {'loyaltyPoints': currentPoints + points});
    });
  }

  // Points Redemption System
  Future<Map<String, dynamic>> redeemPoints(String uid, int points, String rewardType) async {
    final doc = _db.collection('users').doc(uid);
    return await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(doc);
      final currentPoints = (snapshot.data()?['loyaltyPoints'] ?? 0) as int;

      if (currentPoints < points) {
        return {'success': false, 'message': 'Insufficient points'};
      }

      transaction.update(doc, {'loyaltyPoints': currentPoints - points});
      
      // Create redemption record
      final redemptionRef = _db.collection('redemptions').doc();
      transaction.set(redemptionRef, {
        'userId': uid,
        'points': points,
        'rewardType': rewardType,
        'status': 'completed',
        'code': 'REWARD-${DateTime.now().millisecondsSinceEpoch}',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Points redeemed successfully!'};
    });
  }

  // Site Visit Booking
  Future<void> bookSiteVisit(String contractorId, String jobId, DateTime dateTime) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.collection('bookings').add({
      'jobId': jobId,
      'contractorId': contractorId,
      'customerId': user.uid,
      'customerName': user.displayName ?? 'Customer',
      'dateTime': dateTime,
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also update job with visit info
    await _db.collection('jobs').doc(jobId).update({
      'siteVisit': dateTime,
    });
  }

  Stream<List<Map<String, dynamic>>> getContractorBookings(String contractorId) {
    return _db.collection('bookings')
        .where('contractorId', isEqualTo: contractorId)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Project Progress Logs
  Future<void> addProgressLog(String jobId, String note, {String? imageUrl}) async {
    await _db.collection('jobs').doc(jobId).collection('logs').add({
      'note': note,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getProjectLogs(String jobId) {
    return _db.collection('jobs').doc(jobId).collection('logs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Team/Group Chat Management
  Future<String> createTeamChat(String jobId, List<String> memberUids) async {
    final chatRef = await _db.collection('group_chats').add({
      'jobId': jobId,
      'members': memberUids,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Group chat started',
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
    return chatRef.id;
  }

  Future<void> sendGroupMessage(String groupChatId, String senderId, String text, String senderName) async {
    await _db.collection('group_chats').doc(groupChatId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('group_chats').doc(groupChatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getGroupMessages(String groupChatId) {
    return _db.collection('group_chats').doc(groupChatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // AI Accuracy & Change Orders
  Future<void> completeJobWithAccuracy(String jobId, double finalCost) async {
    final docRef = _db.collection('jobs').doc(jobId);
    final doc = await docRef.get();
    final initialEstimate = (doc.data()?['initialAiEstimate'] ?? doc.data()?['amount'] ?? 1.0) as double;
    
    final accuracy = (initialEstimate / finalCost * 100).clamp(0, 100).toInt();

    await docRef.update({
      'status': 'completed',
      'actualFinalCost': finalCost,
      'aiAccuracyBadge': '$accuracy%',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestChangeOrder(String jobId, Map<String, dynamic> data) async {
    await _db.collection('jobs').doc(jobId).collection('changeOrders').add({
      ...data,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> approveChangeOrder(String jobId, String orderId, double newAmount) async {
    await _db.collection('jobs').doc(jobId).collection('changeOrders').doc(orderId).update({
      'status': 'approved',
    });
    
    await _db.collection('jobs').doc(jobId).update({
      'amount': newAmount,
    });
  }

  Stream<List<Map<String, dynamic>>> getChangeOrders(String jobId) {
    return _db.collection('jobs').doc(jobId).collection('changeOrders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<Map<String, dynamic>?> getJobById(String jobId) async {
    final doc = await _db.collection('jobs').doc(jobId).get();
    return doc.exists ? {...doc.data()!, 'id': doc.id} : null;
  }

  // Admin Verification Methods
  Stream<List<Map<String, dynamic>>> getPendingContractors() {
    return _db.collection('contractors')
        .where('verificationStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> verifyContractor(String uid, bool approve) async {
    await _db.collection('contractors').doc(uid).update({
      'isVerified': approve,
      'verificationStatus': approve ? 'approved' : 'rejected',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }
}
