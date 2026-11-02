import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // ── Replace these with your Supabase project keys ─────────────────────────
  // Found in Supabase Dashboard -> Project Settings -> API
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mtoudbilmsrbeqpthehr.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10b3VkYmlsbXNyYmVxcHRoZWhyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMDc1OTgsImV4cCI6MjEwODU4MzU5OH0.BMVtQHdAsC8Aa22rTt7QkVNRyuf6QZovDpE_el_Sk6g',
  );

  static bool get isConfigured =>
      url != 'https://placeholder.supabase.co' &&
      anonKey != 'placeholder-anon-key';

  static SupabaseClient get client => Supabase.instance.client;

  /// Call in main() to initialize Supabase
  static Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('[Supabase] Warning: Using placeholder keys. Set SUPABASE_URL and SUPABASE_ANON_KEY to connect.');
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      debugPrint('[Supabase] Initialized successfully with: $url');
    } catch (e) {
      debugPrint('[Supabase] Initialization error: $e');
    }
  }
}
