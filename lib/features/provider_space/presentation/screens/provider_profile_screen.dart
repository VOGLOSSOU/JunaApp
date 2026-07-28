import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../../core/widgets/juna_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';
import '../../../subscriptions/domain/entities/provider_entity.dart';
import '../../../subscriptions/domain/entities/subscription_entity.dart';
import '../controllers/provider_detail_controller.dart';

class ProviderProfileScreen extends ConsumerWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerAsync = ref.watch(providerDetailProvider(providerId));
    final isAuthenticated = ref.watch(authControllerProvider).user != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: providerAsync.when(
        loading: () => const _ProviderProfileSkeleton(),
        error: (e, _) => _buildError(context, ref),
        data: (provider) => _ProviderProfileBody(
          provider: provider,
          isAuthenticated: isAuthenticated,
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: AppColors.textLight),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Impossible de charger ce profil',
                        style: AppTypography.titleMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => refreshProviderDetail(ref, providerId),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Corps de la page (une fois le provider chargé) ────────────────────────────

class _ProviderProfileBody extends StatefulWidget {
  final ProviderEntity provider;
  final bool isAuthenticated;
  const _ProviderProfileBody(
      {required this.provider, required this.isAuthenticated});

  @override
  State<_ProviderProfileBody> createState() => _ProviderProfileBodyState();
}

class _ProviderProfileBodyState extends State<_ProviderProfileBody> {
  // 0 = abonnements, 1 = plats
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.provider.subscriptions.isEmpty &&
        widget.provider.meals.isNotEmpty) {
      _tab = 1;
    }
  }

  String _locationLine(ProviderEntity p) {
    final address = p.businessAddress.trim();
    final city = p.city.name.trim();
    if (address.isNotEmpty && city.isNotEmpty) return '$address, $city';
    if (address.isNotEmpty) return address;
    return city;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final coverItems =
        p.subscriptions.where((s) => s.imageUrl.isNotEmpty).toList();
    final hasSubs = p.subscriptions.isNotEmpty;
    final hasMeals = p.meals.isNotEmpty;
    final location = _locationLine(p);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CoverCarousel(items: coverItems),

          // ── En-tête compact ───────────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primarySurface,
                      border: Border.all(color: AppColors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: p.logo.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: p.logo,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _Initials(name: p.name),
                            )
                          : _Initials(name: p.name),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                style: AppTypography.headlineMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 5),
                              const Icon(Icons.verified,
                                  color: Color(0xFF3B82F6), size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        _RatingMemberSinceLine(provider: p),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Localisation ──────────────────────────────────────────────────
          if (location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.textLight),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // ── Livraison / retrait ───────────────────────────────────────────
          if (p.acceptsDelivery || p.acceptsPickup)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.acceptsDelivery)
                    _PlainInfoLine(
                      icon: Icons.delivery_dining_outlined,
                      text: p.deliveryZones.isNotEmpty
                          ? 'Livraison · ${p.deliveryZones.join(', ')}'
                          : 'Livraison',
                    ),
                  if (p.acceptsDelivery && p.acceptsPickup)
                    const SizedBox(height: 4),
                  if (p.acceptsPickup)
                    _PlainInfoLine(
                      icon: Icons.storefront_outlined,
                      text: p.pickupPoints.isNotEmpty
                          ? 'Retrait sur place · ${p.pickupPoints.map((e) => e.name).join(', ')}'
                          : 'Retrait sur place',
                    ),
                ],
              ),
            ),

          // ── Description ───────────────────────────────────────────────────
          if (p.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Text(
                p.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

          // ── Proposer un abonnement personnalisé ──────────────────────────
          if (hasMeals)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: JunaButton(
                label: 'Créer un abonnement',
                variant: JunaButtonVariant.secondary,
                borderRadius: AppRadius.full,
                onPressed: () {
                  if (widget.isAuthenticated) {
                    context.push('/providers/${p.id}/propose');
                  } else {
                    context.push(
                        '${AppRoutes.login}?redirect=/providers/${p.id}/propose');
                  }
                },
              ),
            ),

          const SizedBox(height: AppSpacing.xl),

          // ── Onglets + grille / état vide ──────────────────────────────────
          if (!hasSubs && !hasMeals)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.xxxl),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 56, color: AppColors.textLight),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Ce prestataire n\'a pas encore publié de contenu.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (hasSubs && hasMeals)
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _UnderlineTab(
                        icon: Icons.window_rounded,
                        label: 'Abonnements (${p.subscriptions.length})',
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                    ),
                    Expanded(
                      child: _UnderlineTab(
                        icon: Icons.restaurant_rounded,
                        label: 'Plats (${p.meals.length})',
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  hasSubs
                      ? 'Ses abonnements (${p.subscriptions.length})'
                      : 'Ses plats (${p.meals.length})',
                  style: AppTypography.titleLarge,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _ContentGrid(
              subscriptions: hasSubs && (!hasMeals || _tab == 0)
                  ? p.subscriptions
                  : const [],
              meals: hasMeals && (!hasSubs || _tab == 1) ? p.meals : const [],
            ),
          ],

          // ── Points de retrait détaillés ───────────────────────────────────
          if (p.pickupPoints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child:
                  Text('Points de retrait', style: AppTypography.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: p.pickupPoints
                    .map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

// ── Cover (carrousel auto-défilant) ───────────────────────────────────────────

class _CoverCarousel extends StatefulWidget {
  final List<SubscriptionEntity> items;
  const _CoverCarousel({required this.items});

  @override
  State<_CoverCarousel> createState() => _CoverCarouselState();
}

class _CoverCarouselState extends State<_CoverCarousel> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.items.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;

    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (items.isEmpty)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
            )
          else
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild
                ],
              ),
              child: CachedNetworkImage(
                key: ValueKey(items[_index].id),
                imageUrl: items[_index].imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const ColoredBox(color: AppColors.primary),
              ),
            ),

          // Bouton retour (haut gauche)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CircleIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                ),
              ),
            ),
          ),

          // Bouton flèche → abonnement affiché (haut droite)
          if (items.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Align(
                  alignment: Alignment.topRight,
                  child: _CircleIconButton(
                    icon: Icons.north_east_rounded,
                    filled: true,
                    onTap: () =>
                        context.push('/subscriptions/${items[_index].id}'),
                  ),
                ),
              ),
            ),

          // Indicateurs (points)
          if (items.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color:
              filled ? AppColors.white : Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: filled ? AppColors.accent : Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

// ── Petits widgets internes ────────────────────────────────────────────────────

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty
            ? name.substring(0, name.length.clamp(0, 2)).toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RatingMemberSinceLine extends StatelessWidget {
  final ProviderEntity provider;
  const _RatingMemberSinceLine({required this.provider});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (provider.rating > 0) {
      parts.add(
          '★ ${provider.rating.toStringAsFixed(1)}${provider.reviewCount > 0 ? ' (${provider.reviewCount} avis)' : ''}');
    }
    if (provider.memberSince != null) {
      parts.add('Membre depuis ${formatMonthYear(provider.memberSince!)}');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _PlainInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PlainInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _UnderlineTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _UnderlineTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Grille type Instagram (abonnements + plats) ────────────────────────────────

class _ContentGrid extends StatelessWidget {
  final List<SubscriptionEntity> subscriptions;
  final List<MealEntity> meals;

  const _ContentGrid({required this.subscriptions, required this.meals});

  String _mealPriceLabel(MealEntity meal) {
    switch (meal.priceType) {
      case MealPriceType.multiple:
        return 'Dès ${formatPrice(meal.price.toDouble())}';
      case MealPriceType.range:
        return '${formatPrice((meal.priceMin ?? 0).toDouble())}–${formatPrice((meal.priceMax ?? 0).toDouble())}';
      case MealPriceType.fixed:
        return formatPrice(meal.price.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ...subscriptions.map((s) => _GridTile(
            imageUrl: s.imageUrl,
            name: s.title,
            priceLabel: formatPrice(s.price),
            onTap: () => context.push('/subscriptions/${s.id}'),
          )),
      ...meals.map((m) => _GridTile(
            imageUrl: m.imageUrl,
            name: m.name,
            priceLabel: _mealPriceLabel(m),
            onTap: () => context.push('/meals/${m.id}'),
          )),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        final tileSize = (constraints.maxWidth - spacing * 2) / 3;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((t) => SizedBox(width: tileSize, height: tileSize, child: t))
              .toList(),
        );
      },
    );
  }
}

class _GridTile extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String priceLabel;
  final VoidCallback onTap;

  const _GridTile({
    required this.imageUrl,
    required this.name,
    required this.priceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.primarySurface,
                    child:
                        const Icon(Icons.restaurant, color: AppColors.primary),
                  ),
                )
              : Container(
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.restaurant, color: AppColors.primary),
                ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  priceLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton de chargement ────────────────────────────────────────────────────

class _ProviderProfileSkeleton extends StatelessWidget {
  const _ProviderProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          JunaSkeleton(
            width: double.infinity,
            height: 240,
            borderRadius: 0,
          ),

          // En-tête : avatar + nom
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: JunaSkeleton(
                    width: 72,
                    height: 72,
                    borderRadius: 999,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        JunaSkeleton.line(width: 160, height: 18),
                        SizedBox(height: 8),
                        JunaSkeleton.line(width: 100, height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Localisation
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: const JunaSkeleton.line(width: 180, height: 13),
          ),

          // Livraison / retrait
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              children: const [
                JunaSkeleton.line(width: double.infinity, height: 13),
                SizedBox(height: 6),
                JunaSkeleton.line(width: 220, height: 13),
              ],
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Column(
              children: const [
                JunaSkeleton.line(width: double.infinity, height: 13),
                SizedBox(height: 6),
                JunaSkeleton.line(width: double.infinity, height: 13),
                SizedBox(height: 6),
                JunaSkeleton.line(width: 200, height: 13),
              ],
            ),
          ),

          // Bouton
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: JunaSkeleton(
              width: double.infinity,
              height: 52,
              borderRadius: AppRadius.full,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Onglets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: JunaSkeleton(
                    width: double.infinity,
                    height: 36,
                    borderRadius: AppRadius.sm,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: JunaSkeleton(
                    width: double.infinity,
                    height: 36,
                    borderRadius: AppRadius.sm,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Grille 3 colonnes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = (constraints.maxWidth - AppSpacing.sm * 2) / 3;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: List.generate(
                    6,
                    (_) => JunaSkeleton(
                      width: size,
                      height: size,
                      borderRadius: AppRadius.md,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
