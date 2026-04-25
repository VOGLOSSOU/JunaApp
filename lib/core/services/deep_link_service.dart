import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Écoute les liens entrants (juna://) et navigue vers la bonne page.
///
/// Patterns supportés :
///   juna://orders           → page commandes/abonnements actifs
///   juna://orders/:id       → détail commande
///   juna://subscriptions/:id → détail abonnement
///
/// Le format exact du redirect web sera confirmé par l'équipe web.
/// En attendant, tous les patterns raisonnables sont couverts.
class DeepLinkService {
  final GoRouter _router;
  final AppLinks _appLinks = AppLinks();

  DeepLinkService(this._router);

  Future<void> init() async {
    // Lien qui a lancé l'app (app fermée)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) _handle(initialLink);
    } catch (e) {
      debugPrint('[DeepLink] initial link error: $e');
    }

    // Liens reçus pendant que l'app tourne
    _appLinks.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('[DeepLink] stream error: $e'),
    );
  }

  void _handle(Uri uri) {
    debugPrint('[DeepLink] incoming: $uri');

    if (uri.scheme != 'juna') return;

    final path = uri.path; // ex: /orders, /orders/abc123
    final host = uri.host; // ex: orders (custom scheme: juna://orders/abc123)

    // juna://orders  ou  juna:///orders
    final segment = host.isNotEmpty ? host : (path.isNotEmpty ? path.replaceFirst('/', '') : '');
    final parts = segment.split('/'); // ['orders'] ou ['orders', 'abc123']

    switch (parts.first) {
      case 'orders':
        if (parts.length > 1 && parts[1].isNotEmpty) {
          _router.push('/orders/${parts[1]}');
        } else {
          _router.go('/orders');
        }
        break;

      case 'subscriptions':
        if (parts.length > 1 && parts[1].isNotEmpty) {
          _router.push('/subscriptions/${parts[1]}');
        }
        break;

      default:
        // Format inconnu → page commandes par défaut
        _router.go('/orders');
    }
  }
}
