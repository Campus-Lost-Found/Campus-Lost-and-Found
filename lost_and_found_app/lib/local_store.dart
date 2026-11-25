import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static String createId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static Future<String?> readString(String key) async {
    try {
      return await _preferences.getString(key);
    } on PlatformException catch (error) {
      throw StateError('Could not read local data: ${error.message}');
    }
  }

  static Future<void> writeString(String key, String value) async {
    try {
      await _preferences.setString(key, value);
    } on PlatformException catch (error) {
      throw StateError('Could not save local data: ${error.message}');
    }
  }

  static Future<void> remove(String key) async {
    try {
      await _preferences.remove(key);
    } on PlatformException catch (error) {
      throw StateError('Could not clear local data: ${error.message}');
    }
  }

  static Future<List<Map<String, dynamic>>> readRecords(String key) async {
    final value = await readString(key);
    if (value == null || value.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      throw StateError('Local data for "$key" has an invalid format.');
    }
    return decoded
        .map((record) {
          if (record is! Map) {
            throw StateError(
              'Local data for "$key" contains an invalid record.',
            );
          }
          return Map<String, dynamic>.from(record);
        })
        .toList(growable: true);
  }

  static Future<void> writeRecords(
    String key,
    List<Map<String, dynamic>> records,
  ) async {
    await writeString(key, jsonEncode(records));
  }
}
