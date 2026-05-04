class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  const AppException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => message;

  // Constructeurs nommés pour chaque type d'erreur
  factory AppException.network() => const AppException(
        message: 'Vérifiez votre connexion internet.',
        code: 'NETWORK_ERROR',
      );

  factory AppException.timeout() => const AppException(
        message: 'La requête a pris trop de temps. Réessayez.',
        code: 'TIMEOUT',
      );

  factory AppException.unauthorized() => const AppException(
        message: 'Session expirée. Veuillez vous reconnecter.',
        code: 'TOKEN_EXPIRED',
        statusCode: 401,
      );

  factory AppException.forbidden() => const AppException(
        message: 'Vous n\'avez pas les droits nécessaires.',
        code: 'INSUFFICIENT_PERMISSIONS',
        statusCode: 403,
      );

  factory AppException.notFound(String resource) => AppException(
        message: '$resource introuvable.',
        code: 'RESOURCE_NOT_FOUND',
        statusCode: 404,
      );

  factory AppException.validation(String message) => AppException(
        message: message,
        code: 'VALIDATION_ERROR',
        statusCode: 422,
      );

  factory AppException.rateLimit() => const AppException(
        message: 'Trop de tentatives. Attendez quelques minutes.',
        code: 'RATE_LIMIT_EXCEEDED',
        statusCode: 429,
      );

  factory AppException.invalidCredentials() => const AppException(
        message: 'Email ou mot de passe incorrect.',
        code: 'INVALID_CREDENTIALS',
        statusCode: 401,
      );

  factory AppException.server() => const AppException(
        message: 'Erreur serveur. Réessayez plus tard.',
        code: 'SERVER_ERROR',
        statusCode: 500,
      );

  factory AppException.fromCode(String? code, String? message, int? status) {
    // Priorité : si le backend a envoyé un message lisible, on l'utilise toujours
    final apiMessage = _cleanMessage(message);

    switch (code) {
      case 'INVALID_CREDENTIALS':
        return AppException(
          message: apiMessage ?? 'Email ou mot de passe incorrect.',
          code: code, statusCode: status,
        );
      case 'INVALID_PASSWORD':
        return AppException(
          message: apiMessage ?? 'Mot de passe actuel incorrect.',
          code: code, statusCode: status,
        );
      case 'INVALID_TOKEN':
        return AppException(
          message: apiMessage ?? 'Token invalide ou expiré.',
          code: code, statusCode: status,
        );
      case 'TOKEN_EXPIRED':
        return AppException.unauthorized();
      case 'ACCOUNT_SUSPENDED':
        return AppException(
          message: apiMessage ?? 'Compte suspendu. Contactez le support.',
          code: code, statusCode: status,
        );
      case 'INSUFFICIENT_PERMISSIONS':
      case 'FORBIDDEN':
        return AppException(
          message: apiMessage ?? 'Vous n\'avez pas les droits nécessaires.',
          code: code, statusCode: status,
        );
      case 'RESOURCE_NOT_FOUND':
      case 'USER_NOT_FOUND':
      case 'SUBSCRIPTION_NOT_FOUND':
      case 'ORDER_NOT_FOUND':
        return AppException(
          message: apiMessage ?? 'Ressource introuvable.',
          code: code, statusCode: status,
        );
      case 'VALIDATION_ERROR':
        final display = apiMessage ?? _translateValidation(message);
        return AppException.validation(display);
      case 'INVALID_INPUT':
        return AppException(
          message: apiMessage ?? 'Données invalides. Vérifiez vos informations.',
          code: code, statusCode: status,
        );
      case 'RATE_LIMIT_EXCEEDED':
        return AppException.rateLimit();
      case 'EMAIL_NOT_VERIFIED':
        return const AppException(
          message: 'Votre email doit être vérifié pour effectuer cette action.',
          code: 'EMAIL_NOT_VERIFIED', statusCode: 403,
        );
      case 'EMAIL_ALREADY_EXISTS':
      case 'USER_ALREADY_EXISTS':
        return AppException(
          message: apiMessage ?? 'Un compte existe déjà avec cet email.',
          code: code, statusCode: status,
        );
      case 'PHONE_ALREADY_EXISTS':
        return AppException(
          message: apiMessage ?? 'Ce numéro de téléphone est déjà utilisé.',
          code: code, statusCode: status,
        );
      case 'PROVIDER_EXISTS':
        return AppException(
          message: apiMessage ?? 'Vous êtes déjà enregistré comme prestataire.',
          code: code, statusCode: status,
        );
      case 'REVIEW_ALREADY_EXISTS':
        return AppException(
          message: apiMessage ?? 'Vous avez déjà soumis un avis pour cette commande.',
          code: code, statusCode: status,
        );
      case 'ORDER_CANNOT_BE_CANCELLED':
        return AppException(
          message: apiMessage ?? 'Cette commande ne peut plus être annulée.',
          code: code, statusCode: status,
        );
      default:
        return AppException(
          message: apiMessage ?? 'Une erreur inattendue s\'est produite.',
          code: code, statusCode: status,
        );
    }
  }

  static String _translateValidation(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'VALIDATION_ERROR') {
      return 'Données invalides. Vérifiez vos informations.';
    }
    // Traductions des messages NestJS courants
    final lower = raw.toLowerCase();
    if (lower.contains('must be an email') ||
        (lower.contains('email') && lower.contains('valid'))) {
      return 'Adresse email invalide.';
    }
    if (lower.contains('password') && lower.contains('empty')) {
      return 'Le mot de passe est requis.';
    }
    if (lower.contains('password') &&
        (lower.contains('8') || lower.contains('min'))) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (lower.contains('password') && lower.contains('uppercase')) {
      return 'Le mot de passe doit contenir au moins une majuscule.';
    }
    if (lower.contains('password') && lower.contains('number')) {
      return 'Le mot de passe doit contenir au moins un chiffre.';
    }
    if (lower.contains('phone') && lower.contains('valid')) {
      return 'Numéro de téléphone invalide.';
    }
    if (lower.contains('name') && lower.contains('empty')) {
      return 'Le nom est requis.';
    }
    if (lower.contains('email') && lower.contains('empty')) {
      return 'L\'email est requis.';
    }
    // Si plusieurs erreurs, les séparer proprement
    if (lower.contains(',')) {
      final parts =
          raw.split(',').map((p) => _translateValidation(p.trim())).toList();
      return parts.join(' • ');
    }
    return raw;
  }

  static String? _cleanMessage(String? message) {
    if (message == null || message.isEmpty) return null;
    // Si le message ressemble à un code technique, on ignore
    if (message == message.toUpperCase() && message.contains('_')) return null;
    return message;
  }
}
