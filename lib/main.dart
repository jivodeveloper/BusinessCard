import 'package:businesscard/app/app.dart';
import 'package:businesscard/core/firebase_bootstrap.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseStatus = await bootstrapFirebase();

  runApp(
    ProviderScope(
      overrides: [firebaseStatusProvider.overrideWithValue(firebaseStatus)],
      child: const BusinessCardApp(),
    ),
  );
}
