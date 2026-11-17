import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../repositories/auth_repository.dart';

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.error,
    this.isNewGoogleUser = false,
  });

  final bool isLoading;
  final String? error;
  final bool isNewGoogleUser;

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isNewGoogleUser,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      isNewGoogleUser: isNewGoogleUser ?? this.isNewGoogleUser,
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      isNewGoogleUser: false,
    );
    try {
      final credential = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle();
      state = AuthState(
        isNewGoogleUser: credential.additionalUserInfo?.isNewUser ?? false,
      );
      return true;
    } on GoogleSignInException catch (error) {
      state = AuthState(
        error: error.code == GoogleSignInExceptionCode.canceled
            ? null
            : _googleSignInExceptionMessage(error),
      );
      return false;
    } on FirebaseAuthException catch (error) {
      state = AuthState(error: _googleSignInMessageFor(error));
      return false;
    } on FirebaseException catch (error) {
      state = AuthState(error: _firestoreMessageFor(error));
      return false;
    } catch (error) {
      state = AuthState(error: 'Google sign-in failed: $error');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (error) {
      state = AuthState(error: _signInMessageFor(error));
      return false;
    } on FirebaseException catch (error) {
      state = AuthState(error: _firestoreMessageFor(error));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email: email);
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (error) {
      state = AuthState(error: _passwordResetMessageFor(error));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(name: name, email: email, password: password);
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (error) {
      state = AuthState(error: _messageFor(error));
      return false;
    } on FirebaseException catch (error) {
      state = AuthState(error: _firestoreMessageFor(error));
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _messageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email and password sign-up is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'not-initialized':
        return 'Firebase is not configured for this platform. Configure Firebase first.';
      default:
        return 'Could not create your account. Please try again.';
    }
  }

  String _signInMessageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'not-initialized':
        return 'Firebase is not configured for this platform. Configure Firebase first.';
      default:
        return 'Could not log in. Please try again.';
    }
  }

  String _googleSignInExceptionMessage(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return '';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In configuration error. Please ensure SHA-1 fingerprint is added in Firebase Console and google-services.json is updated.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In UI is currently unavailable. Please try again.';
      case GoogleSignInExceptionCode.interrupted:
        return 'Google Sign-In was interrupted. Please try again.';
      default:
        final desc = error.description;
        if (desc != null && desc.isNotEmpty) {
          return 'Google sign-in failed: $desc';
        }
        return 'Google sign-in failed. Please check Firebase setup and try again.';
    }
  }

  String _googleSignInMessageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled in Firebase.';
      case 'not-initialized':
        return 'Firebase is not configured for this platform. Configure Firebase first.';
      default:
        return 'Google sign-in failed. Check your Google OAuth configuration and try again.';
    }
  }

  String _passwordResetMessageFor(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-not-found':
        return 'No account was found for this email address.';
      case 'operation-not-allowed':
        return 'Password reset is not enabled in Firebase.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'not-initialized':
        return 'Firebase is not configured for this platform. Configure Firebase first.';
      default:
        return 'Could not send the password reset email. Please try again.';
    }
  }

  String _firestoreMessageFor(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Authentication succeeded, but Firestore could not save your profile. Check your Firestore security rules.';
    }
    if (error.code == 'unavailable') {
      return 'Authentication succeeded, but Firestore is unavailable. Check your connection and try logging in again.';
    }
    return 'Authentication succeeded, but Firestore could not save your profile. Check your Firestore setup and try again.';
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
