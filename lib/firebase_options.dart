// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: 'AIzaSyBVQiNDD1C2zZAB6mn0UVdUJViqCtINnsE',
      appId: '1:920937722882:android:1f9fdd2d8ab22e5782e31b',
      messagingSenderId: '920937722882',
      projectId: 'currencytradeapp',
      // Copy these values from google-services.json
    );
  }
}
