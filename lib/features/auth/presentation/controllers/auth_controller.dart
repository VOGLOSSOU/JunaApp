import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
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

  AuthController(this._repository) : super(const AuthState()) {
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
          firstName: apiUser.firstName,
          lastName: apiUser.lastName,
          email: apiUser.email,
          phone: apiUser.phone,
          role: UserRole.user,
          avatarUrl: apiUser.avatarUrl,
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
          firstName: apiUser.firstName,
          lastName: apiUser.lastName,
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
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(
        name: lastName.isEmpty ? firstName : '$firstName $lastName',
        email: email,
        password: password,
        phone: phone,
      );
      final apiUser = result.user;
      state = state.copyWith(
        isLoading: false,
        user: UserEntity(
          id: apiUser.id,
          firstName: apiUser.firstName,
          lastName: apiUser.lastName,
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
  return AuthController(ref.read(authRepositoryProvider));
});
