import '../../subscriptions/domain/entities/provider_entity.dart';

/// Façon dont l'utilisateur récupère sa commande.
enum FulfillmentMode { delivery, pickup }

/// Modes proposés par le prestataire, dans l'ordre d'affichage.
///
/// Vient de `acceptsDelivery` / `acceptsPickup` dans `data.provider` de
/// `GET /subscriptions/:id`. Le backend refuse aussi un mode non proposé.
List<FulfillmentMode> availableFulfillmentModes(ProviderEntity provider) => [
      if (provider.acceptsDelivery) FulfillmentMode.delivery,
      if (provider.acceptsPickup) FulfillmentMode.pickup,
    ];
