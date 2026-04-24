import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';

class BecomeProviderScreen extends StatelessWidget {
  const BecomeProviderScreen({super.key});

  static const _webUrl = 'https://junaeats.com';

  Future<void> _openWeb() async {
    final uri = Uri.parse(_webUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ─────────────────────────────────────────────────────────
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.primary, size: 44),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'Rejoignez le réseau Juna',
                style: AppTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                'Développez votre activité culinaire et touchez de nouveaux clients chaque semaine.',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── Avantages ────────────────────────────────────────────────────
            Text('Ce que vous pouvez faire', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            const _Benefit(
              icon: Icons.restaurant_menu_outlined,
              title: 'Créez vos abonnements repas',
              description:
                  'Définissez vos formules, vos prix et vos plats. Vous gardez le contrôle total sur votre offre.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(
              icon: Icons.people_outline_rounded,
              title: 'Gérez vos clients',
              description:
                  'Suivez vos abonnés, leurs préférences et leurs commandes depuis votre tableau de bord.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(
              icon: Icons.bar_chart_rounded,
              title: 'Suivez vos performances',
              description:
                  'Accédez à vos statistiques de ventes, avis clients et revenus en temps réel.',
            ),
            const SizedBox(height: AppSpacing.md),
            const _Benefit(
              icon: Icons.delivery_dining_outlined,
              title: 'Livraison ou retrait',
              description:
                  'Proposez la livraison à domicile, le retrait sur place, ou les deux selon vos capacités.',
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── Prérequis ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vous avez déjà un compte JUNA ? C\'est tout ce qu\'il vous faut pour soumettre votre demande.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.primary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Informations requises ─────────────────────────────────────────
            Text('Informations à fournir', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  _InfoItem(text: 'Nom de votre établissement'),
                  _InfoItem(text: 'Description de votre activité'),
                  _InfoItem(text: 'Adresse professionnelle'),
                  _InfoItem(text: 'Ville où vous opérez'),
                  _InfoItem(text: 'Numéro de téléphone professionnel'),
                  _InfoItem(text: 'Logo de votre établissement'),
                  _InfoItem(
                      text: 'Document justificatif (optionnel mais recommandé)',
                      optional: true),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Comment s'inscrire ───────────────────────────────────────────
            Text('Comment faire votre demande ?', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Step(
                      number: '1',
                      text: 'Connectez-vous à votre compte sur junaeats.com'),
                  const SizedBox(height: AppSpacing.sm),
                  const _Step(
                      number: '2',
                      text: 'Allez dans Paramètres → Paramètres du compte'),
                  const SizedBox(height: AppSpacing.sm),
                  const _Step(
                      number: '3',
                      text: 'Cliquez sur "Devenir prestataire" et remplissez le formulaire avec les informations ci-dessus'),
                  const SizedBox(height: AppSpacing.sm),
                  const _Step(
                      number: '4',
                      text: 'Votre demande est transmise à l\'équipe JUNA pour vérification'),
                  const SizedBox(height: AppSpacing.sm),
                  const _Step(
                      number: '5',
                      text: 'Si approuvée, votre compte bascule automatiquement en mode prestataire — vous pouvez immédiatement créer vos abonnements et recevoir des commandes'),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ── CTA ──────────────────────────────────────────────────────────
            JunaButton(
              label: 'Aller sur junaeats.com',
              onPressed: _openWeb,
            ),
            const SizedBox(height: AppSpacing.md),
            JunaButton(
              label: 'Retour',
              variant: JunaButtonVariant.outline,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.labelLarge),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;
  final bool optional;

  const _InfoItem({required this.text, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            optional ? Icons.radio_button_unchecked_rounded : Icons.circle,
            size: optional ? 8 : 6,
            color: optional ? AppColors.textLight : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: optional ? AppColors.textSecondary : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.white,
                fontSize: 11,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}
