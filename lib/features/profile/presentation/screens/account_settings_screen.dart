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

class _AccountSettingsScreenState
    extends ConsumerState<AccountSettingsScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl  = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl     = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

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

            Text('Prénom', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _firstNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Votre prénom'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Nom', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _lastNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Votre nom'),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Téléphone', style: AppTypography.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration:
                  const InputDecoration(hintText: '+229 97 00 00 00'),
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

            const SizedBox(height: AppSpacing.xxxl),

            JunaButton(
              label: 'Sauvegarder',
              isLoading: _isSaving,
              variant: JunaButtonVariant.secondary,
              onPressed: () async {
                setState(() => _isSaving = true);
                await Future.delayed(const Duration(seconds: 1));
                setState(() => _isSaving = false);
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
