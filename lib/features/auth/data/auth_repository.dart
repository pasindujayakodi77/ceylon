import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart' as foundation;
import 'package:ceylon/services/google_services_checker.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<User?> signUpWithEmail(
    String email,
    String password,
    String role,
    String name,
    String country,
    String language,
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'email': email,
      'role': role,
      'name': name,
      'country': country,
      'language': language,
      'created_at': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (foundation.kIsWeb) {
        // Web flow
        final googleProvider = GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        return userCredential.user;
      } else {
        // Check for Google Play Services availability
        final googleServicesError =
            await GoogleServicesChecker.getGooglePlayServicesError();
        if (googleServicesError != null) {
          throw Exception(googleServicesError);
        }

        // Direct Firebase authentication with Google Provider
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.email',
        );
        googleProvider.addScope(
          'https://www.googleapis.com/auth/userinfo.profile',
        );

        final userCredential = await _auth.signInWithProvider(googleProvider);
        final user = userCredential.user;

        // Ensure a corresponding Firestore user document exists so
        // UI that relies on users/{uid}.role works for Google accounts too.
        if (user != null) {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          final doc = await userRef.get();
          if (!doc.exists) {
            await userRef.set({
              'email': user.email ?? '',
              'name': user.displayName ?? '',
              // Use the same default role as the signup flow
              'role': 'tourist',
              'language': 'en',
              'created_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }

        return user;
      }
    } catch (e) {
      foundation.debugPrint('Firebase Authentication error: $e');
      throw Exception("Google Sign-In failed: $e");
    }
  }
}
