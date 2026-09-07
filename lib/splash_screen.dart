import 'package:flutter/material.dart';
import 'theme.dart';
import 'permission_screen.dart';
import 'main_screen.dart';
import 'language_store.dart';

// App khulte hi 1st screen — logo center, ~2 sec baad route decide.
// Pehli baar (ya onboarding kabhi complete nahi hui) → PermissionScreen
// se pura flow. Onboarding pehle se complete → seedha MainScreen
// (bottom nav), Permission/Privacy/Language/Onboarding/Home dobara nahi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final done = await LanguageStore.isOnboardingComplete();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => done ? const MainScreen() : const PermissionScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Colors.white, size: 60),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: kAccent),
          ],
        ),
      ),
    );
  }
}