import '../../features/subscriptions/domain/entities/subscription_entity.dart';
import '../../features/subscriptions/domain/entities/provider_entity.dart';
import '../../features/subscriptions/domain/entities/meal_entity.dart';
import '../../features/orders/domain/entities/order_entity.dart';
import 'enums.dart';

class MockReview {
  final String id;
  final String providerId;
  final String authorName;
  final double rating;
  final String comment;
  final String date;

  const MockReview({
    required this.id,
    required this.providerId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class MockData {
  MockData._();

  // ── PROVIDERS ──────────────────────────────────────────────────────────────

  static final List<ProviderEntity> providers = [
    ProviderEntity(
      id: 'p1',
      name: 'Chez Mariam',
      description:
          'Cuisine africaine traditionnelle, faite maison avec des produits frais du marché.',
      avatarUrl:
          'https://images.unsplash.com/photo-1583394293214-0b3b8e2e4a4f?w=200',
      logo:
          'https://images.unsplash.com/photo-1583394293214-0b3b8e2e4a4f?w=200',
      rating: 4.8,
      reviewCount: 120,
      isVerified: true,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: 'Rue des Cheminots, Cotonou',
      city: ProviderCity(id: 'c1', name: 'Cotonou'),
    ),
    ProviderEntity(
      id: 'p2',
      name: 'Le Traiteur du Golfe',
      description:
          'Spécialiste des repas d\'entreprise et des formules semaine.',
      avatarUrl:
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=200',
      logo:
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=200',
      rating: 4.6,
      reviewCount: 89,
      isVerified: true,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: 'Boulevard Saint-Michel, Cotonou',
      city: ProviderCity(id: 'c1', name: 'Cotonou'),
    ),
    ProviderEntity(
      id: 'p3',
      name: 'Saveurs d\'Abomey',
      description:
          'Recettes traditionnelles du Bénin, transmises de génération en génération.',
      avatarUrl:
          'https://images.unsplash.com/photo-1543353071-873f17a7a088?w=200',
      logo: 'https://images.unsplash.com/photo-1543353071-873f17a7a088?w=200',
      rating: 4.5,
      reviewCount: 67,
      isVerified: false,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: 'Marché Godomey',
      city: ProviderCity(id: 'c1', name: 'Cotonou'),
    ),
    ProviderEntity(
      id: 'p4',
      name: 'Green Bowl',
      description:
          'Cuisine healthy, végétarienne et vegan. Salades, bowls et jus frais.',
      avatarUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      logo:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=200',
      rating: 4.7,
      reviewCount: 54,
      isVerified: true,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: 'Carrefour Godomey',
      city: ProviderCity(id: 'c1', name: 'Cotonou'),
    ),
    ProviderEntity(
      id: 'p5',
      name: 'Mama Asia',
      description: 'Woks, nouilles et currys asiatiques. Livraison rapide.',
      avatarUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
      logo: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=200',
      rating: 4.4,
      reviewCount: 43,
      isVerified: false,
      acceptsDelivery: true,
      acceptsPickup: true,
      businessAddress: 'Rue du Révérend Père Aupiais',
      city: ProviderCity(id: 'c1', name: 'Cotonou'),
    ),
  ];

  // ── MEALS ──────────────────────────────────────────────────────────────────

  static final List<MealEntity> meals = [
    MealEntity(
        id: 'm1',
        name: 'Riz sauce graine',
        description: 'Riz blanc avec sauce graine maison',
        imageUrl:
            'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400'),
    MealEntity(
        id: 'm2',
        name: 'Alloco poisson',
        description: 'Bananes plantain frites avec poisson grillé',
        imageUrl:
            'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400'),
    MealEntity(
        id: 'm3',
        name: 'Pâte noire',
        description: 'Pâte de maïs avec sauce légumes',
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400'),
    MealEntity(
        id: 'm4',
        name: 'Salade Bowl',
        description: 'Quinoa, avocat, tomates cerises, vinaigrette citron',
        imageUrl:
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400'),
    MealEntity(
        id: 'm5',
        name: 'Poulet yassa',
        description: 'Poulet mariné aux oignons et citron',
        imageUrl:
            'https://images.unsplash.com/photo-1598103442097-8b74394b95c2?w=400'),
    MealEntity(
        id: 'm6',
        name: 'Thiéboudienne',
        description: 'Riz au poisson sénégalais, légumes',
        imageUrl:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400'),
  ];

  // ── SUBSCRIPTIONS ──────────────────────────────────────────────────────────

  static final List<SubscriptionEntity> subscriptions = [
    SubscriptionEntity(
      id: 's1',
      title: 'Abonnement Repas Africain',
      description:
          'Découvrez chaque jour une spécialité africaine préparée avec des ingrédients frais du marché de Cotonou. Riz, pâtes, sauces traditionnelles — vous ne mangerez plus jamais pareil.',
      imageUrl:
          'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=800',
      provider: providers[0],
      price: 25000,
      type: SubscriptionType.lunch,
      duration: SubscriptionDuration.workWeek,
      categories: [SubscriptionCategory.african, SubscriptionCategory.halal],
      rating: 4.8,
      reviewCount: 120,
      meals: [meals[0], meals[1], meals[2], meals[4]],
      deliveryZones: ['Akpakpa', 'Quartier Zongo', 'Cadjehoun', 'Haie Vive'],
      pickupPoints: ['Rue des Cheminots, Cotonou'],
      isAvailable: true,
    ),
    SubscriptionEntity(
      id: 's2',
      title: 'Formule Midi Semaine',
      description:
          'Repas de midi équilibré, livré directement sur votre lieu de travail. Variété garantie chaque jour.',
      imageUrl:
          'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
      provider: providers[1],
      price: 30000,
      type: SubscriptionType.lunch,
      duration: SubscriptionDuration.workWeek,
      categories: [SubscriptionCategory.african],
      rating: 4.6,
      reviewCount: 89,
      meals: [meals[4], meals[5], meals[0]],
      deliveryZones: ['Plateau', 'Ganhi', 'Jonquet', 'Patte d\'Oie'],
      pickupPoints: ['Boulevard Saint-Michel, Cotonou'],
      isAvailable: true,
    ),
    SubscriptionEntity(
      id: 's3',
      title: 'Box Santé Hebdo',
      description:
          'Une semaine de repas healthy et équilibrés. Salades, bowls de légumes, protéines maigres. Idéal pour garder la forme.',
      imageUrl:
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
      provider: providers[3],
      price: 35000,
      type: SubscriptionType.lunchDinner,
      duration: SubscriptionDuration.week,
      categories: [
        SubscriptionCategory.vegetarian,
        SubscriptionCategory.vegan,
        SubscriptionCategory.healthy
      ],
      rating: 4.7,
      reviewCount: 54,
      meals: [meals[3]],
      deliveryZones: ['Haie Vive', 'Cadjehoun', 'Akpakpa'],
      pickupPoints: ['Carrefour Godomey'],
      isAvailable: true,
    ),
    SubscriptionEntity(
      id: 's4',
      title: 'Petit-Déjeuner Traditionnel',
      description:
          'Commencez bien la journée avec un petit-déjeuner africain complet : akassa, bouillie, galettes maison, thé ou café.',
      imageUrl:
          'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=800',
      provider: providers[2],
      price: 15000,
      type: SubscriptionType.breakfast,
      duration: SubscriptionDuration.workWeek,
      categories: [SubscriptionCategory.african],
      rating: 4.5,
      reviewCount: 67,
      meals: [],
      deliveryZones: ['Abomey-Calavi', 'Godomey'],
      pickupPoints: ['Marché Godomey'],
      isAvailable: true,
    ),
    SubscriptionEntity(
      id: 's5',
      title: 'Asian Wok Box',
      description:
          'Woks, nouilles sautées, currys thaïs et spring rolls. Le voyage en Asie depuis Cotonou.',
      imageUrl:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      provider: providers[4],
      price: 28000,
      type: SubscriptionType.lunch,
      duration: SubscriptionDuration.workWeek,
      categories: [SubscriptionCategory.asian],
      rating: 4.4,
      reviewCount: 43,
      meals: [],
      deliveryZones: ['Plateau', 'Haie Vive'],
      pickupPoints: ['Rue du Révérend Père Aupiais'],
      isAvailable: true,
    ),
    SubscriptionEntity(
      id: 's6',
      title: 'Journée Complète Africaine',
      description:
          'Petit-déjeuner, déjeuner et dîner africains. Zéro stress pour la journée entière.',
      imageUrl:
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      provider: providers[0],
      price: 45000,
      type: SubscriptionType.fullDay,
      duration: SubscriptionDuration.workWeek,
      categories: [SubscriptionCategory.african, SubscriptionCategory.halal],
      rating: 4.9,
      reviewCount: 38,
      meals: [meals[0], meals[1], meals[2], meals[4], meals[5]],
      deliveryZones: ['Akpakpa', 'Quartier Zongo', 'Cadjehoun'],
      pickupPoints: ['Rue des Cheminots, Cotonou'],
      isAvailable: true,
    ),
  ];

  // ── ORDERS ─────────────────────────────────────────────────────────────────

  static final List<OrderEntity> orders = [
    OrderEntity(
      id: 'o1',
      orderNumber: 'JUN-00123',
      status: OrderStatus.confirmed,
      deliveryMethod: DeliveryMethod.delivery,
      deliveryAddress: 'Quartier Zongo',
      amount: 26000,
      qrCode: 'o1',
      subscriptionName: 'Formule Semaine Mariam',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderEntity(
      id: 'o2',
      orderNumber: 'JUN-00098',
      status: OrderStatus.active,
      deliveryMethod: DeliveryMethod.pickup,
      pickupLocation: 'Carrefour Godomey',
      amount: 35000,
      qrCode: 'o2',
      subscriptionName: 'Box Équilibre Mensuelle',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    OrderEntity(
      id: 'o3',
      orderNumber: 'JUN-00075',
      status: OrderStatus.cancelled,
      deliveryMethod: DeliveryMethod.delivery,
      deliveryAddress: 'Plateau',
      amount: 31500,
      qrCode: 'o3',
      subscriptionName: 'Plats Familiaux Hebdo',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  // ── REVIEWS ────────────────────────────────────────────────────────────────

  static const List<MockReview> reviews = [
    MockReview(
        id: 'r1',
        providerId: 'p1',
        authorName: 'Adjoua Koné',
        rating: 5.0,
        comment:
            'Excellente cuisine, les repas arrivent toujours chauds et bien présentés. Je recommande vivement la formule semaine !',
        date: 'Il y a 2 jours'),
    MockReview(
        id: 'r2',
        providerId: 'p1',
        authorName: 'Koffi Mensah',
        rating: 5.0,
        comment:
            'Mariam fait vraiment de la bonne cuisine africaine. Le riz sauce graine est un délice, exactement comme à la maison.',
        date: 'Il y a 1 semaine'),
    MockReview(
        id: 'r3',
        providerId: 'p1',
        authorName: 'Fatou Diallo',
        rating: 4.0,
        comment:
            'Très bonne qualité, livraison ponctuelle. Parfois les portions pourraient être un peu plus généreuses.',
        date: 'Il y a 2 semaines'),
    MockReview(
        id: 'r4',
        providerId: 'p1',
        authorName: 'Serge Ahouansou',
        rating: 5.0,
        comment:
            'Je suis abonné depuis 3 mois et je ne suis jamais déçu. Le rapport qualité-prix est imbattable.',
        date: 'Il y a 1 mois'),
    MockReview(
        id: 'r5',
        providerId: 'p2',
        authorName: 'Marie-Claire Hounkpè',
        rating: 5.0,
        comment:
            'Le Traiteur du Golfe assure pour les repas d\'entreprise. Nos équipes adorent les formules semaine.',
        date: 'Il y a 3 jours'),
    MockReview(
        id: 'r6',
        providerId: 'p2',
        authorName: 'Rodrigue Dossou',
        rating: 4.0,
        comment:
            'Très professionnel, livraison à l\'heure. Les repas sont variés et équilibrés.',
        date: 'Il y a 5 jours'),
    MockReview(
        id: 'r7',
        providerId: 'p2',
        authorName: 'Bénédicte Vodounon',
        rating: 5.0,
        comment:
            'Service impeccable. J\'apprécie particulièrement la diversité des menus proposés chaque semaine.',
        date: 'Il y a 3 semaines'),
    MockReview(
        id: 'r8',
        providerId: 'p4',
        authorName: 'Ines Agboton',
        rating: 5.0,
        comment:
            'Green Bowl c\'est ma pause déjeuner idéale. Frais, sain et délicieux. Le bowl avocat-quinoa est incroyable.',
        date: 'Il y a 1 jour'),
    MockReview(
        id: 'r9',
        providerId: 'p4',
        authorName: 'Patrick Zinsou',
        rating: 4.0,
        comment:
            'Excellente cuisine végétarienne, on ne se lasse pas. Un peu cher mais la qualité est au rendez-vous.',
        date: 'Il y a 1 semaine'),
    MockReview(
        id: 'r10',
        providerId: 'p4',
        authorName: 'Clarisse Akpovi',
        rating: 5.0,
        comment:
            'Enfin un prestataire qui fait une vraie cuisine healthy à Cotonou ! Les jus frais sont un bonus appréciable.',
        date: 'Il y a 2 semaines'),
  ];
}
