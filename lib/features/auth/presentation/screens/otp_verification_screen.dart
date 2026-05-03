import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import 'register_screen.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/juna_button.dart';
import '../controllers/auth_controller.dart';

class OtpVerificationExtra {
  final String email;
  final String? redirectTo;

  const OtpVerificationExtra({required this.email, this.redirectTo});
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final OtpVerificationExtra extra;

  const OtpVerificationScreen({super.key, required this.extra});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Countdown 10 min pour l'expiration du code
  late Timer _expiryTimer;
  int _secondsLeft = 600;

  // Cooldown 60s avant de pouvoir renvoyer
  Timer? _resendTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _startExpiryTimer();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _expiryTimer.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startExpiryTimer() {
    _secondsLeft = 600;
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _expiryTimer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendCooldown <= 0) {
        _resendTimer?.cancel();
        return;
      }
      setState(() => _resendCooldown--);
    });
  }

  String get _expiryDisplay {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authControllerProvider.notifier)
          .sendVerificationCode(widget.extra.email);
      _expiryTimer.cancel();
      _startExpiryTimer();
      _startResendCooldown();
      _codeCtrl.clear();
    } catch (_) {
      setState(() => _error = 'Erreur lors du renvoi. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres');
      return;
    }
    if (_secondsLeft <= 0) {
      setState(() => _error = 'Code expiré. Renvoyez un nouveau code.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ref.read(authControllerProvider.notifier).verifyCode(
        email: widget.extra.email,
        code: code,
      );

      if (!mounted) return;

      if (result.userExists) {
        // Flow post-login : user existant vérifié → demander de se reconnecter
        ref.read(authControllerProvider.notifier).clearEmailVerification();
        _showReconnectDialog();
      } else {
        // Flow inscription : aller vers le formulaire d'inscription
        context.pushReplacement(
          AppRoutes.register,
          extra: RegisterExtra(
            email: widget.extra.email,
            verifiedToken: result.verifiedToken,
            redirectTo: widget.extra.redirectTo,
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        if (msg.contains('INVALID_TOKEN') || msg.contains('INVALID_CODE')) {
          _error = 'Code incorrect. Vérifiez et réessayez.';
        } else if (msg.contains('TOKEN_EXPIRED')) {
          _error = 'Code expiré. Renvoyez un nouveau code.';
          setState(() => _secondsLeft = 0);
        } else if (msg.contains('RATE_LIMIT')) {
          _error = 'Trop de tentatives. Attendez avant de réessayer.';
        } else {
          _error = 'Une erreur est survenue. Réessayez.';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showReconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Email vérifié !'),
        content: const Text(
          'Votre email a bien été vérifié. Reconnectez-vous pour accéder à votre compte.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expired = _secondsLeft <= 0;

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
                    Text('Vérification email', style: AppTypography.headlineLarge),
                    const SizedBox(height: AppSpacing.sm),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Un code à 6 chiffres a été envoyé à '),
                          TextSpan(
                            text: widget.extra.email,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Champ OTP
                    Text('Code de vérification', style: AppTypography.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      enabled: !expired,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: AppTypography.headlineMedium.copyWith(
                        letterSpacing: 12,
                      ),
                      onChanged: (_) => setState(() => _error = null),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '······',
                        hintStyle: AppTypography.headlineMedium.copyWith(
                          color: AppColors.textLight,
                          letterSpacing: 12,
                        ),
                        errorText: _error,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Countdown
                    Center(
                      child: Text(
                        expired
                            ? 'Code expiré — renvoyez un nouveau code'
                            : 'Code valable encore $_expiryDisplay',
                        style: AppTypography.bodySmall.copyWith(
                          color: expired ? AppColors.error : AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    if (!expired)
                      JunaButton(
                        label: 'Vérifier',
                        isLoading: _loading,
                        variant: JunaButtonVariant.secondary,
                        onPressed: _verify,
                      ),

                    const SizedBox(height: AppSpacing.lg),

                    // Renvoyer le code
                    Center(
                      child: GestureDetector(
                        onTap: _resendCooldown > 0 || _loading ? null : _resend,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Renvoyer dans ${_resendCooldown}s'
                              : 'Renvoyer le code',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _resendCooldown > 0
                                ? AppColors.textLight
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: _resendCooldown > 0
                                ? TextDecoration.none
                                : TextDecoration.underline,
                          ),
                        ),
                      ),
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
