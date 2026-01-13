import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
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
      'isVerified': true, // Auto-verify for demo, normally would be pending
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
}
