import 'package:businesscard/core/widgets/status_banner.dart';
import 'package:businesscard/features/auth/application/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -40,
              child: _SoftGlow(
                size: 240,
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              left: -70,
              bottom: 120,
              child: _SoftGlow(
                size: 220,
                color: const Color(0xFFD2C19D).withValues(alpha: 0.22),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.badge_outlined,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Text(
                          //   'Business Card',
                          //   style: theme.textTheme.headlineMedium?.copyWith(
                          //     fontWeight: FontWeight.w800,
                          //     letterSpacing: -1.2,
                          //     color: const Color(0xFF14201B),
                          //   ),
                          // ),
                          // const SizedBox(height: 10),
                          // Text(
                          //   'Welcome back',
                          //   style: theme.textTheme.headlineSmall?.copyWith(
                          //     fontWeight: FontWeight.w500,
                          //     color: const Color(0xFF26332D),
                          //   ),
                          // ),
                          // const SizedBox(height: 8),
                          // Text(
                          //   'Sign in with your username to scan cards and manage every saved contact in one calm workspace.',
                          //   style: theme.textTheme.bodyLarge?.copyWith(
                          //     height: 1.55,
                          //     color: const Color(0xFF4B564F),
                          //   ),
                          // ),
                          // const SizedBox(height: 24),
                          // StatusBanner(
                          //   message: firebaseStatus.message,
                          //   isError: !firebaseStatus.isConfigured,
                          // ),
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            StatusBanner(
                              message: authState.errorMessage!,
                              isError: true,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3EADB),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE3D7C0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Sign in',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // const SizedBox(height: 6),
                                // Text(
                                //   'Use your username to sign in. If this is the first time that username is used on this Firebase project, the app will create its mapped account automatically.',
                                //   style: theme.textTheme.bodyMedium?.copyWith(
                                //     color: const Color(0xFF606A63),
                                //   ),
                                // ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email or Username',
                                    helperText:
                                        'Use a Firebase email like aahar831@gmail.com, or enter a username.',
                                    prefixIcon: Icon(
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: authState.isLoading
                                      ? null
                                      : _submit,
                                  icon: authState.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.arrow_forward_rounded),
                                  label: Text(
                                    authState.isLoading
                                        ? 'Signing in...'
                                        : 'Sign in',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          username: _usernameController.text,
          password: _passwordController.text,
        );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
