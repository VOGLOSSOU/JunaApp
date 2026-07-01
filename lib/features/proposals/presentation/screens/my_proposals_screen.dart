import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../domain/entities/subscription_proposal_entity.dart';
import '../controllers/my_proposals_controller.dart';

class MyProposalsScreen extends ConsumerStatefulWidget {
  const MyProposalsScreen({super.key});

  @override
  ConsumerState<MyProposalsScreen> createState() => _MyProposalsScreenState();
}

class _MyProposalsScreenState extends ConsumerState<MyProposalsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProposalsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(myProposalsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProposalsControllerProvider);
    final isFirstLoad = state.isLoading && state.items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text('Mes propositions'),
      ),
      body: isFirstLoad
          ? const _ProposalListSkeleton()
          : state.error != null && state.items.isEmpty
              ? _buildError(state.error!)
              : state.items.isEmpty
                  ? _buildEmpty(context)
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(myProposalsControllerProvider.notifier).load(),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              child: Center(
                                child: CircularProgressIndicator(color: AppColors.primary),
                              ),
                            );
                          }
                          return _ProposalCard(proposal: state.items[i]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text('Impossible de charger vos propositions',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => ref.read(myProposalsControllerProvider.notifier).load(),
              child: Text('Réessayer',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: AppColors.textLight),
            const SizedBox(height: AppSpacing.lg),
            Text('Aucune proposition envoyée',
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Composez un abonnement sur mesure depuis le profil d\'un prestataire.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text('Découvrir des prestataires',
                  style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte de proposition ────────────────────────────────────────────────────────

class _ProposalCard extends StatelessWidget {
  final SubscriptionProposalEntity proposal;
  const _ProposalCard({required this.proposal});

  _StatusStyle _statusStyle() {
    switch (proposal.status) {
      case ProposalStatus.pending:
        return _StatusStyle(
          bg: AppColors.surfaceGrey,
          fg: AppColors.textSecondary,
          label: 'En attente',
        );
      case ProposalStatus.approved:
        return _StatusStyle(
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF2E7D32),
          label: 'Approuvée',
        );
      case ProposalStatus.rejected:
        return _StatusStyle(
          bg: const Color(0xFFFFEBEE),
          fg: AppColors.error,
          label: 'Rejetée',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle();
    final summary =
        '${proposal.type.label} · ${proposal.duration.label} · ${proposal.meals.length} plat${proposal.meals.length > 1 ? 's' : ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Ligne du haut ────────────────────────────────────────────────
          Row(
            children: [
              JunaAvatar(
                imageUrl: proposal.providerLogo.isNotEmpty ? proposal.providerLogo : null,
                initials: proposal.providerName.isNotEmpty
                    ? proposal.providerName.substring(0, proposal.providerName.length.clamp(0, 2)).toUpperCase()
                    : '?',
                size: 32,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  proposal.providerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: status.fg,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Résumé ───────────────────────────────────────────────────────
          Text(
            summary,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          // ── Message ──────────────────────────────────────────────────────
          if (proposal.message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '« ${proposal.message} »',
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          // ── Rejet / approbation ──────────────────────────────────────────
          if (proposal.status == ProposalStatus.rejected &&
              proposal.rejectionReason != null &&
              proposal.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              proposal.rejectionReason!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
          if (proposal.status == ProposalStatus.approved &&
              proposal.resultingSubscriptionId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () =>
                  context.push('/subscriptions/${proposal.resultingSubscriptionId}'),
              child: Text(
                'Voir l\'abonnement →',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // ── Date ─────────────────────────────────────────────────────────
          Text(
            '${proposal.createdAt.day}/${proposal.createdAt.month}/${proposal.createdAt.year}',
            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  final Color bg;
  final Color fg;
  final String label;
  const _StatusStyle({required this.bg, required this.fg, required this.label});
}

class _ProposalListSkeleton extends StatelessWidget {
  const _ProposalListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: JunaSkeleton.line(width: double.infinity, height: 16)),
                const SizedBox(width: AppSpacing.md),
                JunaSkeleton(width: 70, height: 22, borderRadius: AppRadius.full),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const JunaSkeleton.line(width: 200, height: 13),
            const SizedBox(height: AppSpacing.sm),
            const JunaSkeleton.line(width: double.infinity, height: 13),
            const SizedBox(height: 4),
            const JunaSkeleton.line(width: 160, height: 13),
          ],
        ),
      ),
    );
  }
}
