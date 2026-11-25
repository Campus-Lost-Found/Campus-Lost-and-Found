import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static FirebaseOptions get currentPlatform {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      throw UnsupportedError(
        'Firebase Auth and Cloud Firestore are not configured for this '
        'desktop target. Use web, Android, iOS, or macOS.',
      );
    }
    if (const bool.fromEnvironment('USE_FIREBASE_EMULATORS')) {
      return const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:123456789:web:campus-lost-found-demo',
        messagingSenderId: '123456789',
        projectId: 'demo-campus-lost-and-found',
        authDomain: 'localhost',
      );
    }
    if (_apiKey.isEmpty || _projectId.isEmpty || _messagingSenderId.isEmpty) {
      throw StateError(
        'Firebase is not configured. Run FlutterFire configuration or provide '
        'FIREBASE_API_KEY, FIREBASE_PROJECT_ID, FIREBASE_MESSAGING_SENDER_ID, '
        'and the platform-specific FIREBASE_*_APP_ID dart-defines.',
      );
    }

    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _required('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        authDomain: _required('FIREBASE_AUTH_DOMAIN'),
        storageBucket: const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _required('FIREBASE_ANDROID_APP_ID'),
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
          ),
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _required('FIREBASE_IOS_APP_ID'),
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
          ),
          iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
        );
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: _apiKey,
          appId: _required('FIREBASE_MACOS_APP_ID'),
          messagingSenderId: _messagingSenderId,
          projectId: _projectId,
          storageBucket: const String.fromEnvironment(
            'FIREBASE_STORAGE_BUCKET',
          ),
          iosBundleId: const String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID'),
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase Auth and Cloud Firestore are not configured for this '
          'desktop target. Use web, Android, iOS, or macOS.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for Fuchsia.');
    }
  }

  static String _required(String key) {
    final value = switch (key) {
      'FIREBASE_WEB_APP_ID' => const String.fromEnvironment(
        'FIREBASE_WEB_APP_ID',
      ),
      'FIREBASE_ANDROID_APP_ID' => const String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      'FIREBASE_IOS_APP_ID' => const String.fromEnvironment(
        'FIREBASE_IOS_APP_ID',
      ),
      'FIREBASE_MACOS_APP_ID' => const String.fromEnvironment(
        'FIREBASE_MACOS_APP_ID',
      ),
      'FIREBASE_AUTH_DOMAIN' => const String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
      ),
      _ => '',
    };
    if (value.isEmpty) {
      throw StateError('Missing required Firebase dart-define: $key.');
    }
    return value;
  }
}
