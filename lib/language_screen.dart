import 'package:flutter/material.dart';
import 'package:multilingual/multilingual.dart';
import 'package:multilingual/extensions.dart';
import 'app_languages.dart';
import 'language_store.dart';
// import 'native_ad_banner.dart';
import 'theme.dart';
// import 'permission_screen.dart';
import 'onboarding_screen.dart';
// import 'custom_tab_launcher.dart';

//
// Full-screen language selector — permission_screen ke "Language" block se
// khulti hai, aur app ke pehli baar open hone par bhi (isFirstLaunch: true)
// StartupDecider se seedha yahi khulti hai. List: flag + English name +
// native name + radio, niche ad banner placeholder fixed.
//
// isFirstLaunch: true hone par back button hide rehta hai (koi previous
// screen nahi hai) aur ek "Continue" button dikhta hai jo select kiye
// language ke saath seedha PermissionScreen pe le jaata hai.
class LanguageScreen extends StatefulWidget {
  final bool isFirstLaunch;
  const LanguageScreen({super.key, this.isFirstLaunch = false});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected = MultilingualController.locale.languageCode;

  Future<void> _select(String code) async {
    setState(() => _selected = code);
    await MultilingualController.setLocale(AppLanguages.localeFor(code));
    await LanguageStore.save(code);
  }

  Future<void> _confirmAndContinue() async {
    await LanguageStore.save(_selected);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: neeche list ke andar tile ka text hamesha hardcoded
    // Colors.white tha. Jab tile unselected hoti (tileBg = light gray/near-
    // white in light theme), white-on-white ki wajah se text invisible ho
    // jaata tha — sirf tap/hover ke waqt InkWell ka dark ripple overlay
    // pade toh thoda dikh jaata (isliye "hover pe hi text show hora tha").
    // Ab unselected state me onSurface (theme ke hisaab se dark/light)
    // use ho raha, selected state me white hi rahega kyunki bg kAccent hai.
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final scaffold = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isFirstLaunch,
        title: Text('select_language'.trans(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (widget.isFirstLaunch)
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _confirmAndContinue,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: AppLanguages.options.length,
              itemBuilder: (context, index) {
                final opt = AppLanguages.options[index];
                final selected = opt.code == _selected;
                final textColor = selected ? Colors.white : onSurface;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: selected ? kAccent : Theme.of(context).appColors.tileBg,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _select(opt.code),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.white.withOpacity(0.22)
                                    : kAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                opt.code.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                opt.nativeName,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // const NativeAdBanner(),
        ],
      ),
    );
    if (widget.isFirstLaunch) return scaffold;
    // return AdPopScope(child: scaffold);
    return scaffold;
  }
}