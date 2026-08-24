import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../domain/entities/subscription_proposal_entity.dart';
import '../controllers/my_proposals_controller.dart';

class ProposalDetailScreen extends ConsumerWidget {
  final String proposalId;
  const ProposalDetailScreen({super.key, required this.proposalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proposalDetailProvider(proposalId));

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/proposals'),
        ),
        title: const Text('Ma proposition'),
      ),
      body: async.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (proposal) => _buildContent(context, proposal),
      ),
    );
  }

  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const JunaSkeleton(
              width: double.infinity, height: 72, borderRadius: 16),
          const SizedBox(height: AppSpacing.lg),
          const JunaSkeleton.line(width: 180, height: 20),
          const SizedBox(height: AppSpacing.md),
          const JunaSkeleton(
              width: double.infinity, height: 120, borderRadius: 16),
          const SizedBox(height: AppSpacing.md),
          const JunaSkeleton(
              width: double.infinity, height: 80, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text('Impossible de charger cette proposition',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(proposalDetailProvider(proposalId)),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubscriptionProposalEntity p) {
    final statusStyle = _statusStyle(p.status);
    final summary =
        '${p.type.label} · ${p.duration.label} · ${p.category.label}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Statut ─────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: statusStyle.bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(statusStyle.icon, color: statusStyle.fg, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.status.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: statusStyle.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.status == ProposalStatus.rejected &&
                                (p.rejectionReason?.isNotEmpty ?? false)
                            ? p.rejectionReason!
                            : p.status.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusStyle.fg.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Lien vers l'abonnement si approuvée ───────────────────────────
          if (p.status == ProposalStatus.approved &&
              p.resultingSubscriptionId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () =>
                  context.push('/subscriptions/${p.resultingSubscriptionId}'),
              child: Row(
                children: [
                  Text(
                    'Voir l\'abonnement',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.primary),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // ── Prestataire ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push('/providers/${p.providerId}'),
            child: Row(
              children: [
                JunaAvatar(
                  imageUrl: p.providerLogo.isNotEmpty ? p.providerLogo : null,
                  initials: p.providerName.isNotEmpty
                      ? p.providerName
                          .substring(0, p.providerName.length.clamp(0, 2))
                          .toUpperCase()
                      : '?',
                  size: 44,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.providerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Voir le profil',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Détails de la formule ────────────────────────────────────────
          const Text('VOTRE DEMANDE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              )),
          const SizedBox(height: 8),
          Text(summary,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),

          if (p.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '« ${p.message} »',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // ── Plats demandés ────────────────────────────────────────────────
          Text('Plats demandés (${p.meals.length})',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...p.meals.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProposalMealRow(meal: m),
              )),

          const SizedBox(height: AppSpacing.xl),

          // ── Date ───────────────────────────────────────────────────────
          Text(
            'Envoyée le ${formatDate(p.createdAt)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  _StatusStyle _statusStyle(ProposalStatus status) {
    switch (status) {
      case ProposalStatus.pending:
        return _StatusStyle(
          bg: AppColors.surfaceGrey,
          fg: AppColors.textSecondary,
          icon: Icons.hourglass_empty_rounded,
        );
      case ProposalStatus.approved:
        return _StatusStyle(
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF2E7D32),
          icon: Icons.check_circle_outline_rounded,
        );
      case ProposalStatus.rejected:
        return _StatusStyle(
          bg: const Color(0xFFFFEBEE),
          fg: AppColors.error,
          icon: Icons.cancel_outlined,
        );
    }
  }
}

class _StatusStyle {
  final Color bg;
  final Color fg;
  final IconData icon;
  _StatusStyle({required this.bg, required this.fg, required this.icon});
}

class _ProposalMealRow extends StatelessWidget {
  final ProposalMealEntity meal;
  const _ProposalMealRow({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: meal.mealImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: meal.mealImageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primarySurface,
                        child: const Icon(Icons.restaurant,
                            color: AppColors.primary, size: 20),
                      ),
                    )
                  : Container(
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.restaurant,
                          color: AppColors.primary, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meal.mealPricingLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meal.mealPricingLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  'Quantité : ${meal.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatPrice(meal.mealPrice.toDouble()),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
