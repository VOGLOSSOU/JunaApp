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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Chips types de repas scrollables avec fade droit
        Expanded(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.78, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _TypeChip(
                    label: 'Tous',
                    isSelected: filters.type == null,
                    onTap: () => ref.read(filterControllerProvider.notifier).setType(null),
                  ),
                  ...SubscriptionType.values.map((t) => _TypeChip(
                        label: t.label,
                        isSelected: filters.type == t,
                        onTap: () => ref.read(filterControllerProvider.notifier).setType(t),
                      )),
                  const SizedBox(width: AppSpacing.xxl),
                ],
              ),
            ),
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
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
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
          vertical: AppSpacing.sm,
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
