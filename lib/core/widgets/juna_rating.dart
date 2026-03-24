import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class JunaRating extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;
  final bool showCount;

  const JunaRating({
    super.key,
    required this.rating,
    this.reviewCount,
    this.size = 14,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: AppColors.accent, size: size + 2),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: size,
          ),
        ),
        if (showCount && reviewCount != null && reviewCount! > 0) ...[
          const SizedBox(width: 3),
          Text(
            '($reviewCount)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: size - 1,
            ),
          ),
        ],
      ],
    );
  }
}
