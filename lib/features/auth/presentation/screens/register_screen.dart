import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../controllers/auth_controller.dart';

class RegisterExtra {
  final String email;
  final String verifiedToken;
  final String? redirectTo;

  const RegisterExtra({
    required this.email,
    required this.verifiedToken,
    this.redirectTo,
  });
}

class RegisterScreen extends ConsumerStatefulWidget {
  final RegisterExtra extra;

  const RegisterScreen({super.key, required this.extra});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isNavigating = false;
  String _password = '';
  final _formKey = GlobalKey<FormState>();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: widget.extra.email,
          password: _passwordCtrl.text,
          verifiedToken: widget.extra.verifiedToken,
          phone: _phoneCtrl.text.trim(),
        );

    if (success && mounted) {
      final authState = ref.read(authControllerProvider);
      final firstName = authState.user?.name.split(' ').first ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstName.isNotEmpty ? 'Compte créé ! Bienvenue, $firstName !' : 'Compte créé avec succès !',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primaryLight,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(seconds: 3),
        ),
      );

      final location = ref.read(locationControllerProvider);
      final hasCachedCity = location.cityId != null;

      if (hasCachedCity) {
        // Lancer l'animation de pulsation pendant le setup de la ville
        setState(() => _isNavigating = true);
        _pulseCtrl.repeat(reverse: true);

        await Future.wait([
          Future.delayed(const Duration(milliseconds: 400)),
          ref.read(authControllerProvider.notifier).updateLocation(location.cityId!),
        ]);

        _pulseCtrl.stop();
        if (mounted) context.go(widget.extra.redirectTo ?? AppRoutes.home);
      } else {
        // Pas de ville en cache → l'user doit choisir sa localisation
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) context.go(AppRoutes.accountSettings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            // Bouton retour
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GestureDetector(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.home);
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),

            // Formulaire scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Logo + titre
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/juna-icon.png',
                              width: 100,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text('Créer un compte',
                                style: AppTypography.headlineLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Rejoignez Juna et mangez bien chaque jour.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Email (verrouillé — déjà vérifié)
                      Text('Email', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        initialValue: widget.extra.email,
                        enabled: false,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined,
                              color: AppColors.textLight),
                          suffixIcon: Icon(Icons.lock_outline,
                              color: AppColors.textLight, size: 16),
                        ),
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Nom complet
                      Text('Nom complet', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Champ requis';
                          if (v.trim().length < 2) return 'Minimum 2 caractères';
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Marcus Dupont',
                          prefixIcon: Icon(Icons.person_outline,
                              color: AppColors.textLight),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Téléphone
                      Text('Téléphone', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                        decoration: const InputDecoration(
                          hintText: '+229 97 00 00 00',
                          prefixIcon: Icon(Icons.phone_outlined,
                              color: AppColors.textLight),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Mot de passe
                      Text('Mot de passe', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        onChanged: (v) => setState(() => _password = v),
                        validator: (v) {
                          if (v == null || v.length < 8) return 'Minimum 8 caractères';
                          if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Ajoutez au moins une majuscule';
                          if (!RegExp(r'[0-9]').hasMatch(v)) return 'Ajoutez au moins un chiffre';
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.textLight),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textLight,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _PasswordStrengthIndicator(password: _password),

                      // Erreur API
                      if (authState.error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxxl),

                      JunaButton(
                        label: 'Créer mon compte',
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Déjà un compte ? ',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.canPop()
                                ? context.pop()
                                : context.go(AppRoutes.login),
                            child: Text(
                              'Se connecter',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Consentement légal
                      const _LegalConsentText(),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

          // Overlay pulsation pendant le setup de la ville
          if (_isNavigating)
            Positioned.fill(
              child: Container(
                color: AppColors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Transform.scale(
                        scale: _pulse.value,
                        child: Image.asset(
                          'assets/images/juna-icon.png',
                          width: 120,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Configuration en cours…',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final has8 = password.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Criterion(label: 'Au moins 8 caractères', met: has8),
        const SizedBox(height: 4),
        _Criterion(label: 'Au moins une majuscule', met: hasUpper),
        const SizedBox(height: 4),
        _Criterion(label: 'Au moins un chiffre', met: hasDigit),
      ],
    );
  }
}

class _Criterion extends StatelessWidget {
  final String label;
  final bool met;
  const _Criterion({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF2E7D32) : AppColors.textLight;
    return Row(
      children: [
        Icon(
          met ? Icons.check_rounded : Icons.close_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: color, fontSize: 12),
        ),
      ],
    );
  }
}

class _LegalConsentText extends StatelessWidget {
  const _LegalConsentText();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 11,
      color: AppColors.textLight,
      height: 1.5,
    );
    const linkStyle = TextStyle(
      fontSize: 11,
      color: AppColors.textLight,
      height: 1.5,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(
              text: 'En créant un compte, vous reconnaissez avoir pris connaissance de nos '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _open('https://junaeats.com/privacy'),
              child: const Text('politique de confidentialité', style: linkStyle),
            ),
          ),
          const TextSpan(text: ', '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _open('https://junaeats.com/terms'),
              child: const Text('conditions d\'utilisation', style: linkStyle),
            ),
          ),
          const TextSpan(text: ' et '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => _open('https://junaeats.com/sales-terms'),
              child: const Text('conditions de vente', style: linkStyle),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
