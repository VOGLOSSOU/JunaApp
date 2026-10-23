import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class SubscriptionInstructions extends StatelessWidget {
  final String? instructions;
  const SubscriptionInstructions({super.key, this.instructions});

  @override
  Widget build(BuildContext context) {
    final text = instructions?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Précisions du prestataire',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 14, height: 1.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
