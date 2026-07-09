import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/juna_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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
    final isAuthenticated = ref.watch(authControllerProvider).isAuthenticated;

    if (!isAuthenticated) {
      return const _ProposalsUpsellScreen();
    }

    final state = ref.watch(myProposalsControllerProvider);
    final isFirstLoad = state.isLoading && state.items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: const Text('Mes propositions'),
      ),
      bottomNavigationBar: const _ProposalsBottomNav(),
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

// ── Page marketing (non connecté) ──────────────────────────────────────────────

class _ProposalsUpsellScreen extends StatelessWidget {
  const _ProposalsUpsellScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
      ),
      bottomNavigationBar: const _ProposalsBottomNav(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // ── Icône hero ─────────────────────────────────────────────
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    'Votre abonnement,\ncomposé par vous',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Accroche ───────────────────────────────────────────────
                  Text(
                    'Avec Juna Eats, vous ne subissez plus les menus imposés. Choisissez vos plats, votre rythme et votre prestataire - et envoyez votre proposition en quelques secondes.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // ── Étapes ────────────────────────────────────────────────
                  const _UpsellStep(
                    number: '1',
                    title: 'Parcourez les prestataires',
                    description: 'Explorez les cuisiniers et traiteurs autour de vous.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _UpsellStep(
                    number: '2',
                    title: 'Composez votre abonnement',
                    description: 'Sélectionnez vos plats préférés et adaptez la durée à vos besoins.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _UpsellStep(
                    number: '3',
                    title: 'Recevez une réponse rapide',
                    description: 'Le prestataire valide ou ajuste votre proposition. Vous êtes notifié immédiatement.',
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // ── CTA fixe en bas ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(
                  '${AppRoutes.login}?redirect=${Uri.encodeComponent(AppRoutes.myProposals)}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Se connecter pour commencer',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpsellStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _UpsellStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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

// ── Bottom nav (tab Profil actif) ──────────────────────────────────────────────

class _ProposalsBottomNav extends ConsumerWidget {
  const _ProposalsBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final u = ref.watch(authControllerProvider).user;
    return BottomNavigationBar(
      currentIndex: 3, // Profil actif
      onTap: (i) {
        switch (i) {
          case 0: context.go(AppRoutes.home);
          case 1: context.go(AppRoutes.explorer);
          case 2: context.go(AppRoutes.orders);
          case 3: context.go(AppRoutes.profile);
        }
      },
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Explorer',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Commandes',
        ),
        BottomNavigationBarItem(
          icon: _ProfileIcon(initials: u?.initials, avatarUrl: u?.avatarUrl, isActive: false),
          activeIcon: _ProfileIcon(initials: u?.initials, avatarUrl: u?.avatarUrl, isActive: true),
          label: 'Profil',
        ),
      ],
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final String? initials;
  final String? avatarUrl;
  final bool isActive;
  const _ProfileIcon({this.initials, this.avatarUrl, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (initials == null) return Icon(isActive ? Icons.person : Icons.person_outline);
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 2 : 1.5,
        ),
        color: AppColors.primarySurface,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          initials ?? '?',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      );
}

// ── Skeleton ────────────────────────────────────────────────────────────────────

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
