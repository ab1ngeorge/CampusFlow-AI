/// Supabase configuration for CampusFlow AI.
///
/// Set [useSupabase] to `true` to use the live Supabase backend.
/// When `false`, the app falls back to local mock data (no internet needed).
class SupabaseConfig {
  // ── Toggle ────────────────────────────────────────────────────
  static const bool useSupabase = true;

  // ── Credentials ───────────────────────────────────────────────
  static const String supabaseUrl = 'https://xlvfopvxhcfneyutarat.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhsdmZvcHZ4aGNmbmV5dXRhcmF0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MjQ3ODEsImV4cCI6MjA4OTAwMDc4MX0.14eaU1vaR_cjJLtlOA_aVoJxh_W0rY9xckcQ4mJnb30';
}
