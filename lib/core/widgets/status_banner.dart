import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? const Color(0xFFFDECEC)
        : const Color(0xFFEAF8EF);
    final foreground = isError
        ? const Color(0xFF9F1C1C)
        : const Color(0xFF146C2E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isError
              ? const Color(0xFFF6B7B7)
              : colors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}
