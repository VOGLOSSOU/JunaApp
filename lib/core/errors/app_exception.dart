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
        return AppException.validation(message ?? 'Données invalides.');
      case 'RATE_LIMIT_EXCEEDED':
        return AppException.rateLimit();
      default:
        return AppException(
          message: message ?? 'Une erreur est survenue.',
          code: code,
          statusCode: status,
        );
    }
  }
}
