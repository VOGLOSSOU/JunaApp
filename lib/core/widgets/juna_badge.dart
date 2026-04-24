import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';
import '../../core/utils/enums.dart';

class JunaBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final String? emoji;

  const JunaBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.emoji,
  });

  factory JunaBadge.category(SubscriptionCategory category) {
    return JunaBadge(
      label: category.label,
      emoji: category.emoji,
      backgroundColor: AppColors.primarySurface,
      textColor: AppColors.primary,
    );
  }

  factory JunaBadge.orderStatus(OrderStatus status) {
    final (bg, fg) = _statusColors(status);
    return JunaBadge(
      label: status.label,
      backgroundColor: bg.withOpacity(0.12),
      textColor: bg,
    );
  }

  static (Color, Color) _statusColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:   return (AppColors.statusPending, AppColors.white);
      case OrderStatus.confirmed: return (AppColors.statusConfirmed, AppColors.white);
      case OrderStatus.active:    return (AppColors.statusCompleted, AppColors.white);
      case OrderStatus.cancelled: return (AppColors.statusCancelled, AppColors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primarySurface;
    final fg = textColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
