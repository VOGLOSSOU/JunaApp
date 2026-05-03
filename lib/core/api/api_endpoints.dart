class ApiEndpoints {
  // ── Base ──────────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://juna-app.up.railway.app/api/v1';
  static const String baseUrlDev = 'http://localhost:5000/api/v1';

  // ── Géographie ────────────────────────────────────────────────────────────
  static const String countries = '/countries';
  static String citiesByCountry(String code) => '/countries/$code/cities';
  static String landmarksByCity(String cityId) => '/cities/$cityId/landmarks';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String userProfile = '/users/me';
  static const String updateUserLocation = '/users/me/location';
  static const String updateUserPreferences = '/users/me/preferences';
  static const String providerRegister = '/providers/register';
  static const String providerMe = '/auth/provider/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';
  static const String sendVerificationCode = '/auth/send-verification-code';
  static const String verifyCode = '/auth/verify-code';
  static const String forgotPassword = '/auth/forgot-password';

  // ── Abonnements ───────────────────────────────────────────────────────────
  static const String subscriptions = '/subscriptions';
  static String subscriptionById(String id) => '/subscriptions/$id';

  // ── Commandes ─────────────────────────────────────────────────────────────
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static String orderById(String id) => '/orders/$id';
  static String activateOrder(String id) => '/orders/$id/activate';

  // ── Abonnements actifs ────────────────────────────────────────────────────
  static const String activeSubscriptions = '/active-subscriptions/me';
  static const String checkActiveSubscription = '/active-subscriptions/check';

  // ── Avis ──────────────────────────────────────────────────────────────────
  static const String reviews = '/reviews';
  static String reviewsBySubscription(String id) => '/reviews/subscription/$id';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String deleteNotification(String id) => '/notifications/$id';

  // ── Home feed ─────────────────────────────────────────────────────────────
  static const String homeFeed = '/home';

  // ── Paiements ─────────────────────────────────────────────────────────────
  static const String initiatePayment = '/payments/initiate';
  static String paymentStatus(String id) => '/payments/$id/status';

  // ── Upload ────────────────────────────────────────────────────────────────
  // POST /upload/:folder  — champ multipart = "image"
  static const String uploadAvatars      = '/upload/avatars';
  static const String uploadProviders    = '/upload/providers';
  static const String uploadMeals        = '/upload/meals';
  static const String uploadSubscriptions= '/upload/subscriptions';
  static const String uploadDocuments    = '/upload/documents';
}
