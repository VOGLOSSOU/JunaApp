import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  static const _code = 'JUNA-MARC24';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Parrainer un ami'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: AppSpacing.lg),
            Text('Parrainez vos amis',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Invitez vos amis à rejoindre Juna. Vous recevez tous les deux une réduction sur votre prochain abonnement.',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Code
            Text('Votre code de parrainage', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                Clipboard.setData(const ClipboardData(text: _code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copié !')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _code,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.copy_outlined,
                        color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            JunaButton(
              label: 'Partager mon code',
              icon: Icons.share_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
