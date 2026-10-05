import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized Supabase client accessor.
class SupabaseService {
  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fqpywbugsvjofozmkwvv.supabase.co',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_XnGlqB6Kw8DN4_SzmrRLIw_0J79FyiB',
  );

  static Future<void> initialize() async {
    String url = supabaseUrl;
    String anonKey = supabaseAnonKey;

    try {
      if (dotenv.isInitialized) {
        if (dotenv.env['SUPABASE_URL'] != null && dotenv.env['SUPABASE_URL']!.isNotEmpty) {
          url = dotenv.env['SUPABASE_URL']!;
        }
        if (dotenv.env['SUPABASE_ANON_KEY'] != null && dotenv.env['SUPABASE_ANON_KEY']!.isNotEmpty) {
          anonKey = dotenv.env['SUPABASE_ANON_KEY']!;
        }
      }
    } catch (_) {}

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
          url: supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: supabaseAnonKey,
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
