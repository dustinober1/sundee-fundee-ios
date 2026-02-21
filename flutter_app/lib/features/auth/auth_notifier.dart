import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/providers/supabase_provider.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isAuthenticated;
  final String? userEmail;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isAuthenticated = false,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isAuthenticated,
    String? userEmail,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage, // intentionally nullable to clear errors
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        userEmail: userEmail ?? this.userEmail,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final supabase = ref.watch(supabaseClientProvider);
    if (supabase == null) return const AuthState();

    final session = supabase.auth.currentSession;
    return AuthState(
      isAuthenticated: session != null,
      userEmail: session?.user.email,
    );
  }

  /// Sign in with email and password. Returns true on success.
  Future<bool> signIn(String email, String password) async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase is not configured.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: response.session != null,
        userEmail: response.user?.email,
        errorMessage: null,
      );
      return response.session != null;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  /// Create a new account with email and password. Returns true on success.
  Future<bool> signUp(String email, String password) async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Supabase is not configured.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      // session is non-null when email confirmation is not required
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: response.session != null,
        userEmail: response.user?.email,
        errorMessage: null,
      );
      return response.user != null;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred.',
      );
      return false;
    }
  }

  /// Sign out the current user and reset auth state.
  Future<void> signOut() async {
    final supabase = ref.read(supabaseClientProvider);
    if (supabase == null) return;

    await supabase.auth.signOut();
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
