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
    switch (code) {
      case 'INVALID_CREDENTIALS':
        return AppException.invalidCredentials();
      case 'TOKEN_EXPIRED':
        return AppException.unauthorized();
      case 'INSUFFICIENT_PERMISSIONS':
        return AppException.forbidden();
      case 'RESOURCE_NOT_FOUND':
        return AppException.notFound(message ?? 'Ressource');
      case 'VALIDATION_ERROR':
        // Le message peut être le code lui-même ou un message NestJS brut
        final display = _translateValidation(message);
        return AppException.validation(display);
      case 'RATE_LIMIT_EXCEEDED':
        return AppException.rateLimit();
      case 'EMAIL_ALREADY_EXISTS':
      case 'USER_ALREADY_EXISTS':
        return const AppException(
          message: 'Un compte existe déjà avec cet email.',
          code: 'EMAIL_ALREADY_EXISTS',
          statusCode: 409,
        );
      default:
        // Message brut du backend s'il est lisible, sinon message générique
        final display = _cleanMessage(message);
        return AppException(
          message: display ?? 'Une erreur est survenue.',
          code: code,
          statusCode: status,
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
