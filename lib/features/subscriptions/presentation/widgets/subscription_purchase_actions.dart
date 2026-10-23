import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class SubscriptionPurchaseActions extends StatelessWidget {
  final double price;
  final String durationLabel;
  final bool isAvailable;
  final VoidCallback onSubscribe;

  const SubscriptionPurchaseActions(
      {super.key,
      required this.price,
      required this.durationLabel,
      required this.isAvailable,
      required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    final amount = formatPrice(price).replaceFirst(' FCFA', '');
    final priceBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
            TextSpan(text: '$amount ', children: const [
              TextSpan(
                  text: 'FCFA',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            style: const TextStyle(
                fontSize: 22,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.accent)),
        const SizedBox(height: 4),
        Text(durationLabel,
            style: const TextStyle(
                fontSize: 12, height: 1.3, color: AppColors.textSecondary)),
      ],
    );
    final button = ElevatedButton(
      onPressed: isAvailable ? onSubscribe : null,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        backgroundColor: AppColors.accent,
        disabledBackgroundColor: AppColors.surfaceGrey,
        foregroundColor: AppColors.white,
        disabledForegroundColor: AppColors.textSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(isAvailable ? 'S’abonner' : 'Indisponible',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(15) > 20) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              priceBlock,
              const SizedBox(height: 12),
              button,
            ]);
      }
      return Row(children: [
        Expanded(child: priceBlock),
        const SizedBox(width: 16),
        SizedBox(width: constraints.maxWidth * 0.6, child: button),
      ]);
    });
  }
}
