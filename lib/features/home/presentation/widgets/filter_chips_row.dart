import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import 'filter_bottom_sheet.dart';

class FilterChipsRow extends ConsumerWidget {
  const FilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterControllerProvider);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          // Chips types de repas scrollables
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _CategoryChip(
                  label: 'Tous',
                  isSelected: filters.type == null,
                  onTap: () => ref.read(filterControllerProvider.notifier).setType(null),
                ),
                ...SubscriptionType.values.map((t) => _CategoryChip(
                      label: t.label,
                      isSelected: filters.type == t,
                      onTap: () => ref.read(filterControllerProvider.notifier).setType(t),
                    )),
              ],
            ),
          ),

          // Bouton filtres
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const FilterBottomSheet(),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.lg),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: filters.hasFilters
                    ? AppColors.primarySurface
                    : AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: filters.hasFilters
                    ? Border.all(color: AppColors.primary, width: 1)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded,
                      size: 14,
                      color: filters.hasFilters
                          ? AppColors.primary
                          : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    filters.activeCount > 0
                        ? 'Filtres (${filters.activeCount})'
                        : 'Filtres',
                    style: AppTypography.labelSmall.copyWith(
                      color: filters.hasFilters
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isSelected ? AppColors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
