import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notifications_controller.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    // Rafraîchit les notifs à chaque ouverture de l'écran (guide Part 9)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(notificationsControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(notificationsControllerProvider.notifier).load();
  }

  void _onTap(NotificationEntity notif) {
    if (!notif.isRead) {
      ref.read(notificationsControllerProvider.notifier).markAsRead(notif.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final unread = state.unreadCount;

    // Grouper par date
    final today = <NotificationEntity>[];
    final yesterday = <NotificationEntity>[];
    final older = <NotificationEntity>[];

    final now = DateTime.now();
    for (final n in state.notifications) {
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
          onPressed: () => context.pop(),
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
              onPressed: () => ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead(),
              child: Text(
                'Tout lire',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : state.notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: ListView(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (today.isNotEmpty) ...[
                        _GroupHeader(label: "Aujourd'hui"),
                        ...today.map((n) => _NotifTile(
                              notif: n,
                              onTap: () => _onTap(n),
                              onDelete: () => ref
                                  .read(notificationsControllerProvider
                                      .notifier)
                                  .delete(n.id),
                            )),
                      ],
                      if (yesterday.isNotEmpty) ...[
                        _GroupHeader(label: 'Hier'),
                        ...yesterday.map((n) => _NotifTile(
                              notif: n,
                              onTap: () => _onTap(n),
                              onDelete: () => ref
                                  .read(notificationsControllerProvider
                                      .notifier)
                                  .delete(n.id),
                            )),
                      ],
                      if (older.isNotEmpty) ...[
                        _GroupHeader(label: 'Plus ancien'),
                        ...older.map((n) => _NotifTile(
                              notif: n,
                              onTap: () => _onTap(n),
                              onDelete: () => ref
                                  .read(notificationsControllerProvider
                                      .notifier)
                                  .delete(n.id),
                            )),
                      ],
                      if (state.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ),
                      if (!state.hasMore && state.notifications.length >= 30)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(
                              'Toutes les notifications sont affichées',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textLight),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxxl),
                    ],
                  ),
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
            decoration: const BoxDecoration(
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
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
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

class _NotifTile extends StatelessWidget {
  final NotificationEntity notif;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
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
                      notif.message,
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
      ),
    );
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmation: return Icons.receipt_long_outlined;
      case NotificationType.proposalValidated: return Icons.check_circle_outline_rounded;
      case NotificationType.proposalRejected:  return Icons.cancel_outlined;
      case NotificationType.system:            return Icons.info_outline_rounded;
      case NotificationType.unknown:           return Icons.notifications_outlined;
    }
  }

  Color _iconBg(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmation: return AppColors.primarySurface;
      case NotificationType.proposalValidated: return const Color(0xFFE8F5E9);
      case NotificationType.proposalRejected:  return const Color(0xFFFFEBEE);
      case NotificationType.system:            return AppColors.surfaceGrey;
      case NotificationType.unknown:           return AppColors.surfaceGrey;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderConfirmation: return AppColors.primary;
      case NotificationType.proposalValidated: return const Color(0xFF2E7D32);
      case NotificationType.proposalRejected:  return AppColors.error;
      case NotificationType.system:            return AppColors.textSecondary;
      case NotificationType.unknown:           return AppColors.textLight;
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
