import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';

final _mockNotifications = [
  NotificationEntity(
    id: 'n1',
    type: NotificationType.order,
    title: 'Commande confirmée',
    body: 'Votre commande #JUN-00102 chez Chez Mariam a été confirmée. Elle sera prête à 12h30.',
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    isRead: false,
  ),
  NotificationEntity(
    id: 'n2',
    type: NotificationType.delivery,
    title: 'Livraison en cours',
    body: 'Votre repas est en route ! Le livreur arrivera dans environ 15 minutes.',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    isRead: false,
  ),
  NotificationEntity(
    id: 'n3',
    type: NotificationType.promo,
    title: 'Offre spéciale — 20% de réduction',
    body: 'Profitez de 20% de réduction sur tous les abonnements semaine de travail ce weekend. Code : JUNA20',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: false,
  ),
  NotificationEntity(
    id: 'n4',
    type: NotificationType.review,
    title: 'Laissez un avis',
    body: 'Comment s\'est passé votre repas chez Green Bowl ? Votre avis aide la communauté.',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
  ),
  NotificationEntity(
    id: 'n5',
    type: NotificationType.order,
    title: 'Commande livrée',
    body: 'Votre commande #JUN-00098 a bien été livrée. Bon appétit !',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
  NotificationEntity(
    id: 'n6',
    type: NotificationType.system,
    title: 'Bienvenue sur Juna',
    body: 'Votre compte est prêt. Explorez les abonnements disponibles près de chez vous et commandez votre premier repas.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
  ),
  NotificationEntity(
    id: 'n7',
    type: NotificationType.promo,
    title: 'Nouveau prestataire disponible',
    body: 'Mama Asia vient de rejoindre Juna à Cotonou. Découvrez leurs formules woks et currys asiatiques.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),
  NotificationEntity(
    id: 'n8',
    type: NotificationType.order,
    title: 'Rappel de commande',
    body: 'N\'oubliez pas votre abonnement chez Le Traiteur du Golfe. Votre prochain repas est demain à midi.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),
];

class NotificationsController extends StateNotifier<List<NotificationEntity>> {
  NotificationsController()
      : super([..._mockNotifications]..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt)));

  void markAsRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}

final notificationsControllerProvider =
    StateNotifierProvider<NotificationsController, List<NotificationEntity>>(
  (_) => NotificationsController(),
);

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsControllerProvider);
  return notifs.where((n) => !n.isRead).length;
});
