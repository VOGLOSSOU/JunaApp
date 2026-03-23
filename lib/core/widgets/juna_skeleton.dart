import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

class JunaSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const JunaSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  const JunaSkeleton.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceGrey,
      highlightColor: AppColors.white,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceGrey,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class JunaSubscriptionCardSkeleton extends StatelessWidget {
  const JunaSubscriptionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JunaSkeleton(
            width: double.infinity,
            height: 160,
            borderRadius: AppRadius.lg,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const JunaSkeleton.line(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.sm),
                const JunaSkeleton.line(width: 120, height: 12),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const JunaSkeleton.line(width: 80, height: 14),
                    JunaSkeleton(width: 60, height: 32, borderRadius: AppRadius.md),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
