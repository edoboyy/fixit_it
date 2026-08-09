import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  SupabaseClient get client {
    _ensureInitialized();
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'Supabase not configured. Set URL + anon key in lib/supabase/supabase_config.dart',
        );
      }
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );

    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Supabase is not set up. Open lib/supabase/supabase_config.dart, '
        'paste your Project URL and anon key, then run supabase/schema.sql.',
      );
    }
  }
}
