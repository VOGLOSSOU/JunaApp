import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsControllerProvider);
    final unread = ref.watch(unreadCountProvider);

    // Grouper par date
    final today = <NotificationEntity>[];
    final yesterday = <NotificationEntity>[];
    final older = <NotificationEntity>[];

    final now = DateTime.now();
    for (final n in notifications) {
      final diff = now.difference(n.createdAt);
      if (diff.inHours < 24) {
        today.add(n);
      } else if (diff.inHours < 48) {
        yesterday.add(n);
      } else {
        older.add(n);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text('Notifications', style: AppTypography.titleLarge),
            if (unread > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$unread',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsControllerProvider.notifier).markAllAsRead(),
              child: Text(
                'Tout lire',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmpty()
          : ListView(
              children: [
                if (today.isNotEmpty) ...[
                  _GroupHeader(label: "Aujourd'hui"),
                  ...today.map((n) => _NotifTile(notif: n)),
                ],
                if (yesterday.isNotEmpty) ...[
                  _GroupHeader(label: 'Hier'),
                  ...yesterday.map((n) => _NotifTile(notif: n)),
                ],
                if (older.isNotEmpty) ...[
                  _GroupHeader(label: 'Plus ancien'),
                  ...older.map((n) => _NotifTile(notif: n)),
                ],
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 36,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Aucune notification', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Vous serez notifié de vos commandes\net des offres disponibles.',
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
      child: Text(
        label,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final NotificationEntity notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref
          .read(notificationsControllerProvider.notifier)
          .markAsRead(notif.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: notif.isRead ? AppColors.white : AppColors.primarySurface,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône type
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconBg(notif.type),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(notif.type),
                color: _iconColor(notif.type),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: notif.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _timeAgo(notif.createdAt),
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notif.body,
                    style: AppTypography.bodySmall.copyWith(
                      color: notif.isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Point non lu
            if (!notif.isRead) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.order:    return Icons.receipt_long_outlined;
      case NotificationType.delivery: return Icons.delivery_dining_outlined;
      case NotificationType.promo:    return Icons.local_offer_outlined;
      case NotificationType.review:   return Icons.star_outline_rounded;
      case NotificationType.system:   return Icons.info_outline_rounded;
    }
  }

  Color _iconBg(NotificationType type) {
    switch (type) {
      case NotificationType.order:    return AppColors.primarySurface;
      case NotificationType.delivery: return const Color(0xFFE8F5E9);
      case NotificationType.promo:    return const Color(0xFFFFF3E0);
      case NotificationType.review:   return const Color(0xFFFFF9C4);
      case NotificationType.system:   return AppColors.surfaceGrey;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:    return AppColors.primary;
      case NotificationType.delivery: return const Color(0xFF2E7D32);
      case NotificationType.promo:    return AppColors.accent;
      case NotificationType.review:   return const Color(0xFFF9A825);
      case NotificationType.system:   return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    return '${diff.inDays}j';
  }
}
