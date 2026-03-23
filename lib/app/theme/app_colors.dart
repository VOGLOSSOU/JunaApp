import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === COULEURS PRINCIPALES ===
  static const Color primary        = Color(0xFF1A5C2A);
  static const Color primaryLight   = Color(0xFF2E7D40);
  static const Color primaryDark    = Color(0xFF0F3D1A);
  static const Color primarySurface = Color(0xFFEEF5F0);

  // === ACCENT (orange — utilisation rare et ciblée) ===
  static const Color accent         = Color(0xFFF4521E);

  // === FOND & SURFACES ===
  static const Color white          = Color(0xFFFFFFFF);
  static const Color background     = Color(0xFFF7F7F7);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceGrey    = Color(0xFFF0F0F0);

  // === TEXTES ===
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF6B6B6B);
  static const Color textLight      = Color(0xFFAAAAAA);
  static const Color textOnPrimary  = Color(0xFFFFFFFF);

  // === ÉTATS SYSTÈME ===
  static const Color success        = Color(0xFF2E7D32);
  static const Color error          = Color(0xFFD32F2F);
  static const Color warning        = Color(0xFFF9A825);
  static const Color info           = Color(0xFF0277BD);

  // === BORDURES & SÉPARATEURS ===
  static const Color border         = Color(0xFFE0E0E0);
  static const Color divider        = Color(0xFFF0F0F0);

  // === STATUTS COMMANDES ===
  static const Color statusPending      = Color(0xFF9E9E9E);
  static const Color statusConfirmed    = Color(0xFF1565C0);
  static const Color statusPreparing    = Color(0xFFF57C00);
  static const Color statusReady        = Color(0xFF388E3C);
  static const Color statusDelivering   = Color(0xFFF57C00);
  static const Color statusDelivered    = Color(0xFF1A5C2A);
  static const Color statusCompleted    = Color(0xFF1A5C2A);
  static const Color statusCancelled    = Color(0xFFD32F2F);
}
