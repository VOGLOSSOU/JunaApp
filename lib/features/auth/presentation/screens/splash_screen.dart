import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';

// URLs à précharger — mêmes que l'onboarding
const _onboardingImages = [
  'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&q=80',
  'https://images.unsplash.com/photo-1574484284002-952d92456975?w=800&q=80',
  'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80',
];

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Apparition initiale
  late AnimationController _introController;
  late Animation<double> _introFade;
  late Animation<double> _introScale;

  // Pulse x3
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // Tagline
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Dots
  late AnimationController _dotsController;

  // Exit
  late AnimationController _exitController;
  late Animation<double> _exitFade;

  bool _imagesReady = false;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _introFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOut),
    );
    _introScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulse = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Apparition du logo
    await Future.delayed(const Duration(milliseconds: 150));
    await _introController.forward();

    // 2. Tagline apparaît
    await _taglineController.forward();

    // 3. Préchargement des images en parallèle avec le pulse
    _preloadImages();

    // 4. Pulse x3 pendant le chargement
    for (int i = 0; i < 3; i++) {
      await _pulseController.forward();
      await _pulseController.reverse();
    }

    // 5. Attendre que les images soient prêtes (max 4s)
    final deadline = Future.delayed(const Duration(seconds: 4));
    await Future.any([
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return !_imagesReady;
      }),
      deadline,
    ]);

    // 6. Fade out et navigation
    await _exitController.forward();
    _navigate();
  }

  Future<void> _preloadImages() async {
    try {
      await Future.wait(
        _onboardingImages.map(
          (url) => precacheImage(CachedNetworkImageProvider(url), context),
        ),
      );
    } catch (_) {}
    if (mounted) setState(() => _imagesReady = true);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_completed') ?? false;
    if (!mounted) return;
    context.go(onboardingDone ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _taglineController.dispose();
    _dotsController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: FadeTransition(
        opacity: _exitFade,
        child: Stack(
          children: [
            // Cercle déco haut droite
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.18),
                ),
              ),
            ),
            // Cercle déco bas gauche
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.1),
                ),
              ),
            ),

            // Contenu centré
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo avec intro + pulse
                  AnimatedBuilder(
                    animation: Listenable.merge(
                        [_introController, _pulseController]),
                    builder: (_, __) => FadeTransition(
                      opacity: _introFade,
                      child: Transform.scale(
                        scale: _introScale.value * _pulse.value,
                        child: Image.asset(
                          'assets/images/logo_white_orange.png',
                          width: 180,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Abonnez-vous, mangez bien chaque jour.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dots loader en bas
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _taglineFade,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _dotsController,
                    builder: (_, __) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final delay = i / 3;
                        final v =
                            (_dotsController.value - delay).clamp(0.0, 1.0);
                        final opacity =
                            (v < 0.5 ? v * 2 : (1 - v) * 2).clamp(0.2, 1.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
