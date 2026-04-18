import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class NotificationsSettingsScreen extends ConsumerStatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  ConsumerState<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends ConsumerState<NotificationsSettingsScreen> {
  bool _email = true;
  bool _push = true;
  bool _sms = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final notifs = ref
        .read(authControllerProvider)
        .user
        ?.profile
        .preferences
        .notifications;
    if (notifs != null) {
      _email = notifs['email'] ?? true;
      _push = notifs['push'] ?? true;
      _sms = notifs['sms'] ?? false;
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(authControllerProvider.notifier).updatePreferences({
        'notifications': {'email': _email, 'push': _push, 'sms': _sms},
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggle(String key, bool value) {
    setState(() {
      if (key == 'email') _email = value;
      if (key == 'push') _push = value;
      if (key == 'sms') _sms = value;
    });
    _save();
  }

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
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _SwitchItem(
            title: 'Notifications par email',
            subtitle: 'Commandes, confirmations, rappels',
            value: _email,
            onChanged: (v) => _toggle('email', v),
          ),
          _SwitchItem(
            title: 'Notifications push',
            subtitle: 'Alertes en temps réel sur votre téléphone',
            value: _push,
            onChanged: (v) => _toggle('push', v),
          ),
          _SwitchItem(
            title: 'Notifications SMS',
            subtitle: 'Messages texte pour les événements importants',
            value: _sms,
            onChanged: (v) => _toggle('sms', v),
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
                Text(title,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
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
