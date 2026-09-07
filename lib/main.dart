import 'package:flutter/material.dart';
import 'package:multilingual/multilingual.dart';
import 'app_languages.dart';
import 'language_store.dart';
import 'splash_screen.dart';
import 'theme.dart';

// Asli bug ye tha: app_languages.dart me 19 language ka translation 'data'
// pehle se maujood tha, lekin MaterialApp kabhi Multilingual widget se
// wrap hi nahi hua tha — isliye .trans() aur MultilingualController.setLocale
// koi asar nahi dikhate the. Ab teeno cheez wire kar di:
// 1) Multilingual(languages: AppLanguages.data) root pe wrap
// 2) MaterialApp ko locale/localizationsDelegates/supportedLocales controller se
// 3) home MultilingualChild se wrap (isse hi rebuild trigger hota locale change pe)
void main() {
  runApp(MyApp());
}

// Note: yaha 'const' jaanbujh kar nahi lagaya — Multilingual package ki
// docs khud kehti hai const lagane se locale change pe screen rebuild nahi hoti.
class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.load();
    _restoreSavedLocale();
  }

  // Pehle se saved language (LanguageStore) restore — warna har app open
  // pe device locale ya default pe reset ho jaata.
  Future<void> _restoreSavedLocale() async {
    final code = await LanguageStore.getSavedCode();
    if (code == null) return;
    MultilingualController.setLocale(AppLanguages.localeFor(code));
  }

  @override
  Widget build(BuildContext context) {
    return Multilingual(
      languages: AppLanguages.data,
      builder: (context) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.mode,
          builder: (context, mode, _) {
            return MaterialApp(
              title: 'Video Downloader',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: mode,
              localizationsDelegates: MultilingualController.localizationsDelegates,
              supportedLocales: MultilingualController.supportedLocales,
              locale: MultilingualController.locale,
              home: MultilingualChild(
                builder: (context) => SplashScreen(),
              ),
            );
          },
        );
      },
    );
  }
}