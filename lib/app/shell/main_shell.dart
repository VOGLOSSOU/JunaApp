import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/orders/presentation/controllers/orders_controller.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.explorer)) return 1;
    if (location.startsWith(AppRoutes.orders))   return 2;
    if (location.startsWith(AppRoutes.profile))  return 3;
    return 0; // home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.home);
      case 1: context.go(AppRoutes.explorer);
      case 2: context.go(AppRoutes.orders);
      case 3: context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final hasActiveOrders = ref.watch(hasActiveOrdersProvider);
    final user = ref.watch(authControllerProvider).user;
    final isProfileActive = currentIndex == 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => _onTap(context, i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Explorer',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: hasActiveOrders,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: hasActiveOrders,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: _ProfileNavIcon(
              avatarUrl: user?.avatarUrl,
              initials: user?.initials,
              isActive: isProfileActive,
            ),
            activeIcon: _ProfileNavIcon(
              avatarUrl: user?.avatarUrl,
              initials: user?.initials,
              isActive: true,
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _ProfileNavIcon extends StatelessWidget {
  final String? avatarUrl;
  final String? initials;
  final bool isActive;

  const _ProfileNavIcon({
    this.avatarUrl,
    this.initials,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // Pas connecté → icône classique
    if (initials == null) {
      return Icon(isActive ? Icons.person : Icons.person_outline);
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
          width: isActive ? 2 : 1.5,
        ),
        color: AppColors.primarySurface,
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _buildInitials(),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
