import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;
  const LoginScreen({super.key, this.redirectTo});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (success && mounted) {
      final firstName = ref.read(authControllerProvider).user?.name.split(' ').first ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstName.isNotEmpty ? 'Bienvenue, $firstName !' : 'Connexion réussie !',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primaryLight, // Vert plus léger
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(seconds: 3), // Un peu plus long
        ),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        context.go(widget.redirectTo ?? AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
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
                              'assets/images/logo_green_orange.png',
                              width: 120,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text('Bon retour',
                                style: AppTypography.headlineLarge),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Connectez-vous pour continuer',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // Email
                      Text('Email', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Email invalide'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'votre@email.com',
                          prefixIcon: Icon(Icons.email_outlined,
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
                        validator: (v) => v == null || v.length < 6
                            ? 'Minimum 6 caractères'
                            : null,
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
                        label: 'Se connecter',
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                        variant: JunaButtonVariant.secondary,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            child: Text('ou',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textLight)),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pas de compte ? ',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.push(
                              '${AppRoutes.register}${widget.redirectTo != null ? "?redirect=${widget.redirectTo}" : ""}',
                            ),
                            child: Text(
                              'S\'inscrire',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
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
