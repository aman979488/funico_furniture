import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/firestore_collections.dart';

class PinStorage {
  const PinStorage();

  static const _storage = FlutterSecureStorage();
  static const _keyPrefix = 'funica_pin_';
  static const _fpPrefix = 'funica_fp_';

  Future<DocumentReference<Map<String, dynamic>>> _getUserDocRef(String userId) async {
    final collections = [
      FirestoreCollections.customers,
      FirestoreCollections.vendors,
      FirestoreCollections.staff,
    ];
    for (final col in collections) {
      final docRef = FirebaseFirestore.instance.collection(col).doc(userId);
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        return docRef;
      }
    }
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.customers)
        .doc(userId);
  }

  Future<String?> readPin(String userId) async {
    // 1. Pehle FlutterSecureStorage se try karo
    try {
      final pin = await _storage.read(key: '$_keyPrefix$userId');
      if (pin != null && pin.isNotEmpty) return pin;
    } catch (_) {}

    // 2. Fallback: SharedPreferences se read karo
    try {
      final prefs = await SharedPreferences.getInstance();
      final pin = prefs.getString('$_keyPrefix$userId');
      if (pin != null && pin.isNotEmpty) {
        try {
          await _storage.write(key: '$_keyPrefix$userId', value: pin);
        } catch (_) {}
        return pin;
      }
    } catch (_) {}

    // 3. Fallback: Firestore user doc se read karo
    if (Firebase.apps.isNotEmpty) {
      try {
        final docRef = await _getUserDocRef(userId);
        final doc = await docRef.get();
        final pin = doc.data()?['pin'] as String?;
        if (pin != null && pin.isNotEmpty) {
          try {
            await _storage.write(key: '$_keyPrefix$userId', value: pin);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('$_keyPrefix$userId', pin);
          } catch (_) {}
          return pin;
        }
      } catch (_) {}
    }

    return null;
  }

  Future<void> savePin(String userId, String pin) async {
    var savedLocally = false;
    Object? secureStorageError;
    Object? preferencesError;

    try {
      await _storage.write(key: '$_keyPrefix$userId', value: pin);
      savedLocally = true;
    } catch (error) {
      secureStorageError = error;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_keyPrefix$userId', pin);
      savedLocally = true;
    } catch (error) {
      preferencesError = error;
    }

    if (!savedLocally) {
      throw StateError(
        'Could not save PIN locally. '
        'Secure storage: $secureStorageError; preferences: $preferencesError',
      );
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        final docRef = await _getUserDocRef(userId);
        await docRef.set({
          'pin': pin,
          'hasPin': true,
          'pinUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<bool> isFingerprintEnabled(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getBool('$_fpPrefix$userId');
      if (local != null) return local;

      if (Firebase.apps.isNotEmpty) {
        final docRef = await _getUserDocRef(userId);
        final doc = await docRef.get();
        return (doc.data()?['fingerprintEnabled'] as bool?) ?? false;
      }
    } catch (_) {}
    return false;
  }

  Future<void> setFingerprintEnabled(String userId, bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_fpPrefix$userId', enabled);
    } catch (_) {}

    if (Firebase.apps.isNotEmpty) {
      try {
        final docRef = await _getUserDocRef(userId);
        await docRef.set({
          'fingerprintEnabled': enabled,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }
}

final pinStorageProvider = Provider<PinStorage>((ref) => const PinStorage());
