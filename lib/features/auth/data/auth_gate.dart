// FILE: lib/features/auth/data/auth_gate.dart

import 'dart:async';
import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// AuthGate handles authentication state changes and loads user preferences
/// like language settings whenever a user logs in
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription? _authSubscription;
  final AuthRepository _authRepo = AuthRepository();
  int _retryCount = 0;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // Start listening to authentication state changes
    _subscribeToAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _subscribeToAuthChanges() {
    _authSubscription = _authRepo.userStream.listen((User? user) {
      if (user != null) {
        // User signed in, load their language preference
        _loadUserLanguage(user.uid);
      }
    });
  }

  Future<void> _loadUserLanguage(String userId) async {
    try {
      final localeController = Provider.of<LocaleController>(
        context,
        listen: false,
      );

      // This will load language from Firestore and apply it
      await localeController.loadFromFirestore(userId);

      // Reset retry counter on success
      _retryCount = 0;
      _retryTimer?.cancel();
    } catch (e) {
      // Handle errors with exponential backoff for retries
      _handleLanguageLoadError(userId, e);
    }
  }

  void _handleLanguageLoadError(String userId, dynamic error) {
    // Log the error
    debugPrint('Error loading language preference: $error');

    // Maximum retry count (5 retries: ~30 seconds total with exponential backoff)
    if (_retryCount < 5) {
      _retryCount++;

      // Calculate exponential backoff with jitter
      // Base delay: 500ms, then 1000ms, 2000ms, 4000ms, 8000ms
      final baseDelay = 500 * (1 << (_retryCount - 1));
      // Add some randomness (jitter) to avoid thundering herd
      final jitter =
          (baseDelay * 0.2 * (DateTime.now().millisecondsSinceEpoch % 100)) ~/
          100;
      final delay = baseDelay + jitter;

      debugPrint(
        'Retrying to load language preference in ${delay}ms (attempt $_retryCount)',
      );

      // Schedule retry with backoff
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) {
          _loadUserLanguage(userId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // AuthGate is just a wrapper that passes through its child
    return widget.child;
  }
}
