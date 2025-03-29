import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCq7w0O7iYXHWNsByvg7pTk2TwzsTqvAXc',
    appId: '1:414352737163:web:76b77a1f1c6654d24a658e',
    messagingSenderId: '414352737163',
    projectId: 'maeassignment-16f43',
    authDomain: 'maeassignment-16f43.firebaseapp.com',
    storageBucket: 'maeassignment-16f43.firebasestorage.app',
    measurementId: 'G-T0JCN1BC8C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhY45SCeftsyvGtDQom_hnvtkxLXvLTO4',
    appId: '1:414352737163:android:462fe555a78a7c814a658e',
    messagingSenderId: '414352737163',
    projectId: 'maeassignment-16f43',
    storageBucket: 'maeassignment-16f43.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA5LblKwuaf0dTTd9qd-lCCTh7wQLuT2IM',
    appId: '1:414352737163:ios:2caa9631ab0082074a658e',
    messagingSenderId: '414352737163',
    projectId: 'maeassignment-16f43',
    storageBucket: 'maeassignment-16f43.firebasestorage.app',
    iosBundleId: 'com.example.runnerRole',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA5LblKwuaf0dTTd9qd-lCCTh7wQLuT2IM',
    appId: '1:414352737163:ios:2caa9631ab0082074a658e',
    messagingSenderId: '414352737163',
    projectId: 'maeassignment-16f43',
    storageBucket: 'maeassignment-16f43.firebasestorage.app',
    iosBundleId: 'com.example.runnerRole',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCq7w0O7iYXHWNsByvg7pTk2TwzsTqvAXc',
    appId: '1:414352737163:web:216ed0cfb3f8688d4a658e',
    messagingSenderId: '414352737163',
    projectId: 'maeassignment-16f43',
    authDomain: 'maeassignment-16f43.firebaseapp.com',
    storageBucket: 'maeassignment-16f43.firebasestorage.app',
    measurementId: 'G-CJVHZZD5G5',
  );
}
