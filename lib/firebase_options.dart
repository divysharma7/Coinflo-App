import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS Firebase options not configured yet. '
          'Add GoogleService-Info.plist and update this file.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgdDskk4Gga4RKxytmEA7AMNXe0AdoGkc',
    appId: '1:195537008902:android:a43d5761800a640f6b8687',
    messagingSenderId: '195537008902',
    projectId: 'portfolio-11501',
    storageBucket: 'portfolio-11501.firebasestorage.app',
    databaseURL: 'https://portfolio-11501-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
