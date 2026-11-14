// Supabase is used by the app ONLY for sign-in (and uploading files to signed
// URLs issued by our API). All data goes through the Samayam API.
//
// Override per environment at build time, e.g. for the local stack:
//   flutter run --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
//               --dart-define=SUPABASE_PUBLISHABLE_KEY=<local anon key> \
//               --dart-define=API_BASE_URL=http://127.0.0.1:4000
//
// The publishable key is safe to ship: the database grants it no access to app
// data. Never put the service-role key in the app.
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wtzoszozevnljfhiykpj.supabase.co',
  );
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_l7pEwFOoHevpBenKzzOldA_Ze31pNuN',
  );
}
