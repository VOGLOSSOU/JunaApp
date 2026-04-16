import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AuthState()) {
    _checkAuth();
  }

  // Vérifie si un token valide existe au démarrage
  Future<void> _checkAuth() async {
    final hasTokens = await _repository.isAuthenticated();
    if (!hasTokens) return;
    try {
      final apiUser = await _repository.getMe();
      state = state.copyWith(
        user: UserEntity(
          id: apiUser.id,
          name: apiUser.name,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          isVerified: apiUser.isVerified,
          isActive: apiUser.isActive,
          avatarUrl: apiUser.profile.avatar,
          profile: UserProfile(
            avatar: apiUser.profile.avatar,
            address: apiUser.profile.address,
            city: apiUser.profile.city,
            preferences: apiUser.profile.preferences,
          ),
        ),
      );
    } catch (_) {
      await _repository.logout();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.login(email: email, password: password);
      final apiUser = result.user;
      state = state.copyWith(
        isLoading: false,
        user: UserEntity(
          id: apiUser.id,
          name: apiUser.name,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          avatarUrl: apiUser.avatarUrl,
        ),
      );
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      final apiUser = result.user;
      state = state.copyWith(
        isLoading: false,
        user: UserEntity(
          id: apiUser.id,
          name: apiUser.name,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          avatarUrl: apiUser.avatarUrl,
        ),
      );
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  void updateUser(UserEntity updatedUser) {
    state = state.copyWith(user: updatedUser);
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? address,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.updateMe({
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      });
      final apiUser = result;
      state = state.copyWith(
        isLoading: false,
        user: UserEntity(
          id: apiUser.id,
          name: apiUser.name,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          isVerified: apiUser.isVerified,
          isActive: apiUser.isActive,
          avatarUrl: apiUser.avatarUrl,
          profile: UserProfile(
            avatar: apiUser.profile.avatar,
            address: apiUser.profile.address,
            city: apiUser.profile.city,
            preferences: apiUser.profile.preferences,
          ),
        ),
      );
      // Update location from user profile
      if (apiUser.profile.city != null) {
        _ref.read(locationControllerProvider.notifier).selectCity(
              apiUser.profile.city!.name,
              apiUser.profile.city!.countryCode,
            );
      }
      return true;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(isLoading: false, error: exception.message);
      return false;
    }
  }

  Future<String> uploadAvatar(String filePath) async {
    try {
      return await _repository.uploadImage(filePath);
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(error: exception.message);
      rethrow;
    }
  }

  Future<void> updateLocation(String cityId) async {
    await _repository.updateLocation(cityId);
    // Refresh user profile after location update
    try {
      final apiUser = await _repository.getMe();
      state = state.copyWith(
        user: UserEntity(
          id: apiUser.id,
          name: apiUser.name,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          isVerified: apiUser.isVerified,
          isActive: apiUser.isActive,
          avatarUrl: apiUser.avatarUrl,
          profile: UserProfile(
            avatar: apiUser.profile.avatar,
            address: apiUser.profile.address,
            city: apiUser.profile.city,
            preferences: apiUser.profile.preferences,
          ),
        ),
      );
      // Update location from user profile
      if (apiUser.profile.city != null) {
        _ref.read(locationControllerProvider.notifier).selectCity(
              apiUser.profile.city!.name,
              apiUser.profile.city!.countryCode,
            );
      }
    } catch (_) {
      // Ignore refresh error
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref);
});
