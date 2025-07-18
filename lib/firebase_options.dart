// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyBppoR9tyD9z2a9_xM49bxSTn8ONpxpmpM',
    appId: '1:475219352041:web:f6fb6f37cc62d9731a5378',
    messagingSenderId: '475219352041',
    projectId: 'flutter-firebase-auth-83197',
    authDomain: 'flutter-firebase-auth-83197.firebaseapp.com',
    storageBucket: 'flutter-firebase-auth-83197.firebasestorage.app',
    measurementId: 'G-NRBBVNL6QP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1NYw5HPdsUaggZ1MEsE8m_m7wwnqz9I8',
    appId: '1:475219352041:android:d91d6ead894352021a5378',
    messagingSenderId: '475219352041',
    projectId: 'flutter-firebase-auth-83197',
    storageBucket: 'flutter-firebase-auth-83197.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUhgSm7Wvqwn8XTTj68fR9NLcxhbDb6hE',
    appId: '1:475219352041:ios:b998962c069219e11a5378',
    messagingSenderId: '475219352041',
    projectId: 'flutter-firebase-auth-83197',
    storageBucket: 'flutter-firebase-auth-83197.firebasestorage.app',
    iosBundleId: 'com.example.ab',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDUhgSm7Wvqwn8XTTj68fR9NLcxhbDb6hE',
    appId: '1:475219352041:ios:b998962c069219e11a5378',
    messagingSenderId: '475219352041',
    projectId: 'flutter-firebase-auth-83197',
    storageBucket: 'flutter-firebase-auth-83197.firebasestorage.app',
    iosBundleId: 'com.example.ab',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBppoR9tyD9z2a9_xM49bxSTn8ONpxpmpM',
    appId: '1:475219352041:web:915012d54931c5351a5378',
    messagingSenderId: '475219352041',
    projectId: 'flutter-firebase-auth-83197',
    authDomain: 'flutter-firebase-auth-83197.firebaseapp.com',
    storageBucket: 'flutter-firebase-auth-83197.firebasestorage.app',
    measurementId: 'G-Q588D5MHF9',
  );
}
