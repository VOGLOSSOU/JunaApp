import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

class _Slide {
  final String headline;
  final String sub;
  const _Slide({required this.headline, required this.sub});
}

const _slides = [
  _Slide(
    headline: 'Vos repas,\norganisés\npour vous.',
    sub: 'Fini de se demander quoi manger.\nJuna s\'en occupe.',
  ),
  _Slide(
    headline: 'Les meilleurs\ncuisiniers,\nprès de vous.',
    sub: 'Des prestataires vérifiés,\ndes recettes authentiques.',
  ),
  _Slide(
    headline: 'Abonnez-vous.\nSouciez-vous\nmoins.',
    sub: 'Commandez une fois,\nmangez plusieurs fois.',
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
    _setupAnimation();
    _textController.forward();
  }

  void _setupAnimation() {
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _textController.reset();
    _textController.forward();
  }

  Future<void> _next() async {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cercle déco haut droite ──
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
          ),

          // ── Cercle déco bas gauche ──
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ),

          // ── Logo en watermark centré ──
          Center(
            child: Opacity(
              opacity: 0.06,
              child: Image.asset(
                'assets/images/logo_white_orange.png',
                width: 260,
              ),
            ),
          ),

          // ── PageView invisible pour swipe ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (_, __) => const SizedBox.shrink(),
          ),

          // ── Contenu principal ──
          SafeArea(
            child: Column(
              children: [
                // Logo petit en haut centré
                const SizedBox(height: AppSpacing.xl),
                Image.asset(
                  'assets/images/logo_white_orange.png',
                  height: 30,
                ),

                // Texte centré verticalement
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Titre
                              Text(
                                slide.headline,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              // Sous-titre
                              Text(
                                slide.sub,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.5),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bas de page ──
                Padding(
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (i) {
                          final isActive = i == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Bouton
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? AppColors.accent
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: isLast
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                isLast ? 'Commencer' : 'Suivant',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
