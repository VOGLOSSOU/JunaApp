import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explorer/presentation/screens/explorer_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/account_settings_screen.dart';
import '../../features/profile/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/notifications_settings_screen.dart';
import '../../features/profile/presentation/screens/advanced_settings_screen.dart';
import '../../features/profile/presentation/screens/become_provider_screen.dart';
import '../../features/profile/presentation/screens/referral_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/provider_space/presentation/screens/provider_profile_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/mobile_money_screen.dart';
import '../../features/checkout/presentation/screens/payment_processing_screen.dart';
import '../shell/main_shell.dart';

// Route names
class AppRoutes {
  static const splash          = '/';
  static const onboarding      = '/onboarding';
  static const login           = '/login';
  static const register        = '/register';
  static const home            = '/home';
  static const explorer        = '/explorer';
  static const subscriptionDetail = '/subscriptions/:id';
  static const orders          = '/orders';
  static const orderDetail     = '/orders/:id';
  static const profile         = '/profile';
  static const accountSettings = '/profile/settings';
  static const favorites       = '/profile/favorites';
  static const notifSettings   = '/profile/notifications';
  static const advancedSettings = '/profile/advanced';
  static const becomeProvider  = '/profile/become-provider';
  static const referral        = '/profile/referral';
  static const support         = '/profile/support';
  static const providerProfile      = '/providers/:id';
  static const notifications        = '/notifications';
  static const checkout             = '/checkout/form/:subscriptionId';
  static const checkoutMobileMoney  = '/checkout/mobile-money';
  static const checkoutProcessing   = '/checkout/processing';
  static const checkoutFailed       = '/checkout/failed';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // Laisse splash et onboarding passer sans redirect
      if (isSplash || isOnboarding) return null;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectTo: redirect);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return RegisterScreen(redirectTo: redirect);
        },
      ),
      // Shell avec bottom navigation
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.explorer,
            builder: (_, __) => const ExplorerScreen(),
          ),
          GoRoute(
            path: AppRoutes.orders,
            builder: (_, __) => const OrdersScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
          // Détail abonnement (dans shell)
          GoRoute(
            path: AppRoutes.subscriptionDetail,
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return SubscriptionDetailScreen(subscriptionId: id);
            },
          ),
          // Détail commande
          GoRoute(
            path: AppRoutes.orderDetail,
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailScreen(orderId: id);
            },
          ),
        ],
      ),
      // Sous-pages profil
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (_, __) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.favorites,
        builder: (_, __) => const FavoritesScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifSettings,
        builder: (_, __) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.advancedSettings,
        builder: (_, __) => const AdvancedSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.becomeProvider,
        builder: (_, __) => const BecomeProviderScreen(),
      ),
      GoRoute(
        path: AppRoutes.referral,
        builder: (_, __) => const ReferralScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, __) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerProfile,
        builder: (_, state) {
          final id = state.pathParameters['id']!;
          return ProviderProfileScreen(providerId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      // ── Checkout ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, state) {
          final id = state.pathParameters['subscriptionId']!;
          return CheckoutScreen(subscriptionId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutMobileMoney,
        builder: (_, state) {
          final extra = state.extra as CheckoutMobileExtra;
          return MobileMoneyScreen(extra: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutProcessing,
        builder: (_, state) {
          final extra = state.extra as PaymentProcessingExtra;
          return PaymentProcessingScreen(extra: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.checkoutFailed,
        builder: (_, state) {
          final extra = state.extra as PaymentFailedExtra;
          return PaymentFailedScreen(extra: extra);
        },
      ),
    ],
  );
});
