import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';

class _Slide {
  final String headline;
  final String sub;
  final Color accentColor;

  const _Slide({
    required this.headline,
    required this.sub,
    required this.accentColor,
  });
}

const _slides = [
  _Slide(
    headline: 'Vos repas,\norganisés\npour vous.',
    sub: 'Fini de se demander quoi manger. Juna s\'en occupe.',
    accentColor: Color(0xFF2E7D40),
  ),
  _Slide(
    headline: 'Les meilleurs\ncuisiniers,\nprès de vous.',
    sub: 'Des prestataires vérifiés, des recettes authentiques.',
    accentColor: Color(0xFFF4521E),
  ),
  _Slide(
    headline: 'Abonnez-vous.\nSouciez-vous\nmoins.',
    sub: 'Commandez une fois, mangez plusieurs fois.',
    accentColor: Color(0xFF1A5C2A),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    if (_currentIndex < _slides.length - 1) {
      _textController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go(AppRoutes.home);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _textController.reset();
    _textController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final size = MediaQuery.of(context).size;
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        children: [
          // Cercle décoratif haut droite
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            top: _currentIndex == 0 ? -60 : _currentIndex == 1 ? -100 : -40,
            right: _currentIndex == 1 ? -40 : -80,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: _currentIndex == 1 ? 320 : 280,
              height: _currentIndex == 1 ? 320 : 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: slide.accentColor.withOpacity(0.18),
              ),
            ),
          ),

          // Cercle décoratif bas gauche
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            bottom: _currentIndex == 2 ? -40 : -80,
            left: _currentIndex == 0 ? -60 : -30,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: _currentIndex == 2 ? 260 : 220,
              height: _currentIndex == 2 ? 260 : 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(
                  _currentIndex == 1 ? 0.14 : 0.08,
                ),
              ),
            ),
          ),

          // Cercle décoratif milieu (slide 2 seulement)
          if (_currentIndex == 1)
            Positioned(
              top: size.height * 0.35,
              left: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
            ),

          // Contenu principal
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (_, i) => const SizedBox.shrink(),
            ),
          ),

          // Logo en haut
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.xl, left: AppSpacing.xl),
              child: Image.asset(
                'assets/images/logo_white_orange.png',
                height: 32,
              ),
            ),
          ),

          // Texte central animé
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.22),
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.headline,
                            style: AppTypography.headlineLarge.copyWith(
                              color: Colors.white,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              fontSize: 40,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            slide.sub,
                            style: AppTypography.bodyLarge.copyWith(
                              color: Colors.white.withOpacity(0.55),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bas de page : indicators + boutons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Indicateurs
                    Row(
                      children: List.generate(_slides.length, (i) {
                        final isActive = i == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Bouton principal
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: GestureDetector(
                          key: ValueKey(isLast),
                          onTap: _onNext,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? AppColors.accent
                                  : Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: isLast
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                isLast ? 'Commencer' : 'Suivant',
                                style: AppTypography.titleMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Passer
                    if (!isLast)
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Passer',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
