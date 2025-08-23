// FILE: lib/firebase_options.dart

// Auto-generated Firebase options for the ceylon-97e24 project.
// This file provides platform-specific FirebaseOptions used by Firebase.initializeApp.

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
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return android; // Use Android options as default for desktop fallback
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDtiVi0c1kbkhoKpUBq1GHVcFGPJuHe6vs',
    authDomain: 'ceylon-97e24.firebaseapp.com',
    projectId: 'ceylon-97e24',
    storageBucket: 'ceylon-97e24.firebasestorage.app',
    messagingSenderId: '831708443753',
    appId: '1:831708443753:web:REPLACE_WITH_WEB_APP_ID',
    measurementId: 'G-REPLACE_MEASURE_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtiVi0c1kbkhoKpUBq1GHVcFGPJuHe6vs',
    appId: '1:831708443753:android:79a63a97146ebdf617def8',
    messagingSenderId: '831708443753',
    projectId: 'ceylon-97e24',
    storageBucket: 'ceylon-97e24.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtiVi0c1kbkhoKpUBq1GHVcFGPJuHe6vs',
    appId: '1:831708443753:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '831708443753',
    projectId: 'ceylon-97e24',
    storageBucket: 'ceylon-97e24.firebasestorage.app',
    iosBundleId: 'com.example.ceylon',
    androidClientId:
        '831708443753-tl0sibdrkvdjqc9s02etm43m0bjitvo5.apps.googleusercontent.com',
  );
}
