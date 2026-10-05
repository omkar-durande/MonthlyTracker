import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Supabase client accessor.
class SupabaseService {
  SupabaseService._();

  static const String _defaultUrl = 'https://fqpywbugsvjofozmkwvv.supabase.co';
  static const String _defaultAnonKey = 'sb_publishable_XnGlqB6Kw8DN4_SzmrRLIw_0J79FyiB';

  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'] ?? _defaultUrl;
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? _defaultAnonKey;

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
      );
    } catch (_) {
      // Supabase already initialized or fallback
    }
  }

  static SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      try {
        Supabase.initialize(
          url: _defaultUrl,
          // ignore: deprecated_member_use
          anonKey: _defaultAnonKey,
        );
        return Supabase.instance.client;
      } catch (_) {
        return Supabase.instance.client;
      }
    }
  }

  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get currentUserId => currentUser?.id;

  static Stream<AuthState>? get authStateChanges {
    try {
      return client.auth.onAuthStateChange;
    } catch (_) {
      return null;
    }
  }
}
