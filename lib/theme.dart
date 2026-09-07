import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// App ka accent color — flag avatar bg, selected radio, buttons sab yahi use karte.
const kAccent = Color(0xFFE0473C);

// Custom color tokens jo default ColorScheme me nahi hote (tile bg, divider,
// hint text, input fill, avatar bg) — Theme.of(context).appColors se access.
class AppColors extends ThemeExtension<AppColors> {
  final Color tileBg;
  final Color divider;
  final Color hint;
  final Color inputFill;
  final Color avatarBg;

  const AppColors({
    required this.tileBg,
    required this.divider,
    required this.hint,
    required this.inputFill,
    required this.avatarBg,
  });

  static const dark = AppColors(
    tileBg: Color(0xFF1C1C1E),
    divider: Color(0xFF2C2C2E),
    hint: Color(0xFF9A9A9E),
    inputFill: Color(0xFF1C1C1E),
    avatarBg: kAccent,
  );

  static const light = AppColors(
    tileBg: Color(0xFFF5F5F7),
    divider: Color(0xFFE2E2E5),
    hint: Color(0xFF6E6E73),
    inputFill: Color(0xFFF0F0F2),
    avatarBg: kAccent,
  );

  @override
  AppColors copyWith({
    Color? tileBg,
    Color? divider,
    Color? hint,
    Color? inputFill,
    Color? avatarBg,
  }) {
    return AppColors(
      tileBg: tileBg ?? this.tileBg,
      divider: divider ?? this.divider,
      hint: hint ?? this.hint,
      inputFill: inputFill ?? this.inputFill,
      avatarBg: avatarBg ?? this.avatarBg,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      tileBg: Color.lerp(tileBg, other.tileBg, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      avatarBg: Color.lerp(avatarBg, other.avatarBg, t)!,
    );
  }
}

// BUG jo tha: MaterialApp me (main.dart) plain ThemeData use ho raha hai,
// AppTheme.dark/light kabhi wire hi nahi hue — isliye extension<AppColors>()
// hamesha null aata tha aur pehle yaha hardcoded "?? AppColors.dark" fallback
// use ho raha tha. Result: light mode me bhi tileBg dark (1C1C1E) mil raha
// tha jabki text onSurface bhi dark (near-black) — dark text on dark bg =
// options screen pe kuch dikhta hi nahi tha.
// Fix: fallback ab current theme ke brightness ke hisaab se sahi AppColors
// deta hai, extension registered ho ya na ho, dono case me visible rahega.
extension AppColorsX on ThemeData {
  AppColors get appColors =>
      extension<AppColors>() ??
      (brightness == Brightness.dark ? AppColors.dark : AppColors.light);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F10),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F10),
          elevation: 0,
          centerTitle: false,
        ),
        // comment kiya — ye extension MaterialApp tak kabhi pohochta hi nahi
        // tha (main.dart alag ThemeData use kar raha hai), so removed to
        // avoid confusion. AppColorsX ka naya fallback isके bina bhi kaam karta hai.
        // extensions: const [AppColors.dark],
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          centerTitle: false,
        ),
        // extensions: const [AppColors.light], // same reason as above, commented
      );
}

// Dark/light mode persist — LanguageStore jaisa hi pattern, ThemeMode
// notifier taaki MaterialApp turant rebuild ho toggle karte hi.
class ThemeController {
  static const _key = 'app_dark_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false; // default light
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDark(bool isDark) async {
    mode.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}