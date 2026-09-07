import 'package:flutter/material.dart';
import 'package:multilingual/extensions.dart';
import 'theme.dart';
import 'language_screen.dart';

// Permission ke baad 3rd screen — policy text + checkbox, "Agree & Next"
// tabhi enable jab checkbox ticked. Sab text .trans() se.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _agreed = false;

  void _agreeAndNext() {
    if (!_agreed) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LanguageScreen(isFirstLaunch: true)),
    );
  }

  Widget _section(BuildContext context, String titleKey, String bodyKey) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleKey.trans(),
              style: TextStyle(
                  color: onSurface, fontWeight: FontWeight.w700, fontSize: 14.5)),
          const SizedBox(height: 6),
          Text(bodyKey.trans(),
              style: TextStyle(color: onSurface.withOpacity(0.75), fontSize: 13.5, height: 1.4)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('privacy_title'.trans(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  Text(
                    'privacy_intro'.trans(),
                    style: TextStyle(color: onSurface.withOpacity(0.8), fontSize: 13.5, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  _section(context, 'privacy_notif_title', 'privacy_notif_body'),
                  _section(context, 'privacy_photos_title', 'privacy_photos_body'),
                  _section(context, 'privacy_network_title', 'privacy_network_body'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    activeColor: kAccent,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                  Expanded(
                    child: Text('privacy_agree_checkbox'.trans(),
                        style: TextStyle(color: onSurface, fontSize: 13)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _agreed ? kAccent : kAccent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _agreed ? _agreeAndNext : null,
                  child: Text('agree_next'.trans(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}