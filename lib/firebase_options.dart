// File generated to provide default FirebaseOptions for BloomHabit.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBloomHabitMockKeyForInit12345678',
    appId: '1:1234567890:web:bloomhabit123456',
    messagingSenderId: '1234567890',
    projectId: 'bloomhabit-app',
    authDomain: 'bloomhabit-app.firebaseapp.com',
    storageBucket: 'bloomhabit-app.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBloomHabitMockKeyForInit12345678',
    appId: '1:1234567890:android:bloomhabit123456',
    messagingSenderId: '1234567890',
    projectId: 'bloomhabit-app',
    storageBucket: 'bloomhabit-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBloomHabitMockKeyForInit12345678',
    appId: '1:1234567890:ios:bloomhabit123456',
    messagingSenderId: '1234567890',
    projectId: 'bloomhabit-app',
    storageBucket: 'bloomhabit-app.appspot.com',
    iosBundleId: 'com.bloomhabit.bloomHabit',
  );
}
