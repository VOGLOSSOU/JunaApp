enum SubscriptionType {
  breakfast,
  lunch,
  dinner,
  snack,
  breakfastLunch,
  lunchDinner,
  fullDay,
  custom,
}

enum SubscriptionDuration {
  day,
  threeDays,
  week,
  twoWeeks,
  month,
  workWeek,
  workWeek2,
  workMonth,
  weekend,
}

enum SubscriptionCategory {
  african,
  vegetarian,
  halal,
  asian,
  vegan,
  european,
  fastFood,
  healthy,
}

enum DeliveryMethod { delivery, pickup }

enum PaymentMethod { wave, mtnMoney, moovMoney, orangeMoney, card, cash }

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivering,
  delivered,
  completed,
  cancelled,
}

extension SubscriptionTypeLabel on SubscriptionType {
  String get label {
    switch (this) {
      case SubscriptionType.breakfast:      return 'Petit-déjeuner';
      case SubscriptionType.lunch:          return 'Déjeuner';
      case SubscriptionType.dinner:         return 'Dîner';
      case SubscriptionType.snack:          return 'Snack';
      case SubscriptionType.breakfastLunch: return 'Petit-déj + Déjeuner';
      case SubscriptionType.lunchDinner:    return 'Déjeuner + Dîner';
      case SubscriptionType.fullDay:        return 'Journée complète';
      case SubscriptionType.custom:         return 'Personnalisé';
    }
  }

  String get emoji {
    switch (this) {
      case SubscriptionType.breakfast:      return '🌅';
      case SubscriptionType.lunch:          return '☀️';
      case SubscriptionType.dinner:         return '🌙';
      case SubscriptionType.snack:          return '🍎';
      case SubscriptionType.breakfastLunch: return '🌤️';
      case SubscriptionType.lunchDinner:    return '🍽️';
      case SubscriptionType.fullDay:        return '🔄';
      case SubscriptionType.custom:         return '✨';
    }
  }
}

extension SubscriptionDurationLabel on SubscriptionDuration {
  String get label {
    switch (this) {
      case SubscriptionDuration.day:       return '1 jour';
      case SubscriptionDuration.threeDays: return '3 jours';
      case SubscriptionDuration.week:      return '1 semaine';
      case SubscriptionDuration.twoWeeks:  return '2 semaines';
      case SubscriptionDuration.month:     return '1 mois';
      case SubscriptionDuration.workWeek:  return 'Semaine de travail';
      case SubscriptionDuration.workWeek2: return '2 semaines de travail';
      case SubscriptionDuration.workMonth: return 'Mois de travail';
      case SubscriptionDuration.weekend:   return 'Week-end';
    }
  }
}

extension SubscriptionCategoryLabel on SubscriptionCategory {
  String get label {
    switch (this) {
      case SubscriptionCategory.african:    return 'Africain';
      case SubscriptionCategory.vegetarian: return 'Végétarien';
      case SubscriptionCategory.halal:      return 'Halal';
      case SubscriptionCategory.asian:      return 'Asiatique';
      case SubscriptionCategory.vegan:      return 'Vegan';
      case SubscriptionCategory.european:   return 'Européen';
      case SubscriptionCategory.fastFood:   return 'Fast-food';
      case SubscriptionCategory.healthy:    return 'Healthy';
    }
  }

  String get emoji {
    switch (this) {
      case SubscriptionCategory.african:    return '🌍';
      case SubscriptionCategory.vegetarian: return '🥗';
      case SubscriptionCategory.halal:      return '☪️';
      case SubscriptionCategory.asian:      return '🌏';
      case SubscriptionCategory.vegan:      return '🌿';
      case SubscriptionCategory.european:   return '🇪🇺';
      case SubscriptionCategory.fastFood:   return '🍔';
      case SubscriptionCategory.healthy:    return '💪';
    }
  }
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:    return 'En attente';
      case OrderStatus.confirmed:  return 'Confirmée';
      case OrderStatus.preparing:  return 'En préparation';
      case OrderStatus.ready:      return 'Prête';
      case OrderStatus.delivering: return 'En livraison';
      case OrderStatus.delivered:  return 'Livrée';
      case OrderStatus.completed:  return 'Complétée';
      case OrderStatus.cancelled:  return 'Annulée';
    }
  }
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.wave:        return 'Wave';
      case PaymentMethod.mtnMoney:    return 'MTN Mobile Money';
      case PaymentMethod.moovMoney:   return 'Moov Money';
      case PaymentMethod.orangeMoney: return 'Orange Money';
      case PaymentMethod.card:        return 'Carte bancaire';
      case PaymentMethod.cash:        return 'Espèces (à la livraison)';
    }
  }

  String get emoji {
    switch (this) {
      case PaymentMethod.wave:        return '📱';
      case PaymentMethod.mtnMoney:    return '📱';
      case PaymentMethod.moovMoney:   return '📱';
      case PaymentMethod.orangeMoney: return '📱';
      case PaymentMethod.card:        return '💳';
      case PaymentMethod.cash:        return '💵';
    }
  }
}
