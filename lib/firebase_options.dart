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
    apiKey: 'AIzaSyCXAKVQdoV0z2gvuh1YEovYodt-DiJNuDQ',
    appId: '1:235038161282:web:adbed1864334409f41b79b',
    messagingSenderId: '235038161282',
    projectId: 'reading-tracker-67f66',
    authDomain: 'reading-tracker-67f66.firebaseapp.com',
    storageBucket: 'reading-tracker-67f66.firebasestorage.app',
    measurementId: 'G-KMYWSF80TN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyADW4WCdsPfegfZGJUIfIUicK0nL2BnAnQ',
    appId: '1:235038161282:android:46818e43fd649ca941b79b',
    messagingSenderId: '235038161282',
    projectId: 'reading-tracker-67f66',
    storageBucket: 'reading-tracker-67f66.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJsgLIs2LADSAYqScF031pk39ZvettrGk',
    appId: '1:235038161282:ios:a34cee40381561fa41b79b',
    messagingSenderId: '235038161282',
    projectId: 'reading-tracker-67f66',
    storageBucket: 'reading-tracker-67f66.firebasestorage.app',
    iosBundleId: 'com.example.readingTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDJsgLIs2LADSAYqScF031pk39ZvettrGk',
    appId: '1:235038161282:ios:a34cee40381561fa41b79b',
    messagingSenderId: '235038161282',
    projectId: 'reading-tracker-67f66',
    storageBucket: 'reading-tracker-67f66.firebasestorage.app',
    iosBundleId: 'com.example.readingTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCXAKVQdoV0z2gvuh1YEovYodt-DiJNuDQ',
    appId: '1:235038161282:web:905af565a0c8411441b79b',
    messagingSenderId: '235038161282',
    projectId: 'reading-tracker-67f66',
    authDomain: 'reading-tracker-67f66.firebaseapp.com',
    storageBucket: 'reading-tracker-67f66.firebasestorage.app',
    measurementId: 'G-SYFBEQ84HT',
  );
}
