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
  active,
  completed,
  cancelled,
}

extension SubscriptionTypeApi on SubscriptionType {
  String get apiValue {
    switch (this) {
      case SubscriptionType.breakfast:      return 'BREAKFAST';
      case SubscriptionType.lunch:          return 'LUNCH';
      case SubscriptionType.dinner:         return 'DINNER';
      case SubscriptionType.snack:          return 'SNACK';
      case SubscriptionType.breakfastLunch: return 'BREAKFAST_LUNCH';
      case SubscriptionType.lunchDinner:    return 'LUNCH_DINNER';
      case SubscriptionType.fullDay:        return 'FULL_DAY';
      case SubscriptionType.custom:         return 'CUSTOM';
    }
  }
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

extension SubscriptionTypeExplanation on SubscriptionType {
  String get explanation {
    switch (this) {
      case SubscriptionType.breakfast:
        return 'Vous recevez un petit-déjeuner chaque matin — pain, œufs, bouillies, jus ou plats locaux — livré ou mis à disposition à l\'heure du matin.';
      case SubscriptionType.lunch:
        return 'Un repas complet préparé par le prestataire vous attend chaque jour à l\'heure du déjeuner. Fini de courir chercher à manger à la pause.';
      case SubscriptionType.dinner:
        return 'Votre repas du soir est pris en charge. Le prestataire prépare votre dîner et vous le livre ou le met à disposition chaque soir.';
      case SubscriptionType.snack:
        return 'Une collation quotidienne — encas, petite faim de l\'après-midi, jus ou goûter — pour tenir entre deux repas sans se soucier de quoi manger.';
      case SubscriptionType.breakfastLunch:
        return 'Deux repas couverts par jour : un petit-déjeuner le matin et un déjeuner complet à la pause de midi. Votre matinée et votre après-midi sont assurées.';
      case SubscriptionType.lunchDinner:
        return 'Deux repas par jour : le midi et le soir. Plus besoin de penser à cuisiner après le travail ni de trouver quelque chose à manger le midi.';
      case SubscriptionType.fullDay:
        return 'La formule la plus complète : petit-déjeuner, déjeuner et dîner inclus. Trois repas par jour, sans vous soucier de quoi manger du matin au soir.';
      case SubscriptionType.custom:
        return 'Formule sur mesure composée par le prestataire. Les détails exacts des repas inclus sont précisés dans la description de l\'abonnement.';
    }
  }
}

extension SubscriptionDurationApi on SubscriptionDuration {
  String get apiValue {
    switch (this) {
      case SubscriptionDuration.day:       return 'DAY';
      case SubscriptionDuration.threeDays: return 'THREE_DAYS';
      case SubscriptionDuration.week:      return 'WEEK';
      case SubscriptionDuration.twoWeeks:  return 'TWO_WEEKS';
      case SubscriptionDuration.month:     return 'MONTH';
      case SubscriptionDuration.workWeek:  return 'WORK_WEEK';
      case SubscriptionDuration.workWeek2: return 'WORK_WEEK_2';
      case SubscriptionDuration.workMonth: return 'WORK_MONTH';
      case SubscriptionDuration.weekend:   return 'WEEKEND';
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

extension SubscriptionDurationDetail on SubscriptionDuration {
  String get sublabel {
    switch (this) {
      case SubscriptionDuration.day:       return '1 jour · Sans engagement';
      case SubscriptionDuration.threeDays: return '3 jours consécutifs';
      case SubscriptionDuration.week:      return '7 jours · Week-end inclus';
      case SubscriptionDuration.twoWeeks:  return '14 jours · Week-end inclus';
      case SubscriptionDuration.month:     return '~30 jours · Week-end inclus';
      case SubscriptionDuration.workWeek:  return '5 jours · Lun–Ven uniquement';
      case SubscriptionDuration.workWeek2: return '10 jours ouvrés · Lun–Ven';
      case SubscriptionDuration.workMonth: return '20 jours ouvrés · Sans week-end';
      case SubscriptionDuration.weekend:   return '2 jours · Sam–Dim uniquement';
    }
  }

  String get explanation {
    switch (this) {
      case SubscriptionDuration.day:
        return 'Un abonnement d\'une seule journée — idéal pour tester un prestataire ou pour un besoin ponctuel sans engagement.';
      case SubscriptionDuration.threeDays:
        return 'L\'abonnement court sur 3 jours consécutifs à partir de la date de début. Pratique pour un début de semaine ou un premier essai prolongé.';
      case SubscriptionDuration.week:
        return '7 jours complets, week-end inclus. Vous êtes couvert du lundi au dimanche sans interruption — le prestataire livre chaque jour.';
      case SubscriptionDuration.twoWeeks:
        return 'Deux semaines complètes (14 jours), week-end inclus. Une bonne option pour tester un prestataire sur une durée significative avant de s\'engager sur un mois.';
      case SubscriptionDuration.month:
        return 'Un mois complet (~30 jours), week-end inclus. L\'engagement le plus long — vous bénéficiez de vos repas chaque jour sans exception.';
      case SubscriptionDuration.workWeek:
        return 'Du lundi au vendredi uniquement — le week-end n\'est pas inclus. Parfait pour être bien nourri pendant la semaine active sans payer les jours de repos.';
      case SubscriptionDuration.workWeek2:
        return 'Deux semaines de travail (10 jours ouvrés, sans les week-ends). Vous recevez vos repas 5 jours sur 7 pendant deux semaines calendaires.';
      case SubscriptionDuration.workMonth:
        return '20 jours ouvrés — un mois de travail complet, sans les week-ends. Idéal pour les actifs qui ne veulent pas payer les jours où ils ne travaillent pas.';
      case SubscriptionDuration.weekend:
        return 'Uniquement le samedi et le dimanche. Idéal pour ceux qui cuisinent en semaine et veulent profiter d\'un service traiteur pendant les jours de repos.';
    }
  }
}

extension SubscriptionCategoryExplanation on SubscriptionCategory {
  String get explanation {
    switch (this) {
      case SubscriptionCategory.african:
        return 'Plats inspirés des traditions culinaires africaines — riz, sauces, attiéké, igname, plantain, viandes et poissons préparés selon les recettes locales. Une cuisine authentique et généreuse.';
      case SubscriptionCategory.european:
        return 'Plats d\'inspiration européenne — pâtes, grillades, salades composées, sandwichs élaborés. Un style occidental adapté aux palais habitués aux saveurs d\'Europe.';
      case SubscriptionCategory.asian:
        return 'Spécialités d\'Asie — riz cantonnais, nouilles, plats sautés, soupes asiatiques. Des saveurs umami, épicées ou sucrées-salées selon les spécialités du prestataire.';
      case SubscriptionCategory.vegetarian:
        return 'Tous les plats sont sans viande ni poisson. Légumes, légumineuses, œufs et produits laitiers composent les repas — idéal pour ceux qui ont fait le choix de ne pas consommer de chair animale.';
      case SubscriptionCategory.vegan:
        return 'Aucun produit d\'origine animale — ni viande, ni poisson, ni œufs, ni produits laitiers. Une alimentation 100 % végétale pour ceux qui ont adopté un mode de vie vegan.';
      case SubscriptionCategory.halal:
        return 'Tous les repas sont préparés selon les règles alimentaires halal. Les viandes sont abattues conformément aux prescriptions islamiques et les ingrédients non conformes sont exclus.';
      case SubscriptionCategory.fastFood:
        return 'Burgers, wraps, poulet frit, frites — des portions copieuses et des saveurs directes. Des plats généreux pour manger rapidement et bien.';
      case SubscriptionCategory.healthy:
        return 'Des repas équilibrés, légers et nutritifs, pensés pour prendre soin de votre santé sans sacrifier le goût. Idéal pour manger sainement au quotidien.';
    }
  }
}

extension SubscriptionCategoryApi on SubscriptionCategory {
  String get apiValue {
    switch (this) {
      case SubscriptionCategory.african:    return 'AFRICAN';
      case SubscriptionCategory.vegetarian: return 'VEGETARIAN';
      case SubscriptionCategory.halal:      return 'HALAL';
      case SubscriptionCategory.asian:      return 'ASIAN';
      case SubscriptionCategory.vegan:      return 'VEGAN';
      case SubscriptionCategory.european:   return 'EUROPEAN';
      case SubscriptionCategory.fastFood:   return 'FAST_FOOD';
      case SubscriptionCategory.healthy:    return 'HEALTHY';
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
      case OrderStatus.pending:   return 'En attente';
      case OrderStatus.confirmed: return 'Confirmée';
      case OrderStatus.active:    return 'Actif';
      case OrderStatus.completed: return 'Terminée';
      case OrderStatus.cancelled: return 'Annulée';
    }
  }

  bool get canActivate => this == OrderStatus.confirmed;

  bool get isActive => this == OrderStatus.active;

  bool get isPending => this == OrderStatus.pending;
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
