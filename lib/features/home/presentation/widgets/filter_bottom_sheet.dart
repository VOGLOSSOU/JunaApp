import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/services/location_repository.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../../features/auth/data/models/auth_models.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../controllers/location_controller.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late SubscriptionDuration? _duration;
  late SubscriptionCategory? _category;
  late String? _landmarkId;
  List<LandmarkModel> _landmarks = [];
  bool _isLoadingLandmarks = false;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(filterControllerProvider);
    _duration = filters.duration;
    _category = filters.category;
    _landmarkId = filters.landmarkId;
    _loadLandmarks();
  }

  Future<void> _loadLandmarks() async {
    final location = ref.read(locationControllerProvider);
    final cityId = location.cityId;
    if (cityId == null) return;

    setState(() => _isLoadingLandmarks = true);
    try {
      final repo = ref.read(locationRepositoryProvider);
      final landmarks = await repo.getLandmarksByCity(cityId);
      setState(() {
        _landmarks = landmarks;
        _isLoadingLandmarks = false;
      });
    } catch (_) {
      setState(() => _isLoadingLandmarks = false);
    }
  }

  void _apply() {
    final notifier = ref.read(filterControllerProvider.notifier);
    notifier.setDuration(_duration);
    notifier.setCategory(_category);
    notifier.setLandmark(_landmarkId);
    // Reload subscriptions with new filters
    ref.read(subscriptionsControllerProvider.notifier).load(refresh: true);
    Navigator.pop(context);
  }

  void _reset() {
    ref.read(filterControllerProvider.notifier).reset();
    ref.read(subscriptionsControllerProvider.notifier).load(refresh: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Filtres', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.xl),

          // 1 — Durée
          Text('Durée', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: SubscriptionDuration.values.map((d) {
              final selected = _duration == d;
              return GestureDetector(
                onTap: () => setState(() => _duration = selected ? null : d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    d.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? AppColors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 2 — Catégories
          Text('Catégorie', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: SubscriptionCategory.values.map((c) {
              final selected = _category == c;
              return GestureDetector(
                onTap: () => setState(() => _category = selected ? null : c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    c.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: selected ? AppColors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // 3 — Zones de référence (uniquement si une ville avec ID est sélectionnée)
          if (ref.read(locationControllerProvider).cityId != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Zone de référence', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            if (_isLoadingLandmarks)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_landmarks.isEmpty)
              Text('Aucune zone disponible',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary))
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _landmarkId = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _landmarkId == null ? AppColors.primary : AppColors.surfaceGrey,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'Toutes les zones',
                        style: AppTypography.labelSmall.copyWith(
                          color: _landmarkId == null ? AppColors.white : AppColors.textSecondary,
                          fontWeight: _landmarkId == null ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  ..._landmarks.map((landmark) {
                    final selected = _landmarkId == landmark.id;
                    return GestureDetector(
                      onTap: () => setState(() => _landmarkId = selected ? null : landmark.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          landmark.name,
                          style: AppTypography.labelSmall.copyWith(
                            color: selected ? AppColors.white : AppColors.textSecondary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],

          const SizedBox(height: AppSpacing.xxxl),

          // Actions
          Row(
            children: [
              Expanded(
                child: JunaButton(
                  label: 'Réinitialiser',
                  variant: JunaButtonVariant.outline,
                  onPressed: _reset,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: JunaButton(
                  label: 'Appliquer',
                  variant: JunaButtonVariant.primary,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
