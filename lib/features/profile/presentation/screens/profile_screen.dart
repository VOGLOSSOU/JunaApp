import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text('Profil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── AVATAR + NOM ─────────────────────────────────────────────
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: user != null
                  ? Column(
                      children: [
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.accountSettings),
                          child: JunaAvatar(
                            imageUrl: user.avatarUrl,
                            initials: user.initials,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(user.fullName, style: AppTypography.titleLarge),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const JunaAvatar(initials: '?', size: 80),
                        const SizedBox(height: AppSpacing.md),
                        Text('Connexion requise',
                            style: AppTypography.titleMedium),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.login),
                          child: Text(
                            'Se connecter',
                            style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── COMPTE ───────────────────────────────────────────────────
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres du compte',
                  onTap: () => context.push(AppRoutes.accountSettings),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── PARAMÈTRES AVANCÉS ───────────────────────────────────────
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.tune_rounded,
                  label: 'Paramètres avancés',
                  onTap: () => context.push(AppRoutes.advancedSettings),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── DÉCONNEXION ──────────────────────────────────────────────
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: GestureDetector(
                  onTap: () {
                    ref.read(authControllerProvider.notifier).logout();
                    context.go(AppRoutes.home);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3), width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'Se déconnecter',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                    height: 1, indent: AppSpacing.lg + 40, endIndent: 0),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
