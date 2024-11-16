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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyB_J0leYgEV4bKBqEQq3hCRb5KJyhZmXxM',
    appId: '1:1096380473742:web:01939f32eac98f924344df',
    messagingSenderId: '1096380473742',
    projectId: 'attendance-system-fc3c8',
    authDomain: 'attendance-system-fc3c8.firebaseapp.com',
    storageBucket: 'attendance-system-fc3c8.firebasestorage.app',
    measurementId: 'G-Q5SXKLZS3H',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCkHVZveSZwWTChSGLXobK2ks2koFWgOGc',
    appId: '1:1096380473742:android:79fcaa0dd7bfa6e94344df',
    messagingSenderId: '1096380473742',
    projectId: 'attendance-system-fc3c8',
    storageBucket: 'attendance-system-fc3c8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWZozh--IfdvpAhf27oSmb3C_63KTuHsI',
    appId: '1:1096380473742:ios:028e9d1983a802724344df',
    messagingSenderId: '1096380473742',
    projectId: 'attendance-system-fc3c8',
    storageBucket: 'attendance-system-fc3c8.firebasestorage.app',
    iosBundleId: 'com.soldier.attendanceSystem',
  );
}