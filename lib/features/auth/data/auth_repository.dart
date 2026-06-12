import 'package:businesscard/core/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  Future<void> signIn({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (username.trim().isEmpty || password.trim().isEmpty) {
      throw const AuthException('Enter both username and password.');
    }

    final normalized = username.trim();
    final isEmailLogin = normalized.contains('@');
    final usernamePattern = RegExp(r'^[a-zA-Z0-9._-]{3,24}$');
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (isEmailLogin && !emailPattern.hasMatch(normalized)) {
      throw const AuthException('Enter a valid email address.');
    }
    if (!isEmailLogin && !usernamePattern.hasMatch(normalized)) {
      throw const AuthException(
        'Username must be 3-24 characters and can use letters, numbers, dots, hyphens, or underscores.',
      );
    }

    try {
      final email = _emailForUsername(normalized);
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }

      await _signInOrCreateAccount(
        username: normalized,
        email: email,
        password: password.trim(),
      );
    } on FirebaseAuthException catch (error) {
      throw AuthException(
        _messageForFirebaseError(
          error,
          attemptedUsername: normalized,
          attemptedEmail: _emailForUsername(normalized),
        ),
      );
    } catch (_) {
      throw const AuthException(
        'Unable to establish a Firebase session right now.',
      );
    }
  }

  Future<void> _signInOrCreateAccount({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (!_shouldAttemptAutoCreate(error: error, username: username)) {
        rethrow;
      }

      try {
        await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use' ||
            createError.code == 'credential-already-in-use') {
          rethrow;
        }
        rethrow;
      }
    }
  }

  bool _shouldAttemptAutoCreate({
    required FirebaseAuthException error,
    required String username,
  }) {
    if (username.contains('@')) {
      return false;
    }

    return error.code == 'invalid-credential' ||
        error.code == 'wrong-password' ||
        error.code == 'user-not-found';
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _emailForUsername(String username) {
    if (username.contains('@')) {
      return username.toLowerCase();
    }

    return '${username.toLowerCase()}@${AppConfig.authEmailDomain}';
  }

  String _messageForFirebaseError(
    FirebaseAuthException error, {
    required String attemptedUsername,
    required String attemptedEmail,
  }) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        if (!attemptedUsername.contains('@')) {
          return 'Sign-in failed for "$attemptedUsername". This app maps that username to "$attemptedEmail". If your Firebase account uses a different email, enter the full email address instead.';
        }
        return 'Incorrect email or password for "$attemptedEmail".';
      case 'email-already-in-use':
      case 'credential-already-in-use':
        if (!attemptedUsername.contains('@')) {
          return 'An account already exists for "$attemptedEmail", but the password did not match.';
        }
        return 'An account already exists for "$attemptedEmail", but the password did not match.';
      case 'operation-not-allowed':
        return 'Firebase email/password sign-in is disabled for this project.';
      case 'invalid-email':
        return 'This username could not be mapped to a valid sign-in email.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'too-many-requests':
        return 'Too many sign-in attempts. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Unable to reach Firebase. Check the network connection and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Unable to establish a Firebase session right now.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
