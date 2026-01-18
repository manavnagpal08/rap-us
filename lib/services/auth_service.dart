import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:rap_app/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );
  final DatabaseService _db = DatabaseService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Admin Check
  bool get isAdmin {
    final email = currentUser?.email;
    return email == 'manav.nagpal2005@gmail.com' || 
           email == 'kaaysha.rao@gmail.com' || 
           email == 'admin@rap.com';
  }

  // Auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<UserCredential?> register(String email, String password, String fullName, {String role = 'user', String? photoBase64}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update display name
      await credential.user?.updateDisplayName(fullName);
      
      // Create Firestore Profile
      await _db.createUserProfile(credential.user!.uid, {
        'fullName': fullName,
        'email': email,
        'role': role,
        if (photoBase64 != null) 'photoBase64': photoBase64,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<String> getUserRole() async {
    if (currentUser == null) return 'guest';
    final profile = await _db.getUserProfile(currentUser!.uid);
    return profile?['role'] ?? 'user';
  }

  // Login with Email & Password
  Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Sign-In (Optional)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      throw 'Google Sign-In failed: $e';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found': return 'No user found for that email.';
      case 'wrong-password': return 'Wrong password provided.';
      case 'email-already-in-use': return 'Account already exists for that email.';
      case 'invalid-email': return 'The email address is not valid.';
      case 'weak-password': return 'The password is too weak.';
      default: return e.message ?? 'An unknown error occurred.';
    }
  }
}
