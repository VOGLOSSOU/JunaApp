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
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => context.push(AppRoutes.notifSettings),
                ),
                _MenuItem(
                  icon: Icons.favorite_outline,
                  label: 'Mes favoris',
                  onTap: () => context.push(AppRoutes.favorites),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── PRESTATAIRE ──────────────────────────────────────────────
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.restaurant_outlined,
                  label: 'Devenir prestataire',
                  highlighted: true,
                  onTap: () => context.push(AppRoutes.becomeProvider),
                ),
                _MenuItem(
                  icon: Icons.lightbulb_outline,
                  label: 'Proposer un abonnement',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Parrainer un ami',
                  onTap: () => context.push(AppRoutes.referral),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ── SUPPORT ──────────────────────────────────────────────────
            _MenuSection(
              items: [
                _MenuItem(
                  icon: Icons.chat_outlined,
                  label: 'Contacter le support',
                  onTap: () => context.push(AppRoutes.support),
                ),
                _MenuItem(
                  icon: Icons.flag_outlined,
                  label: 'Signaler un problème',
                  onTap: () {},
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
  final bool highlighted;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
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
        decoration: highlighted
            ? BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: highlighted ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: highlighted ? AppColors.primary : AppColors.textPrimary,
                  fontWeight:
                      highlighted ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: highlighted ? AppColors.primary : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
