import 'package:cached_network_image/cached_network_image.dart';
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
  final String imageUrl;

  const _Slide({
    required this.headline,
    required this.sub,
    required this.imageUrl,
  });
}

const _slides = [
  _Slide(
    headline: 'Vos repas,\norganisés\npour vous.',
    sub: 'Fini de se demander quoi manger.\nJuna s\'en occupe.',
    imageUrl: 'https://images.unsplash.com/photo-1588166524941-3bf61a9c41db?w=800&q=80',
  ),
  _Slide(
    headline: 'Les meilleurs\ncuisiniers,\nprès de vous.',
    sub: 'Des prestataires vérifiés,\ndes recettes authentiques.',
    imageUrl: 'https://images.unsplash.com/photo-1574484284002-952d92456975?w=800&q=80',
  ),
  _Slide(
    headline: 'Abonnez-vous.\nSouciez-vous\nmoins.',
    sub: 'Commandez une fois,\nmangez plusieurs fois.',
    imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800&q=80',
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
        duration: const Duration(milliseconds: 600),
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
          // ── Photo de fond avec transition animée ──
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: _BackgroundPhoto(
              key: ValueKey(_currentIndex),
              imageUrl: slide.imageUrl,
            ),
          ),

          // ── Overlay dégradé (bas → haut) ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark.withOpacity(0.55),
                  AppColors.primaryDark.withOpacity(0.75),
                  AppColors.primaryDark.withOpacity(0.95),
                  AppColors.primaryDark,
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Contenu principal ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Logo petit en haut centré
                Image.asset(
                  'assets/images/logo_white_orange.png',
                  height: 28,
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
                              Text(
                                slide.sub,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.6),
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
                                  : Colors.white.withOpacity(0.25),
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
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: isLast
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withOpacity(0.25),
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

class _BackgroundPhoto extends StatelessWidget {
  final String imageUrl;
  const _BackgroundPhoto({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        placeholder: (_, __) => Container(color: AppColors.primaryDark),
        errorWidget: (_, __, ___) => Container(color: AppColors.primaryDark),
      ),
    );
  }
}
