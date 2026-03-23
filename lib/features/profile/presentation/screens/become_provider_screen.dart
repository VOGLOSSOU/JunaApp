import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';

class BecomeProviderScreen extends StatefulWidget {
  const BecomeProviderScreen({super.key});

  @override
  State<BecomeProviderScreen> createState() => _BecomeProviderScreenState();
}

class _BecomeProviderScreenState extends State<BecomeProviderScreen> {
  final _businessNameCtrl = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _cityCtrl         = TextEditingController();
  bool _isSubmitting      = false;
  bool _submitted         = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Devenir prestataire'),
      ),
      body: _submitted ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Rejoignez notre réseau de prestataires et développez votre activité culinaire.',
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          _Field(label: 'Nom du commerce', ctrl: _businessNameCtrl,
              hint: 'Chez Mariam, Le Traiteur du Golfe...'),
          const SizedBox(height: AppSpacing.lg),
          _Field(label: 'Description', ctrl: _descCtrl,
              hint: 'Décrivez votre cuisine et votre spécialité...',
              maxLines: 4),
          const SizedBox(height: AppSpacing.lg),
          _Field(label: 'Téléphone', ctrl: _phoneCtrl,
              hint: '+229 97 00 00 00',
              keyboardType: TextInputType.phone),
          const SizedBox(height: AppSpacing.lg),
          _Field(label: 'Ville', ctrl: _cityCtrl,
              hint: 'Cotonou, Porto-Novo...'),
          const SizedBox(height: AppSpacing.xxxl),

          JunaButton(
            label: 'Envoyer ma candidature',
            isLoading: _isSubmitting,
            variant: JunaButtonVariant.secondary,
            onPressed: () async {
              setState(() => _isSubmitting = true);
              await Future.delayed(const Duration(seconds: 2));
              setState(() { _isSubmitting = false; _submitted = true; });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Candidature envoyée !',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Notre équipe examinera votre candidature et vous contactera dans les 48h.',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            JunaButton(
              label: 'Retour au profil',
              variant: JunaButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  const _Field({
    required this.label,
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
