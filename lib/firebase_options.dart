import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are currently only implemented for web.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAvlvk7sEzIZNtq0kWF015v7rtxn24LTYg",
    appId: "1:390050157596:web:2d106085051b4087f2bbd9",
    messagingSenderId: "390050157596",
    projectId: "flacroncv-9340f",
    authDomain: "flacroncv-9340f.firebaseapp.com",
    storageBucket: "flacroncv-9340f.firebasestorage.app",
    measurementId: "G-NZZ4Y1S0J5",
  );
}