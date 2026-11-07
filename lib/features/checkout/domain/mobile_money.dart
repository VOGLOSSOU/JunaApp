import '../../../core/errors/app_exception.dart';

/// Opérateurs Mobile Money supportés par FeexPay.
///
/// Bénin uniquement pour l'instant. FeexPay ne détecte pas l'opérateur à
/// partir du numéro : l'utilisateur doit le choisir explicitement, sinon le
/// backend part par défaut sur MTN et les paiements Moov/Celtiis échouent.
enum MobileMoneyOperator {
  mtn(provider: 'MTN', label: 'MTN', method: 'MOBILE_MONEY_MTN'),
  moov(provider: 'MOOV', label: 'Moov', method: 'MOBILE_MONEY_MOOV'),
  celtiis(
      provider: 'CELTIIS', label: 'Celtiis', method: 'MOBILE_MONEY_CELTIIS');

  /// Valeur envoyée dans le champ `provider` de `POST /payments/initiate`.
  final String provider;
  final String label;

  /// Valeur du champ `method` renvoyée par `GET /payments/:id/status`.
  final String method;

  const MobileMoneyOperator({
    required this.provider,
    required this.label,
    required this.method,
  });

  /// Retrouve l'opérateur depuis un code `MOBILE_MONEY_*`. Renvoie null pour
  /// une valeur générique (`MOBILE_MONEY`) ou inconnue : l'utilisateur devra
  /// alors choisir lui-même.
  static MobileMoneyOperator? fromMethod(String? method) {
    for (final op in values) {
      if (op.method == method) return op;
    }
    return null;
  }
}

const beninDialCode = '229';

/// Convertit le numéro saisi en numéro complet attendu par le backend :
/// `229` + 10 chiffres commençant par `01`, sans `+` ni espace.
///
/// Accepte aussi un numéro déjà préfixé (`229…` ou `+229…`). Renvoie null si
/// le numéro n'est pas un numéro béninois valide.
String? toBeninPaymentPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 13 && digits.startsWith(beninDialCode)) {
    digits = digits.substring(beninDialCode.length);
  }
  if (digits.length != 10 || !digits.startsWith('01')) return null;
  return '$beninDialCode$digits';
}

/// Statut d'un paiement, tel que renvoyé à l'initiation ou au polling.
enum PaymentOutcome {
  processing,
  success,
  failed;

  /// Une valeur inconnue est traitée comme en cours : le polling tranchera.
  static PaymentOutcome parse(String status) => switch (status.toUpperCase()) {
        'SUCCESS' => success,
        'FAILED' => failed,
        _ => processing,
      };
}

/// Message affiché quand `POST /payments/initiate` est refusé.
String paymentInitiationErrorMessage(Object error) {
  final ex = error is AppException ? error : null;
  switch (ex?.code) {
    case 'PAYMENT_ALREADY_PROCESSED':
      return 'Un paiement est déjà en cours ou validé pour cette commande.';
    case 'INVALID_PAYMENT_REQUEST':
      return 'Numéro invalide. Vérifiez votre numéro et votre opérateur.';
  }
  final status = ex?.statusCode;
  if (ex == null || ex.isNetworkError || (status != null && status >= 500)) {
    return 'Service de paiement momentanément indisponible. Réessayez dans quelques instants.';
  }
  return ex.message;
}
