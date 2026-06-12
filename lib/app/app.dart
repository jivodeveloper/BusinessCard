import 'package:businesscard/app/theme.dart';
import 'package:businesscard/features/auth/application/auth_controller.dart';
import 'package:businesscard/features/auth/presentation/login_page.dart';
import 'package:businesscard/features/cards/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessCardApp extends ConsumerWidget {
  const BusinessCardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Business Card',
      debugShowCheckedModeBanner: false,
      theme: buildBusinessCardTheme(),
      home: authState.isAuthenticated ? const HomePage() : const LoginPage(),
    );
  }
}
