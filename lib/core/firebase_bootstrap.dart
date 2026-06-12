import 'package:firebase_core/firebase_core.dart';
import 'package:businesscard/firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirebaseStatus {
  const FirebaseStatus({required this.isConfigured, required this.message});

  const FirebaseStatus.configured()
    : isConfigured = true,
      message = 'Firebase is connected.';

  const FirebaseStatus.unconfigured([
    this.message =
        'Firebase is not configured yet. Add your Firebase config files to enable uploads.',
  ]) : isConfigured = false;

  final bool isConfigured;
  final String message;
}

final firebaseStatusProvider = Provider<FirebaseStatus>(
  (ref) => const FirebaseStatus.unconfigured(),
);

Future<FirebaseStatus> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    return const FirebaseStatus.configured();
  } catch (error) {
    return FirebaseStatus.unconfigured(
      'Firebase is not configured yet. Add '
      '`google-services.json` and `GoogleService-Info.plist`, then restart the app.\n$error',
    );
  }
}
