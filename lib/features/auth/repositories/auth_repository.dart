import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../shared/enums/user_role.dart';

abstract class AuthRepository {
  Future<void> signIn({required String email, required String password});

  Future<UserCredential> signInWithGoogle();

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.customer,
  });

  /// Create a Vendor account (Name, Shop Name, Contact, Email, Password)
  Future<void> createVendor({
    required String name,
    required String shopName,
    required String contact,
    required String email,
    required String password,
  });

  /// Create a Staff account (Name, Contact, Email, Password, Role)
  Future<void> createStaff({
    required String name,
    required String contact,
    required String email,
    required String password,
    UserRole role = UserRole.admin,
  });
}

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserCredential> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Google did not return an ID token. Configure the Google web client ID.',
      );
    }

    final credential = await FirebaseAuth.instance.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase did not return the signed-in user.',
      );
    }

    await _ensureUserProfile(user);
    return credential;
  }

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
    UserRole role = UserRole.customer,
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
    final collectionName = FirestoreCollections.getCollectionForRole(role);
    await FirebaseFirestore.instance.collection(collectionName).doc(user.uid).set({
      'uid': user.uid,
      'name': displayName,
      'email': user.email,
      'role': role.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createVendor({
    required String name,
    required String shopName,
    required String contact,
    required String email,
    required String password,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase did not return the created vendor user.',
      );
    }

    final displayName = name.trim();
    await user.updateDisplayName(displayName);
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.vendors)
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': displayName,
      'shopName': shopName.trim(),
      'nameShop': shopName.trim(),
      'phoneNumber': contact.trim(),
      'contact': contact.trim(),
      'email': user.email,
      'role': UserRole.vendor.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> createStaff({
    required String name,
    required String contact,
    required String email,
    required String password,
    UserRole role = UserRole.admin,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-initialized',
        message: 'Firebase is not configured for this platform.',
      );
    }

    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Firebase did not return the created staff user.',
      );
    }

    final displayName = name.trim();
    await user.updateDisplayName(displayName);
    final staffRole = role.isStaff ? role : UserRole.admin;
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.staff)
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': displayName,
      'phoneNumber': contact.trim(),
      'contact': contact.trim(),
      'email': user.email,
      'role': staffRole.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _ensureUserProfile(User user, {UserRole role = UserRole.customer}) async {
    try {
      final collectionsToCheck = [
        FirestoreCollections.customers,
        FirestoreCollections.vendors,
        FirestoreCollections.staff,
      ];

      for (final col in collectionsToCheck) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection(col)
              .doc(user.uid)
              .get()
              .timeout(const Duration(seconds: 4));
          if (doc.exists) return;
        } catch (_) {}
      }

      final targetCollection = FirestoreCollections.getCollectionForRole(role);
      await FirebaseFirestore.instance
          .collection(targetCollection)
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email,
        'phoneNumber': user.phoneNumber ?? '',
        'photoUrl': user.photoURL,
        'role': role.value,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Do not abort authentication if Firestore profile sync is slow or offline
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);
