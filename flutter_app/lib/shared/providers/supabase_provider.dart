import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the SupabaseClient if initialized, null if optional sync is disabled.
/// Use this everywhere instead of Supabase.instance.client directly.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null; // Supabase.initialize() was not called
  }
});
