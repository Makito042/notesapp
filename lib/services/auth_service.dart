import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of user authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      debugPrint('Attempting to sign in with email: $email');
      
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw 'Please enter both email and password';
      }
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (userCredential.user == null) {
        throw 'Failed to sign in. Please try again.';
      }
      
      debugPrint('Successfully signed in user: ${userCredential.user?.uid}');
      return userCredential;
      
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error - Code: ${e.code}, Message: ${e.message}');
      // Re-throw the exception to be handled by the UI layer
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during sign in: $e');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password, String name) async {
    try {
      debugPrint('Starting registration for email: $email');
      
      // Input validation
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw 'Please fill in all fields';
      }

      if (password.length < 6) {
        throw 'Password must be at least 6 characters long';
      }

      // Verify Firebase is initialized
      if (_auth.app == null) {
        debugPrint('Firebase Auth not initialized');
        throw 'Authentication service is not available. Please try again later.';
      }

      // Create user
      debugPrint('Creating user with email: $email');
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );
      } catch (e) {
        debugPrint('Error in createUserWithEmailAndPassword: ${e.toString()}');
        rethrow;
      }

      if (userCredential.user == null) {
        debugPrint('User creation returned null user');
        throw 'Failed to create user account. Please try again.';
      }

      debugPrint('User created successfully, updating profile...');
      
      // Update user display name
      try {
        await userCredential.user?.updateDisplayName(name.trim());
        await userCredential.user?.reload();
        debugPrint('User profile updated successfully');
      } catch (e) {
        debugPrint('Error updating user profile: $e');
        // Continue even if updating display name fails
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      debugPrint('Firebase Auth Exception - Code: ${e.code}, Message: ${e.message}');
      debugPrint('Error details: ${e.toString()}');
      
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak. Please choose a stronger password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email address.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled. Please contact support.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        default:
          errorMessage = 'Registration failed: ${e.message ?? 'Unknown error occurred. Please try again.'}';
      }
      
      debugPrint('Auth error: $errorMessage');
      throw errorMessage;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during registration: $e');
      debugPrint('Stack trace: $stackTrace');
      throw 'Registration failed: ${e.toString()}. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw 'Google sign in was aborted';

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      throw 'Error signing in with Google: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw 'No user found with that email address.';
      } else {
        throw 'An error occurred. Please try again.';
      }
    }
  }
}
