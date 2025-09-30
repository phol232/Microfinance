import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../env/env_loader.dart';

/// Reads Firebase configuration from environment variables and exposes
/// platform-specific [FirebaseOptions].
class FirebaseConfig {
  FirebaseConfig._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase configuration has not been defined for Linux.',
        );
      default:
        throw UnsupportedError(
          'Firebase configuration for "$defaultTargetPlatform" is not defined.',
        );
    }
  }

  static FirebaseOptions get android {
    return FirebaseOptions(
      apiKey: EnvLoader.get('FIREBASE_ANDROID_API_KEY', isRequired: true),
      appId: EnvLoader.get('FIREBASE_ANDROID_APP_ID', isRequired: true),
      messagingSenderId:
          EnvLoader.get('FIREBASE_MESSAGING_SENDER_ID', isRequired: true),
      projectId: EnvLoader.get('FIREBASE_PROJECT_ID', isRequired: true),
      storageBucket: EnvLoader.get('FIREBASE_STORAGE_BUCKET'),
      androidClientId: EnvLoader.get('FIREBASE_ANDROID_CLIENT_ID'),
    );
  }

  static FirebaseOptions get ios {
    return FirebaseOptions(
      apiKey: EnvLoader.get('FIREBASE_IOS_API_KEY', isRequired: true),
      appId: EnvLoader.get('FIREBASE_IOS_APP_ID', isRequired: true),
      messagingSenderId:
          EnvLoader.get('FIREBASE_MESSAGING_SENDER_ID', isRequired: true),
      projectId: EnvLoader.get('FIREBASE_PROJECT_ID', isRequired: true),
      storageBucket: EnvLoader.get('FIREBASE_STORAGE_BUCKET'),
      iosClientId: EnvLoader.get('FIREBASE_IOS_CLIENT_ID'),
      iosBundleId: EnvLoader.get('FIREBASE_IOS_BUNDLE_ID'),
    );
  }

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: EnvLoader.get('FIREBASE_IOS_API_KEY', isRequired: true),
        appId: EnvLoader.get('FIREBASE_IOS_APP_ID', isRequired: true),
        messagingSenderId:
            EnvLoader.get('FIREBASE_MESSAGING_SENDER_ID', isRequired: true),
        projectId: EnvLoader.get('FIREBASE_PROJECT_ID', isRequired: true),
        storageBucket: EnvLoader.get('FIREBASE_STORAGE_BUCKET'),
        iosClientId: EnvLoader.get('FIREBASE_IOS_CLIENT_ID'),
        iosBundleId: EnvLoader.get('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get windows {
    return FirebaseOptions(
      apiKey: EnvLoader.get('FIREBASE_WINDOWS_API_KEY', isRequired: true),
      appId: EnvLoader.get('FIREBASE_WINDOWS_APP_ID', isRequired: true),
      messagingSenderId:
          EnvLoader.get('FIREBASE_MESSAGING_SENDER_ID', isRequired: true),
      projectId: EnvLoader.get('FIREBASE_PROJECT_ID', isRequired: true),
      storageBucket: EnvLoader.get(
        'FIREBASE_WINDOWS_STORAGE_BUCKET',
        fallback: EnvLoader.get('FIREBASE_STORAGE_BUCKET'),
      ),
      authDomain: EnvLoader.get(
        'FIREBASE_WINDOWS_AUTH_DOMAIN',
        fallback: EnvLoader.get('FIREBASE_WEB_AUTH_DOMAIN'),
      ),
    );
  }

  static FirebaseOptions get web {
    return FirebaseOptions(
      apiKey: EnvLoader.get('FIREBASE_WEB_API_KEY', isRequired: true),
      appId: EnvLoader.get('FIREBASE_WEB_APP_ID', isRequired: true),
      messagingSenderId:
          EnvLoader.get('FIREBASE_MESSAGING_SENDER_ID', isRequired: true),
      projectId: EnvLoader.get('FIREBASE_PROJECT_ID', isRequired: true),
      storageBucket: EnvLoader.get(
        'FIREBASE_WEB_STORAGE_BUCKET',
        fallback: EnvLoader.get('FIREBASE_STORAGE_BUCKET'),
      ),
      authDomain: EnvLoader.get('FIREBASE_WEB_AUTH_DOMAIN'),
    );
  }
}
