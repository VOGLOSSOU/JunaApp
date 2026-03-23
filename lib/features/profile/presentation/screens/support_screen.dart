import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String? _category;
  final _msgCtrl   = TextEditingController();
  bool _submitting = false;
  bool _submitted  = false;

  static const _categories = [
    'Problème de commande',
    'Problème de paiement',
    'Problème avec un prestataire',
    'Problème technique',
    'Autre',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
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
        title: const Text('Contacter le support'),
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
          Text('Catégorie', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          ..._categories.map((c) => GestureDetector(
                onTap: () => setState(() => _category = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _category == c
                        ? AppColors.primarySurface
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _category == c
                          ? AppColors.primary
                          : AppColors.border,
                      width: _category == c ? 1.5 : 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(c,
                            style: AppTypography.bodyMedium.copyWith(
                              color: _category == c
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: _category == c
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            )),
                      ),
                      if (_category == c)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.xl),

          Text('Message', style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _msgCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Décrivez votre problème en détail...',
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),

          JunaButton(
            label: 'Envoyer',
            isLoading: _submitting,
            variant: JunaButtonVariant.secondary,
            onPressed: _category != null && _msgCtrl.text.isNotEmpty
                ? () async {
                    setState(() => _submitting = true);
                    await Future.delayed(const Duration(seconds: 1));
                    setState(() { _submitting = false; _submitted = true; });
                  }
                : null,
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
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Ticket envoyé !',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Notre équipe vous répondra dans les plus brefs délais.',
              style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            JunaButton(
              label: 'Retour',
              variant: JunaButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
