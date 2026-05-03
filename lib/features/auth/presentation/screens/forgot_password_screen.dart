import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Entrez une adresse email valide');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _error = msg.contains('RATE_LIMIT')
          ? 'Trop de tentatives. Attendez avant de réessayer.'
          : 'Erreur lors de l\'envoi. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: GestureDetector(
                  onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceGrey,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 16, color: AppColors.textPrimary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Image.asset('assets/images/juna-icon.png', width: 100),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Mot de passe oublié', style: AppTypography.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _sent
                          ? 'Un lien de réinitialisation a été envoyé à votre adresse email. Vérifiez votre boîte de réception.'
                          : 'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),

                    if (_sent) ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mark_email_read_outlined,
                              color: AppColors.primary, size: 36),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      JunaButton(
                        label: 'Retour à la connexion',
                        variant: JunaButtonVariant.secondary,
                        onPressed: () => context.go(AppRoutes.login),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.xxxl),
                      Text('Adresse email', style: AppTypography.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_loading,
                        onChanged: (_) => setState(() => _error = null),
                        decoration: InputDecoration(
                          hintText: 'votre@email.com',
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: AppColors.textLight),
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      JunaButton(
                        label: 'Envoyer le lien',
                        isLoading: _loading,
                        variant: JunaButtonVariant.secondary,
                        onPressed: _send,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go(AppRoutes.login),
                          child: Text(
                            'Retour à la connexion',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
