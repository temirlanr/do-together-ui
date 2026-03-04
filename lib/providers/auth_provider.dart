import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exceptions.dart';
import '../core/storage/secure_storage.dart';
import '../data/api/auth_api.dart';
import '../data/dto/dtos.dart';
import 'achievement_provider.dart';
import 'calendar_provider.dart';
import 'chore_provider.dart';
import 'core_providers.dart';
import 'household_provider.dart';

/// Authentication state.
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final UserDto? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    UserDto? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApi _authApi;
  final SecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._authApi, this._storage, this._ref)
      : super(const AuthState());

  /// Check if we have a valid stored token on app start.
  Future<void> checkAuthStatus() async {
    final hasToken = await _storage.hasValidToken;
    if (hasToken) {
      final userId = await _storage.userId;
      final email = await _storage.userEmail;
      final displayName = await _storage.userDisplayName;
      state = AuthState(
        isAuthenticated: true,
        user: userId != null
            ? UserDto(id: userId, email: email, displayName: displayName)
            : null,
      );
    }
  }

  /// Login with email + password.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.login(
        LoginDto(email: email, password: password),
      );
      await _saveSession(response);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Register a new account.
  Future<bool> register(
      String email, String displayName, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authApi.register(
        RegisterDto(email: email, displayName: displayName, password: password),
      );
      await _saveSession(response);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<void> _saveSession(AuthResponseDto response) async {
    await _storage.saveTokens(
      accessToken: response.accessToken!,
      refreshToken: response.refreshToken!,
      expiresAtUtc: response.expiresAtUtc,
    );
    await _storage.saveUser(
      id: response.user.id,
      email: response.user.email,
      displayName: response.user.displayName,
    );
    state = AuthState(isAuthenticated: true, user: response.user);
  }

  /// Logout: clear tokens, state, and all user-scoped providers.
  Future<void> logout() async {
    await _storage.clearAll();
    // Invalidate all providers that hold user-specific data so the next
    // user who logs in never sees stale state from the previous session.
    _ref.invalidate(householdProvider);
    _ref.invalidate(todayOccurrencesProvider);
    _ref.invalidate(upcomingOccurrencesProvider);
    _ref.invalidate(templateProvider);
    _ref.invalidate(calendarProvider);
    _ref.invalidate(achievementsProvider);
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
    ref,
  );
});
