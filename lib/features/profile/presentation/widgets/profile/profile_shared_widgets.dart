import 'package:empatia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Widgets compartilhados entre as seções do perfil.

// ── Section wrapper ──────────────────────────────────────────────────────────

class ProfileSectionWidget extends StatelessWidget {
  final String emoji;
  final String title;
  final int? count;
  final Widget child;

  const ProfileSectionWidget({
    Key? key,
    required this.emoji,
    required this.title,
    this.count,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.kidsPink.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kidsPink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class ProfileEmptyStateWidget extends StatelessWidget {
  final String emoji;
  final String message;
  final String sub;

  const ProfileEmptyStateWidget({
    Key? key,
    required this.emoji,
    required this.message,
    required this.sub,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(message,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}