import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  student,
  staff,
  admin;

  String get label => switch (this) {
    UserRole.student => 'Student',
    UserRole.staff => 'Staff',
    UserRole.admin => 'Admin',
  };

  bool get canReview => this == UserRole.staff || this == UserRole.admin;
  bool get canManageRoles => this == UserRole.admin;
}

class UserRecord {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('User profile ${snapshot.id} does not exist.');
    }
    final roleName = data['role'];
    final role = UserRole.values.where((value) => value.name == roleName);
    if (role.isEmpty) {
      throw StateError('User profile ${snapshot.id} has an invalid role.');
    }
    return UserRecord(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: role.first,
    );
  }
}

class AccessDeniedException implements Exception {
  const AccessDeniedException();

  @override
  String toString() => 'Access denied';
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static UserRecord? _currentUser;

  static UserRecord? get currentUser => _currentUser;
  static UserRole? get currentRole => _currentUser?.role;
  static bool get canReview => currentRole?.canReview ?? false;
  static bool get canManageRoles => currentRole?.canManageRoles ?? false;

  static void connectToEmulators() {
    if (!const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) return;
    final configuredHost = const String.fromEnvironment(
      'FIREBASE_EMULATOR_HOST',
    );
    final host = configuredHost.isNotEmpty
        ? configuredHost
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    _auth.useAuthEmulator(host, 9099);
    _firestore.useFirestoreEmulator(host, 8080);
  }

  @visibleForTesting
  static void setCurrentUserForTesting(UserRecord? user) {
    _currentUser = user;
  }

  static Future<UserRecord?> restoreSession() async {
    final authUser = _auth.currentUser;
    if (authUser == null) return null;
    final profile = await _firestore
        .collection('users')
        .doc(authUser.uid)
        .get();
    _currentUser = UserRecord.fromSnapshot(profile);
    return _currentUser;
  }

  static Future<String?> register(
    String name,
    String email,
    String password,
  ) async {
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Firebase created an account without a user record.');
      }
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': user.email,
        'role': UserRole.student.name,
      });
    } on FirebaseAuthException catch (error) {
      return error.message ?? 'Could not create the account (${error.code}).';
    } on FirebaseException catch (error) {
      final createdUser = credential?.user;
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } on FirebaseAuthException catch (cleanupError) {
          throw StateError(
            'Profile creation failed (${error.code}) and the new account '
            'could not be removed (${cleanupError.code}).',
          );
        }
      }
      rethrow;
    }
    await _auth.signOut();
    return null;
  }

  static Future<UserRecord?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final authUser = credential.user;
      if (authUser == null) {
        throw StateError('Firebase signed in without a user record.');
      }
      final profile = await _firestore
          .collection('users')
          .doc(authUser.uid)
          .get();
      _currentUser = UserRecord.fromSnapshot(profile);
      return _currentUser;
    } on FirebaseAuthException catch (error) {
      if (const {
        'invalid-credential',
        'user-not-found',
        'wrong-password',
        'invalid-email',
      }.contains(error.code)) {
        return null;
      }
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  static void requireStaff() {
    if (!canReview) throw const AccessDeniedException();
  }

  static void requireAdmin() {
    if (!canManageRoles) throw const AccessDeniedException();
  }

  static Future<List<UserRecord>> allUsers() async {
    requireAdmin();
    final users = await _firestore.collection('users').get();
    return users.docs.map(UserRecord.fromSnapshot).toList(growable: false);
  }

  static Future<void> updateRole(String userId, UserRole role) async {
    requireAdmin();
    await _firestore.collection('users').doc(userId).update({
      'role': role.name,
    });
    if (_currentUser?.id == userId) {
      _currentUser = UserRecord(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        role: role,
      );
    }
  }
}
