import '../../../../core/utils/enums.dart';
import '../../../subscriptions/domain/entities/meal_entity.dart';

enum ProposalStatus { pending, approved, rejected }

extension ProposalStatusX on ProposalStatus {
  String get label {
    switch (this) {
      case ProposalStatus.pending:
        return 'En attente';
      case ProposalStatus.approved:
        return 'Approuvée';
      case ProposalStatus.rejected:
        return 'Rejetée';
    }
  }

  String get description {
    switch (this) {
      case ProposalStatus.pending:
        return 'En attente de réponse du prestataire';
      case ProposalStatus.approved:
        return 'Acceptée — disponible dans le catalogue';
      case ProposalStatus.rejected:
        return 'Non retenue';
    }
  }
}

class ProposalMealEntity {
  final String mealId;
  final String? mealPricingLabel;
  final int quantity;
  final String mealName;
  final String mealImageUrl;
  final MealPriceType mealPriceType;
  final int mealPrice;

  const ProposalMealEntity({
    required this.mealId,
    this.mealPricingLabel,
    required this.quantity,
    required this.mealName,
    required this.mealImageUrl,
    required this.mealPriceType,
    required this.mealPrice,
  });
}

class SubscriptionProposalEntity {
  final String id;
  final SubscriptionType type;
  final SubscriptionCategory category;
  final SubscriptionDuration duration;
  final String message;
  final ProposalStatus status;
  final String? rejectionReason;
  final String? resultingSubscriptionId;
  final String providerId;
  final String providerName;
  final String providerLogo;
  final List<ProposalMealEntity> meals;
  final DateTime createdAt;

  const SubscriptionProposalEntity({
    required this.id,
    required this.type,
    required this.category,
    required this.duration,
    required this.message,
    required this.status,
    this.rejectionReason,
    this.resultingSubscriptionId,
    required this.providerId,
    required this.providerName,
    required this.providerLogo,
    required this.meals,
    required this.createdAt,
  });
}
