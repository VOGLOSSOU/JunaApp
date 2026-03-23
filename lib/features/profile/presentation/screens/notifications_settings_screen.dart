import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _orderUpdates   = true;
  bool _promotions     = true;
  bool _reminders      = false;
  bool _newProviders   = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SwitchItem(
            title: 'Mises à jour commandes',
            subtitle: 'Confirmations, statuts, livraisons',
            value: _orderUpdates,
            onChanged: (v) => setState(() => _orderUpdates = v),
          ),
          _SwitchItem(
            title: 'Promotions et offres',
            subtitle: 'Nouveaux abonnements, réductions',
            value: _promotions,
            onChanged: (v) => setState(() => _promotions = v),
          ),
          _SwitchItem(
            title: 'Rappels',
            subtitle: 'Rappels de renouvellement d\'abonnement',
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          _SwitchItem(
            title: 'Nouveaux prestataires',
            subtitle: 'Nouveaux prestataires dans votre zone',
            value: _newProviders,
            onChanged: (v) => setState(() => _newProviders = v),
          ),
        ],
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
