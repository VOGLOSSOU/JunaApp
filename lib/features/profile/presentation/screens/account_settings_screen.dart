import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _countryCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _countryCtrl = TextEditingController(text: user?.country ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Paramètres du compte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  JunaAvatar(
                    imageUrl: user?.avatarUrl,
                    initials: user?.initials ?? '?',
                    size: 88,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            Text('Nom complet', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Votre nom complet'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Téléphone', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+229 97 00 00 00'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Email', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              enabled: false,
              controller: TextEditingController(text: user?.email ?? ''),
              decoration: const InputDecoration(
                hintText: 'Email',
                suffixIcon: Icon(Icons.lock_outline,
                    color: AppColors.textLight, size: 16),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Ville', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _cityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Votre ville'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Pays', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _countryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Votre pays'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Erreur API
            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        authState.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xxxl),

            JunaButton(
              label: 'Sauvegarder',
              isLoading: _isSaving,
              variant: JunaButtonVariant.secondary,
              onPressed: () async {
                setState(() => _isSaving = true);
                final success = await ref
                    .read(authControllerProvider.notifier)
                    .updateProfile(
                      name: _nameCtrl.text.trim(),
                      phone: _phoneCtrl.text.trim(),
                    );
                if (success) {
                  // Update local fields
                  final authController =
                      ref.read(authControllerProvider.notifier);
                  final currentUser = ref.read(authControllerProvider).user;
                  if (currentUser != null) {
                    final updatedUser = currentUser.copyWith(
                      city: _cityCtrl.text.trim(),
                      country: _countryCtrl.text.trim(),
                    );
                    authController.updateUser(updatedUser);
                  }
                  if (context.mounted) context.pop();
                }
                setState(() => _isSaving = false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
