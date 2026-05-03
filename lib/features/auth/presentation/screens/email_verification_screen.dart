import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/auth_controller.dart';
import 'otp_verification_screen.dart';

class EmailVerificationExtra {
  final String? prefillEmail;
  final String? redirectTo;

  const EmailVerificationExtra({this.prefillEmail, this.redirectTo});
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  // null = flow inscription, non-null = flow post-login (email déjà connu)
  final String? prefillEmail;
  final String? redirectTo;

  const EmailVerificationScreen({
    super.key,
    this.prefillEmail,
    this.redirectTo,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl =
        TextEditingController(text: widget.prefillEmail ?? '');
    // Si email déjà connu (post-login), envoyer le code automatiquement
    if (widget.prefillEmail != null && widget.prefillEmail!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send());
    }
  }

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
      await ref.read(authControllerProvider.notifier).sendVerificationCode(email);
      if (!mounted) return;
      context.push(
        AppRoutes.verifyCode,
        extra: OtpVerificationExtra(email: email, redirectTo: widget.redirectTo),
      );
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
    final isPostLogin = widget.prefillEmail != null;

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
                  onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
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
                    Text(
                      isPostLogin
                          ? 'Vérifiez votre email'
                          : 'Créer un compte',
                      style: AppTypography.headlineLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isPostLogin
                          ? 'Votre email doit être vérifié pour continuer. Nous vous envoyons un code à 6 chiffres.'
                          : 'Commencez par entrer votre adresse email. Nous vous enverrons un code de vérification.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),

                    Text('Adresse email', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isPostLogin && !_loading,
                      onChanged: (_) => setState(() => _error = null),
                      decoration: InputDecoration(
                        hintText: 'votre@email.com',
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.textLight),
                        suffixIcon: isPostLogin
                            ? const Icon(Icons.lock_outline,
                                color: AppColors.textLight, size: 16)
                            : null,
                        errorText: _error,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    else
                      JunaButton(
                        label: 'Envoyer le code',
                        onPressed: _send,
                        variant: JunaButtonVariant.secondary,
                      ),
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
