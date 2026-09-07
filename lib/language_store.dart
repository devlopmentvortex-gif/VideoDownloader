import 'package:shared_preferences/shared_preferences.dart';

// Chuna hua language code persist karta hai â€” Multilingual package khud
// app restart ke baad locale yaad nahi rakhta, isliye apna store zaroori
// (theme.dart ke ThemeController jaisa hi pattern).
class LanguageStore {
  static const _key = 'app_locale_code';
  static const _onboardKey = 'onboarding_complete';

  static Future<String?> getSavedCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
  }

  // Permission→Privacy→Language→Onboarding→Home 5-step, sab ek baar
  // complete hone ke baad true — Splash isko check karke seedha
  // MainScreen bhej deta, dobara pura flow nahi dikhata.
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardKey) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardKey, true);
  }
}