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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JunaSkeleton(
            width: double.infinity,
            height: 110,
            borderRadius: AppRadius.lg,
          ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JunaSkeleton.line(width: double.infinity, height: 16),
                SizedBox(height: AppSpacing.sm),
                JunaSkeleton.line(width: 120, height: 12),
                SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: JunaSkeleton.line(width: 70, height: 14)),
                    SizedBox(width: AppSpacing.sm),
                    JunaSkeleton(width: 52, height: 28, borderRadius: AppRadius.md),
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
