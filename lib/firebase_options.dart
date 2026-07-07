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
          apiKey: 'AIzaSyCMeydEO6IX_YtiR-kynhCBc5YFqxLbo3A',
          appId: '1:339029236820:android:b7a97499104509fdaba1c1',
          messagingSenderId: '339029236820',
          projectId: 'abudshisha',
          storageBucket: 'abudshisha.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyB3jkKZNhv0Zv8HaaOVTVFTmfCjAt2N-GU',
          appId: '1:339029236820:ios:336df0b29847ba54aba1c1',
          messagingSenderId: '339029236820',
          projectId: 'abudshisha',
          storageBucket: 'abudshisha.firebasestorage.app',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyB3jkKZNhv0Zv8HaaOVTVFTmfCjAt2N-GU',
          appId: '1:339029236820:macos:336df0b29847ba54aba1c1',
          messagingSenderId: '339029236820',
          projectId: 'abudshisha',
          storageBucket: 'abudshisha.firebasestorage.app',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
