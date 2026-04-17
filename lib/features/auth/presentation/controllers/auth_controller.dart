import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../home/presentation/controllers/location_controller.dart';
import '../../data/models/auth_models.dart';
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

  Future<void> _checkAuth() async {
    final hasTokens = await _repository.isAuthenticated();
    if (!hasTokens) return;
    try {
      final apiUser = await _repository.getMe();
      state = state.copyWith(user: _buildUser(apiUser));
    } catch (_) {
      await _repository.logout();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.login(email: email, password: password);
      // getMe() pour récupérer le profil complet (adresse, ville, etc.)
      final fullUser = await _repository.getMe();
      state = state.copyWith(isLoading: false, user: _buildUser(fullUser));
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
      await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      // getMe() pour récupérer le profil complet
      final fullUser = await _repository.getMe();
      state = state.copyWith(isLoading: false, user: _buildUser(fullUser));
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
      await _repository.updateMe({
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      });
      // Un seul getMe() pour rafraîchir le profil
      final fullUser = await _repository.getMe();
      state = state.copyWith(isLoading: false, user: _buildUser(fullUser));
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
      // Mettre à jour l'avatar dans le profil
      await _repository.updateMe({'avatarUrl': url});
      final fullUser = await _repository.getMe();
      state = state.copyWith(user: _buildUser(fullUser));
      return url;
    } catch (e) {
      final exception = extractException(e);
      state = state.copyWith(error: exception.message);
      return null;
    }
  }

  Future<void> updateLocation(String cityId) async {
    try {
      await _repository.updateLocation(cityId);
      final fullUser = await _repository.getMe();
      final user = _buildUser(fullUser);
      state = state.copyWith(user: user);
      if (user.profile.city != null) {
        _ref.read(locationControllerProvider.notifier).selectCity(
              user.profile.city!.name,
              user.profile.city!.countryCode,
            );
      }
    } catch (_) {}
  }

  void updateUser(UserEntity updatedUser) {
    state = state.copyWith(user: updatedUser);
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
