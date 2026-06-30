import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyBdb-hIYycWkXUXpHQCe1jxx0i0xvmjwy0',
        authDomain: 'abudshisha.firebaseapp.com',
        projectId: 'abudshisha',
        storageBucket: 'abudshisha.firebasestorage.app',
        messagingSenderId: '339029236820',
        appId: '1:339029236820:web:0774967e360d021caba1c1',
        measurementId: 'G-C0KRGXSVC9',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyDqDQjDjDjDjDjDjDjDjDjDjDjDjDjDjDj',
          appId: '1:1234567890:android:abcdef1234567890',
          messagingSenderId: '1234567890',
          projectId: 'qurity',
          storageBucket: 'qurity.appspot.com',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_IOS_API_KEY',
          appId: '1:1234567890:ios:abcdef1234567890',
          messagingSenderId: '1234567890',
          projectId: 'qurity',
          storageBucket: 'qurity.appspot.com',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'YOUR_MACOS_API_KEY',
          appId: '1:1234567890:macos:abcdef1234567890',
          messagingSenderId: '1234567890',
          projectId: 'qurity',
          storageBucket: 'qurity.appspot.com',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}