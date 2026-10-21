import 'package:shared_preferences/shared_preferences.dart';

// Remembers the user's language/state/district choice on this device,
// so a returning logged-in user can skip straight past onboarding
// instead of re-selecting it every time they open the app.
class SessionPrefs {
  SessionPrefs._();

  static const _keyLanguage = 'selected_language';
  static const _keyState = 'selected_state';
  static const _keyDistrict = 'selected_district';

  // Call this once the user finishes the onboarding selections.
  static Future<void> saveSelections({
    required String language,
    required String state,
    required String district,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
    await prefs.setString(_keyState, state);
    await prefs.setString(_keyDistrict, district);
  }

  // Returns null if any value is missing (e.g. first-ever launch).
  static Future<Map<String, String>?> loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_keyLanguage);
    final state = prefs.getString(_keyState);
    final district = prefs.getString(_keyDistrict);

    if (language == null || state == null || district == null) {
      return null;
    }

    return {'language': language, 'state': state, 'district': district};
  }

  // Call this on logout so the next login re-asks for preferences
  // (or you can skip this if you'd rather keep them for next login).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyState);
    await prefs.remove(_keyDistrict);
  }
}