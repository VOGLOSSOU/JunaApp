import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoggingOut = false;
  late AnimationController _introCtrl;
  late Animation<double> _introFade;
  late Animation<double> _introScale;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _introFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut),
    );
    _introScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutBack),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await _introCtrl.forward();
    _pulseCtrl.repeat(reverse: true);

    await ref.read(authControllerProvider.notifier).logout();

    _pulseCtrl.stop();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Stack(
      children: [
      Scaffold(
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
                      onTap: _isLoggingOut ? null : _logout,
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
      ),

      if (_isLoggingOut)
        Positioned.fill(
          child: FadeTransition(
            opacity: _introFade,
            child: Container(
              color: AppColors.primaryDark,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_introCtrl, _pulseCtrl]),
                    builder: (_, __) => Transform.scale(
                      scale: _introScale.value * _pulse.value,
                      child: Image.asset(
                        'assets/images/juna-icon.png',
                        width: 180,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Déconnexion en cours…',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
