/// Supabase config for Fixit GH.
/// Values from: Project Settings → API
class SupabaseConfig {
  SupabaseConfig._();

  static const bool isConfigured =
      supabaseUrl != 'YOUR_SUPABASE_URL' &&
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  static const String supabaseUrl = 'https://jedzwfiklfxbigbqjymt.supabase.co';

  /// anon / public key (JWT). Do not use the service_role key.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImplZHp3ZmlrbGZ4YmlnYnFqeW10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQwNDA4NTksImV4cCI6MjA5OTYxNjg1OX0.LC7OtmFFbNiAPgnlbtxY7_eGTcWpd3JlkCC1-ss3DY4';
}
