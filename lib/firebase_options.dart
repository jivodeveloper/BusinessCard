import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for Fuchsia.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8UdQH31kaYiSt0iuqK6FvL6N2ikLQiPg',
    appId: '1:73033635378:android:8d87b3a51f2fb77e388e2b',
    messagingSenderId: '73033635378',
    projectId: 'businesscard-a9cf7',
    storageBucket: 'businesscard-a9cf7.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDGeuFLKF2xwAzOdzyh_0IoHA-6QxEkf9c',
    appId: '1:73033635378:ios:e7fed002e2610882388e2b',
    messagingSenderId: '73033635378',
    projectId: 'businesscard-a9cf7',
    storageBucket: 'businesscard-a9cf7.firebasestorage.app',
    iosBundleId: 'com.jivo.businesscard.businesscard',
  );
}
