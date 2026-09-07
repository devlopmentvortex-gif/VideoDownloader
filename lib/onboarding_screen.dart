import 'package:flutter/material.dart';
import 'package:multilingual/extensions.dart';
import 'theme.dart';
import 'home_screen.dart';

// Language ke baad tutorial/onboarding — 3 page swipe. Titles/subtitles
// ab .trans() keys se (onboard_title_1..3 / onboard_sub_1..3).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  final IconData icon;
  final String imageAsset;
  final String titleKey;
  final String subtitleKey;
  const _OnboardingPage(this.icon, this.imageAsset, this.titleKey, this.subtitleKey);
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    // page 1: 4K downloader
    _OnboardingPage(Icons.favorite_rounded, 'assets/svgs/onboarding1.png',
        'onboard_title_1', 'onboard_sub_1'),
    // page 2: Paste & Download
    _OnboardingPage(Icons.link_rounded, 'assets/svgs/onboarding2.png',
        'onboard_title_2', 'onboard_sub_2'),
    // page 3: 3x Faster Download
    _OnboardingPage(Icons.speed_rounded, 'assets/svgs/onboarding3.png',
        'onboard_title_3', 'onboard_sub_3'),
  ];

  void _next() {
    if (_index == _pages.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 280,
                          child: Image.asset(
                            p.imageAsset,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(p.titleKey.trans(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: kAccent,
                                fontWeight: FontWeight.w700,
                                fontSize: 19)),
                        const SizedBox(height: 8),
                        Text(p.subtitleKey.trans(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: onSurface.withOpacity(0.7), fontSize: 14)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? kAccent : kAccent.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  Material(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _next,
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.arrow_forward_rounded,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}