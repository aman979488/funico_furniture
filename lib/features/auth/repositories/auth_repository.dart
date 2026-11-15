import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<void> signIn({required String email, required String password}) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase did not return the signed-in user.',
      );
    }

    await _ensureUserProfile(user);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase did not return the created user.',
      );
    }

    final displayName = name.trim();
    await user.updateDisplayName(displayName);
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': displayName,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureUserProfile(User user) async {
    final profile = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final snapshot = await profile.get();
    if (!snapshot.exists) {
      await profile.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);
