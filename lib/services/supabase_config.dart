// Holds your Supabase project's connection details.
// The "publishable key" is safe to ship in the app — it's the same
// idea as a public API key. It only works alongside your RLS
// policies (Step 2), which is what actually keeps data safe.
//
// IMPORTANT: If this repo is ever public, don't worry about this
// file being visible — RLS protects the data regardless. What you
// must NEVER put in the client app is your Supabase "service role"
// key — that one bypasses RLS completely and belongs only on a
// secure server, never in Flutter code.
class SupabaseConfig {
  static const String url = 'https://wtzoszozevnljfhiykpj.supabase.co';
  static const String publishableKey = 'sb_publishable_l7pEwFOoHevpBenKzzOldA_Ze31pNuN';
}