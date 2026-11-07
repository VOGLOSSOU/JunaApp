import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

enum AuthErrorOrigin { other, login, session }

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final bool isInitializing;
  // true si des tokens valides existent en stockage mais le profil n'a pas pu être chargé (erreur réseau)
  final bool hasStoredSession;
  final String? error;
  final AuthErrorOrigin errorOrigin;
  final bool needsProfileCompletion;
  final bool needsEmailVerification;
  // Email temporaire pour le flow OTP post-login
  final String? unverifiedEmail;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.hasStoredSession = false,
    this.error,
    this.errorOrigin = AuthErrorOrigin.other,
    this.needsProfileCompletion = false,
    this.needsEmailVerification = false,
    this.unverifiedEmail,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    bool? isInitializing,
    bool? hasStoredSession,
    String? error,
    AuthErrorOrigin? errorOrigin,
    bool? needsProfileCompletion,
    bool? needsEmailVerification,
    String? unverifiedEmail,
    bool clearUser = false,
    bool clearError = false,
    bool clearUnverifiedEmail = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      hasStoredSession: hasStoredSession ?? this.hasStoredSession,
      error: clearError ? null : (error ?? this.error),
      errorOrigin: clearError
          ? AuthErrorOrigin.other
          : error != null
              ? (errorOrigin ?? AuthErrorOrigin.other)
              : this.errorOrigin,
      needsProfileCompletion:
          needsProfileCompletion ?? this.needsProfileCompletion,
      needsEmailVerification:
          needsEmailVerification ?? this.needsEmailVerification,
      unverifiedEmail: clearUnverifiedEmail
          ? null
          : (unverifiedEmail ?? this.unverifiedEmail),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final CacheService _cacheService;
  final Ref _ref;
  int _authVersion = 0;
  bool _isCurrent(int version) => mounted && version == _authVersion;

  AuthController(this._repository, this._cacheService, this._ref)
      : super(const AuthState()) {
    _ref.listen<int>(sessionInvalidationProvider, (previous, next) {
      if (previous != null && next > previous) {
        _expireSessionLocally();
      }
    });
    _checkAuth();
  }

  Future<void> _expireSessionLocally() async {
    // A guest has no session to expire. In particular, a late anonymous 401
    // must not clear a failed login or replace it with a session warning.
    if (!mounted || (state.user == null && !state.hasStoredSession)) return;
    _authVersion++;
    state = const AuthState(
      isInitializing: false,
      error: 'Session expirée. Veuillez vous reconnecter.',
      errorOrigin: AuthErrorOrigin.session,
    );
    // Clear before starting another session; never write auth state after
    // asynchronous cleanup, which could overwrite a newer login result.
    await _cacheService.clearAll(const [
      'user_profile',
      'my_orders',
      'active_subscriptions',
    ]);
  }

  bool _isSessionRejection(AppException error) =>
      error.statusCode == 401 ||
      error.code == 'TOKEN_EXPIRED' ||
      error.code == 'INVALID_TOKEN';

  // Synchronise la localisation affichée dans le header avec le profil user
  void _syncLocation(UserEntity user) {
    final city = user.profile.city;
    if (city != null) {
      _ref.read(locationControllerProvider.notifier).selectCity(
            city.name,
            city.countryCode,
            cityId: city.id,
          );
    }
  }

  // Construit un UserEntity complet depuis ApiUserModel
  UserEntity _buildUser(ApiUserModel apiUser) => UserEntity(
        id: apiUser.id,
        name: apiUser.name,
        email: apiUser.email,
        phone: apiUser.phone,
        role: UserRole.user,
        isVerified: apiUser.isVerified,
        isActive: apiUser.isActive,
        avatarUrl: apiUser.profile.avatar ?? apiUser.avatarUrl,
        profile: UserProfile(
          avatar: apiUser.profile.avatar,
          address: apiUser.profile.address,
          city: apiUser.profile.city,
          preferences: apiUser.profile.preferences,
        ),
      );

  Future<UserEntity> _cacheAndBuildUser(ApiUserModel apiUser) async {
    await _cacheService.save('user_profile', apiUser.toJson());
    return _buildUser(apiUser);
  }

  Future<void> _checkAuth() async {
    final version = _authVersion;
    bool hasTokens;
    try {
      hasTokens = await _repository.isAuthenticated();
    } catch (_) {
      if (_isCurrent(version)) state = state.copyWith(isInitializing: false);
      return;
    }
    if (!_isCurrent(version)) return;
    if (!hasTokens) {
      state = state.copyWith(isInitializing: false);
      return;
    }
    state = state.copyWith(hasStoredSession: true);
    final cachedProfile = await _cacheService.get('user_profile',
        maxAge: const Duration(days: 7));
    if (!_isCurrent(version)) return;
    if (cachedProfile != null) {
      try {
        final user = _buildUser(
            ApiUserModel.fromJson(cachedProfile as Map<String, dynamic>));
        state = state.copyWith(user: user, isInitializing: false);
        _syncLocation(user);
      } catch (_) {}
    }
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final apiUser = await _repository.getMe();
        if (!_isCurrent(version)) return;
        final user = await _cacheAndBuildUser(apiUser);
        if (!_isCurrent(version)) return;
        state = state.copyWith(
            user: user,
            isInitializing: false,
            hasStoredSession: false,
            clearError: true);
        _syncLocation(user);
        return;
      } catch (e) {
        if (!_isCurrent(version)) return;
        final exception = extractException(e);
        if (_isSessionRejection(exception)) {
          await _repository.logout();
          if (_isCurrent(version)) await _expireSessionLocally();
          return;
        }
        // A network outage, 429 or server failure is not a rejected session.
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
        if (!_isCurrent(version)) return;
      }
    }
    if (_isCurrent(version)) {
      state = state.copyWith(isInitializing: false, hasStoredSession: true);
    }
  }

  // Appelé quand l'app revient au premier plan ou que le réseau est rétabli
  Future<void> tryRestoreSession() async {
    if (state.isLoading || state.user != null) return;
    final version = _authVersion;
    final hasTokens = await _repository.isAuthenticated();
    if (!_isCurrent(version)) return;
    if (!hasTokens) {
      state = state.copyWith(hasStoredSession: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final apiUser = await _repository.getMe();
      if (!_isCurrent(version)) return;
      final user = await _cacheAndBuildUser(apiUser);
      if (!_isCurrent(version)) return;
      state =
          state.copyWith(user: user, isLoading: false, hasStoredSession: false);
      _syncLocation(user);
    } catch (_) {
      if (!_isCurrent(version)) return;
      // Réseau toujours indisponible — on réessaiera au prochain retour au premier plan
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    if (state.isLoading) return false;
    final version = ++_authVersion;
    state = state.copyWith(
      isLoading: true,
      isInitializing: false,
      hasStoredSession: false,
      clearUser: true,
      clearError: true,
    );
    try {
      final result = await _repository.login(email: email, password: password);
      if (!_isCurrent(version)) return false;
      final fullUser = await _repository.getMe();
      if (!_isCurrent(version)) return false;
      final user = _buildUser(fullUser);

      // Utilisateur non vérifié → ne pas connecter, stocker l'email pour le flow OTP
      if (!user.isVerified) {
        state = state.copyWith(
          isLoading: false,
          needsEmailVerification: true,
          unverifiedEmail: email,
        );
        return true;
      }

      await _cacheService.save('user_profile', fullUser.toJson());
      if (!_isCurrent(version)) return false;
      state = state.copyWith(
        isLoading: false,
        user: user,
        needsProfileCompletion: !result.isProfileComplete,
        needsEmailVerification: false,
        clearUnverifiedEmail: true,
      );
      _syncLocation(user);
      return true;
    } catch (e) {
      if (!_isCurrent(version)) return false;
      final exception = extractException(e);
      state = state.copyWith(
          isLoading: false,
          error: exception.message,
          errorOrigin: AuthErrorOrigin.login);
      return false;
    }
  }

  Future<void> sendVerificationCode(String email) async {
    await _repository.sendVerificationCode(email);
  }

  Future<({bool verified, String verifiedToken, bool userExists})> verifyCode({
    required String email,
    required String code,
  }) async {
    return _repository.verifyCode(email: email, code: code);
  }

  Future<void> forgotPassword(String email) async {
    await _repository.forgotPassword(email);
  }

  void clearEmailVerification() {
    state = state.copyWith(
      needsEmailVerification: false,
      clearUnverifiedEmail: true,
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String verifiedToken,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        verifiedToken: verifiedToken,
        phone: phone,
      );
      final fullUser = await _repository.getMe();
      final user = await _cacheAndBuildUser(fullUser);
      state = state.copyWith(
        isLoading: false,
        user: user,
        needsProfileCompletion: !result.isProfileComplete,
      );
      _syncLocation(user);
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cleanPhone = phone?.replaceAll(' ', '');
      await _repository.updateMe({
        'name': name,
        if (cleanPhone != null && cleanPhone.isNotEmpty) 'phone': cleanPhone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      });
      final fullUser = await _repository.getMe();
      final user = await _cacheAndBuildUser(fullUser);
      state = state.copyWith(isLoading: false, user: user);
      _syncLocation(user);
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  Future<String?> uploadAvatar(Uint8List bytes, String filename) async {
    try {
      final url = await _repository.uploadImageBytes(bytes, filename);
      await _repository.updateMe({'avatarUrl': url});
      final fullUser = await _repository.getMe();
      state = state.copyWith(user: await _cacheAndBuildUser(fullUser));
      return url;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(error: exception.message);
      return null;
    }
  }

  Future<bool> updateLocation(String cityId) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.updateLocation(cityId);
      final fullUser = await _repository.getMe();
      final user = await _cacheAndBuildUser(fullUser);
      state = state.copyWith(user: user);
      _syncLocation(user);
      return true;
    } catch (error) {
      state = state.copyWith(error: extractException(error).message);
      return false;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      await _repository.updatePreferences(preferences);
      final fullUser = await _repository.getMe();
      state = state.copyWith(user: await _cacheAndBuildUser(fullUser));
    } catch (_) {}
  }

  void updateUser(UserEntity updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    final version = ++_authVersion;
    await _repository.logout();
    await _cacheService.clearAll(const [
      'user_profile',
      'my_orders',
      'active_subscriptions',
    ]);
    if (_isCurrent(version)) state = const AuthState(isInitializing: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(cacheServiceProvider),
    ref,
  );
});
