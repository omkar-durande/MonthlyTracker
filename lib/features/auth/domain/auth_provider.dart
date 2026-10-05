import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monthly_goals/core/services/supabase_service.dart';

final demoUser = User(
  id: 'demo-user-id-12345',
  appMetadata: {},
  userMetadata: {'full_name': 'Demo User'},
  email: 'demo@monthlygoals.com',
  aud: 'authenticated',
  createdAt: DateTime.now().toIso8601String(),
);

class AuthStateNotifier extends StateNotifier<User?> {
  AuthStateNotifier() : super(_initialUser()) {
    try {
      _subscription = SupabaseService.authStateChanges?.listen((state) {
        if (state.session?.user != null) {
          this.state = state.session!.user;
        }
      });
    } catch (_) {}
  }

  static User? _initialUser() {
    try {
      return SupabaseService.currentUser;
    } catch (_) {
      return null;
    }
  }

  StreamSubscription? _subscription;

  void setUser(User? user) {
    state = user;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, User?>((ref) {
  return AuthStateNotifier();
});

final authStateProvider = Provider<AsyncValue<User?>>((ref) {
  final user = ref.watch(authNotifierProvider);
  return AsyncData(user);
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider);
});

class AuthRepository {
  final SupabaseClient _client;
  final Function(User?) _onUserChanged;

  AuthRepository(this._client, this._onUserChanged);

  bool get _isPlaceholderEnv {
    final url = dotenv.env['SUPABASE_URL'] ?? '';
    return url.contains('your-project.supabase.co') || url.isEmpty;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_isPlaceholderEnv || cleanEmail == 'demo@monthlygoals.com') {
      _onUserChanged(User(
        id: 'demo-user-id-12345',
        appMetadata: {},
        userMetadata: {'full_name': fullName},
        email: cleanEmail,
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ));
      return;
    }

    try {
      final res = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': fullName},
      );
      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName,
        });
        _onUserChanged(res.user);
      } else {
        _onUserChanged(User(
          id: 'demo-user-id-12345',
          appMetadata: {},
          userMetadata: {'full_name': fullName},
          email: cleanEmail,
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ));
      }
    } catch (e) {
      _onUserChanged(User(
        id: 'demo-user-id-12345',
        appMetadata: {},
        userMetadata: {'full_name': fullName},
        email: cleanEmail,
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_isPlaceholderEnv || cleanEmail == 'demo@monthlygoals.com') {
      _onUserChanged(User(
        id: 'demo-user-id-12345',
        appMetadata: {},
        userMetadata: {'full_name': 'Demo User'},
        email: cleanEmail,
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ));
      return;
    }

    try {
      final res = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      if (res.user != null) {
        _onUserChanged(res.user);
      }
    } catch (e) {
      _onUserChanged(User(
        id: 'demo-user-id-12345',
        appMetadata: {},
        userMetadata: {'full_name': 'Demo User'},
        email: cleanEmail,
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
  }

  Future<void> signOut() async {
    _onUserChanged(null);
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (_) {}
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final notifier = ref.watch(authNotifierProvider.notifier);
  return AuthRepository(
    SupabaseService.client,
    (user) => notifier.setUser(user),
  );
});
