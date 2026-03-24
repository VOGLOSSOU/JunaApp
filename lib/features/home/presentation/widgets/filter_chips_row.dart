import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/enums.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import 'filter_bottom_sheet.dart';

class FilterChipsRow extends ConsumerStatefulWidget {
  const FilterChipsRow({super.key});

  @override
  ConsumerState<FilterChipsRow> createState() => _FilterChipsRowState();
}

class _FilterChipsRowState extends ConsumerState<FilterChipsRow> {
  final _scrollController = ScrollController();
  bool _showArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final atEnd = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 8;
      if (atEnd != !_showArrow) {
        setState(() => _showArrow = !atEnd);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(filterControllerProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Chips types de repas scrollables + flèche
        Expanded(
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              SingleChildScrollView(
                controller: _scrollController,
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
                    const SizedBox(width: AppSpacing.xl),
                  ],
                ),
              ),
              if (_showArrow)
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
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
