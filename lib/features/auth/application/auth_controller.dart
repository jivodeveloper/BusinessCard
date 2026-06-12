import 'package:businesscard/features/auth/data/auth_repository.dart';
import 'package:businesscard/features/auth/domain/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(firebaseAuth: FirebaseAuth.instance),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() => const AuthState();

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.signIn(username: username, password: password);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        username: username.trim(),
        clearError: true,
      );
      return true;
    } on AuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.message,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: 'Unable to sign in right now.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } finally {
      state = const AuthState();
    }
  }
}
