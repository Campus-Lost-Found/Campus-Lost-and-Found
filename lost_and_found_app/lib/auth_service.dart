import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'local_store.dart';

const Set<String> _preconfiguredStaffEmails = <String>{'staff.one@gmail.com'};

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
  final String passwordSalt;
  final String passwordHash;
  final UserRole role;

  const UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordSalt,
    required this.passwordHash,
    required this.role,
  });

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'];
    final role = UserRole.values.where((value) => value.name == roleName);
    if (role.isEmpty) {
      throw StateError('A saved user has an invalid role.');
    }
    return UserRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordSalt: json['passwordSalt'] as String,
      passwordHash: json['passwordHash'] as String,
      role: role.first,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
    'role': role.name,
  };

  UserRecord withRole(UserRole newRole) => UserRecord(
    id: id,
    name: name,
    email: email,
    passwordSalt: passwordSalt,
    passwordHash: passwordHash,
    role: newRole,
  );
}

class AccessDeniedException implements Exception {
  const AccessDeniedException();

  @override
  String toString() => 'Access denied';
}

class AuthService {
  static const String _usersKey = 'campus_find_users';
  static const String _sessionKey = 'campus_find_session_user_id';
  static UserRecord? _currentUser;

  static UserRecord? get currentUser => _currentUser;
  static UserRole? get currentRole => _currentUser?.role;
  static bool get canReview => currentRole?.canReview ?? false;
  static bool get canManageRoles => currentRole?.canManageRoles ?? false;

  static bool isPreconfiguredStaffEmail(String email) =>
      _preconfiguredStaffEmails.contains(email.trim().toLowerCase());

  @visibleForTesting
  static void setCurrentUserForTesting(UserRecord? user) {
    _currentUser = user;
  }

  static Future<List<UserRecord>> _users({bool provisionStaff = true}) async {
    final records = await LocalStore.readRecords(_usersKey);
    final users = records.map(UserRecord.fromJson).toList(growable: true);
    if (!provisionStaff) return users;

    var changed = false;
    for (final email in _preconfiguredStaffEmails) {
      if (users.any((user) => user.email == email)) continue;
      users.add(
        UserRecord(
          id: LocalStore.createId(),
          name: 'Preconfigured staff',
          email: email,
          passwordSalt: '',
          passwordHash: '',
          role: UserRole.staff,
        ),
      );
      changed = true;
    }
    if (changed) {
      await LocalStore.writeRecords(
        _usersKey,
        users.map((user) => user.toJson()).toList(),
      );
    }
    return users;
  }

  static Future<void> initialize() async {
    await _users();
  }

  static Future<bool> hasUsers() async => (await _users()).isNotEmpty;

  static Future<bool> needsStaffPasswordSetup(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    return (await _users()).any(
      (user) =>
          user.email == normalizedEmail &&
          user.role == UserRole.staff &&
          user.passwordSalt.isEmpty &&
          user.passwordHash.isEmpty,
    );
  }

  static Future<UserRecord?> restoreSession() async {
    final userId = await LocalStore.readString(_sessionKey);
    if (userId == null) return null;
    final users = await _users();
    for (final user in users) {
      if (user.id == userId) {
        _currentUser = user;
        return user;
      }
    }
    await LocalStore.remove(_sessionKey);
    throw StateError('The saved session has no matching user account.');
  }

  static Future<String?> register(
    String name,
    String email,
    String password,
  ) async {
    final users = await _users();
    final normalizedEmail = email.trim().toLowerCase();
    final existingIndex = users.indexWhere(
      (user) => user.email == normalizedEmail,
    );
    final salt = _makeSalt();
    if (existingIndex >= 0) {
      final existing = users[existingIndex];
      final isUnclaimedStaff =
          existing.role == UserRole.staff &&
          existing.passwordSalt.isEmpty &&
          existing.passwordHash.isEmpty;
      if (!isUnclaimedStaff) {
        return 'An account with this email already exists.';
      }
      users[existingIndex] = UserRecord(
        id: existing.id,
        name: name.trim(),
        email: existing.email,
        passwordSalt: salt,
        passwordHash: _hash(password, salt),
        role: UserRole.staff,
      );
    } else {
      users.add(
        UserRecord(
          id: LocalStore.createId(),
          name: name.trim(),
          email: normalizedEmail,
          passwordSalt: salt,
          passwordHash: _hash(password, salt),
          role: UserRole.student,
        ),
      );
    }
    await LocalStore.writeRecords(
      _usersKey,
      users.map((record) => record.toJson()).toList(),
    );
    return null;
  }

  static Future<UserRecord> bootstrapAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _users();
    final initializedUsers = users.where(
      (user) => user.passwordSalt.isNotEmpty || user.passwordHash.isNotEmpty,
    );
    if (initializedUsers.isNotEmpty) {
      throw StateError(
        'Initial admin setup is closed because an account already exists.',
      );
    }
    final salt = _makeSalt();
    final admin = UserRecord(
      id: LocalStore.createId(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordSalt: salt,
      passwordHash: _hash(password, salt),
      role: UserRole.admin,
    );
    users.add(admin);
    await LocalStore.writeRecords(
      _usersKey,
      users.map((user) => user.toJson()).toList(),
    );
    await LocalStore.writeString(_sessionKey, admin.id);
    _currentUser = admin;
    return admin;
  }

  static Future<UserRecord?> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = await _users();
    for (final user in users) {
      if (user.email == normalizedEmail &&
          _hash(password, user.passwordSalt) == user.passwordHash) {
        await LocalStore.writeString(_sessionKey, user.id);
        _currentUser = user;
        return user;
      }
    }
    return null;
  }

  static Future<void> signOut() async {
    await LocalStore.remove(_sessionKey);
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
    return List<UserRecord>.unmodifiable(await _users());
  }

  static Future<void> updateRole(String userId, UserRole role) async {
    requireAdmin();
    final users = await _users();
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) {
      throw ArgumentError.value(userId, 'userId', 'No account exists for ID');
    }
    final updatedUser = users[index].withRole(role);
    users[index] = updatedUser;
    await LocalStore.writeRecords(
      _usersKey,
      users.map((user) => user.toJson()).toList(),
    );
    if (_currentUser?.id == userId) _currentUser = updatedUser;
  }

  static String _makeSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hash(String password, String salt) =>
      sha256.convert(utf8.encode('$salt$password')).toString();
}
