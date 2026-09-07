import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:multilingual/extensions.dart';
import 'package:lottie/lottie.dart';
import 'theme.dart';
import 'ad_placement.dart';
import 'privacy_policy_screen.dart';

// Screenshot jaisa hi — center title "Permission", illustration icon,
// "Read And Write Permission" heading + subtitle, Ad space, gradient
// "Allow Access" button full-width. Sab text .trans() keys se.
//
// FIX: pehle .request() list ka result kabhi check hi nahi ho raha tha —
// isliye chahe dialog show ho ya na ho, seedha next screen pe chala jaata
// tha (lagta tha "permission le hi nahi raha"). Ab har status check/log
// ho raha hai, aur agar "permanently denied" hai (already ek baar deny
// karke "don't ask again") toh app settings khulti hai next screen jaane
// se pehle.
//
// ⚠️ IMPORTANT — sirf Dart code se system dialog nahi khulega agar
// AndroidManifest.xml me permissions declare nahi hai. android/app/src/main/
// AndroidManifest.xml me <application> ke bahar ye add karo (agar already
// nahi hai):
//   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
//       android:maxSdkVersion="32"/>
// Aur android/app/build.gradle.kts me targetSdk >= 33 hona chahiye,
// warna Android photos/videos granular permission na maang ke seedha
// purane storage flow pe chala jaata hai (jo naye Android pe silently
// denied ho sakta hai bina dialog dikhaye).
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _allowAndContinue(BuildContext context) async {
    final permissions = [
      Permission.notification,
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ];

    final statuses = <Permission, PermissionStatus>{};
    for (final p in permissions) {
      // ek-ek karke request — batch request kabhi kabhi ek hi native
      // dialog show karke baaki sabko silently skip kar deta hai.
      statuses[p] = await p.request();
    }
    debugPrint('permission statuses: $statuses');

    final anyPermanentlyDenied =
        statuses.values.any((s) => s.isPermanentlyDenied);

    if (!context.mounted) return;

    if (anyPermanentlyDenied) {
      // "Don't ask again" already choose ho chuka — request() dobara
      // dialog nahi dikhayega, seedha app settings kholna padega.
      await openAppSettings();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('perm_title'.trans(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Lottie.asset(
                'assets/animations/AllowPermission.json',
                width: 220,
                height: 220,
                repeat: true,
              ),
              const SizedBox(height: 28),
              Text('perm_heading'.trans(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: onSurface, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 12),
              Text(
                'perm_subtitle'.trans(),
                textAlign: TextAlign.center,
                style: TextStyle(color: onSurface.withOpacity(0.65), fontSize: 13.5, height: 1.4),
              ),
              const Spacer(),
              const NativeAdPlacement(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE0473C), Color(0xFFF7941D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _allowAndContinue(context),
                      child: Center(
                        child: Text('allow_access'.trans(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}