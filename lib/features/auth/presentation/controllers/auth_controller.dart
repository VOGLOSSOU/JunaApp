import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  AuthController() : super(const AuthState());

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(seconds: 1)); // simulate API

    // Mock: accepte tout email/mdp pour la démo
    state = state.copyWith(
      isLoading: false,
      user: UserEntity(
        id: 'u1',
        firstName: 'Marcus',
        lastName: 'Dupont',
        email: email,
        phone: '+229 97 00 00 00',
        role: UserRole.user,
        city: 'Cotonou',
      ),
    );
    return true;
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(
      isLoading: false,
      user: UserEntity(
        id: 'u1',
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: UserRole.user,
        city: 'Cotonou',
      ),
    );
    return true;
  }

  void logout() {
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);
