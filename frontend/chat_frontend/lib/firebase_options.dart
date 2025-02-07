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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBis1oCtVGzUGpXs3AtTQzVLVimojYufP0',
    appId: '1:340237548744:web:2cfbd5f3af4a660cd879fd',
    messagingSenderId: '340237548744',
    projectId: 'kasaychi-community',
    authDomain: 'kasaychi-community.firebaseapp.com',
    databaseURL: 'https://kasaychi-community-default-rtdb.firebaseio.com',
    storageBucket: 'kasaychi-community.firebasestorage.app',
    measurementId: 'G-KD1TL06QQ0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKB0oxZzMBKdpOVGc4vxaaImTavlZfL0Q',
    appId: '1:340237548744:android:381683f8208df270d879fd',
    messagingSenderId: '340237548744',
    projectId: 'kasaychi-community',
    databaseURL: 'https://kasaychi-community-default-rtdb.firebaseio.com',
    storageBucket: 'kasaychi-community.firebasestorage.app',
  );
}
