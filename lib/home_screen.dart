import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multilingual/extensions.dart';
import 'theme.dart';
import 'ad_placement.dart';
import 'language_store.dart';
import 'main_screen.dart';

// 5 step ek hi screen me: gender -> age -> category -> watch category ->
// interest. Har step ke subtitle ke neeche Ad space reserved hai. Last
// step (interest, min 3 max 5) ke Next pe MainScreen pe pushReplacement
// hota hai. Koi back navigation nahi (jaisa pehle se hai).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _Gender { female, male }

class _Option {
  final String key; // stable identity (radio value)
  final String labelKey; // .trans() key for display
  final IconData icon; // fallback / used by steps with no svg (age)
  final String? svgAsset; // when set, svg renders instead of icon
  // full "app icon" style svg (own bg baked in, e.g. insta/tiktok) vs
  // plain glyph-only svg (fb/twitter/download) — same distinction as
  // home_tab.dart's _Social.hasBakedBg.
  final bool hasBakedBg;
  final String? pngAsset; // raster (png/jpg) icon instead of svg — age options
  const _Option(this.key, this.labelKey, this.icon,
      {this.svgAsset, this.hasBakedBg = false, this.pngAsset});
}

class _OttOption {
  final String name;
  final String initials;
  final Color color;
  final String svgAsset;
  const _OttOption(this.name, this.initials, this.color, this.svgAsset);
}

class _HomeScreenState extends State<HomeScreen> {
  static const _totalSteps = 5; // 0..4
  static const _minInterest = 3;
  static const _maxInterest = 5;

  int _step = 0;

  _Gender? _gender;
  String? _age;
  String? _category;
  String? _watchCategory;
  final Set<String> _interests = {};

  final _ageOptions = const [
    _Option('18_24', 'age_18_24', Icons.groups_2_rounded,
        pngAsset: 'assets/svgs/18.png'),
    _Option('25_31', 'age_25_31', Icons.groups_rounded,
        pngAsset: 'assets/svgs/25.png'),
    _Option('32_39', 'age_32_39', Icons.people_alt_rounded,
        pngAsset: 'assets/svgs/35.png'),
    _Option('40_plus', 'age_40_plus', Icons.elderly_rounded,
        pngAsset: 'assets/svgs/40.png'),
  ];

  final _categoryOptions = const [
    _Option('all_video', 'cat_all_video', Icons.download_rounded,
        svgAsset: 'assets/svgs/download.svg', hasBakedBg: true),
    _Option('insta', 'cat_insta', Icons.camera_alt_rounded,
        svgAsset: 'assets/svgs/instagram.svg', hasBakedBg: true),
    _Option('fb', 'cat_fb', Icons.facebook_rounded,
        svgAsset: 'assets/svgs/facebook.svg', hasBakedBg: true),
    _Option('tiktok', 'cat_tiktok', Icons.music_note_rounded,
        svgAsset: 'assets/svgs/tiktok.svg', hasBakedBg: true),
    _Option('twitter', 'cat_twitter', Icons.alternate_email_rounded,
        svgAsset: 'assets/svgs/twitter.svg', hasBakedBg: true),
  ];

  final _ottOptions = const [
    _OttOption('Disney Hotstar', 'D+', Color(0xFF0B1F4B), 'assets/svgs/disney.svg'),
    _OttOption('Amazon Prime', 'PV', Color(0xFF00A8E1), 'assets/svgs/amazonprime.svg'),
    _OttOption('Sony Liv', 'SL', Color(0xFF6C1FB0), 'assets/svgs/sonyliv.svg'),
    _OttOption('Jio Cinema', 'JC', Color(0xFFE30B5C), 'assets/svgs/jiocinema.svg'),
    _OttOption('Apple TV+', 'TV', Colors.black, 'assets/svgs/appletv.svg'),
    _OttOption('Netflix', 'N', Color(0xFFE50914), 'assets/svgs/netflix.svg'),
  ];

  static const _adAfterOttIndex = 1; // 2 items ke baad ad (screenshot jaisa)

  final _interestOptions = const [
    'Action Movies',
    'Comedy Movies',
    'Romance',
    'Romantic Songs',
    'Football',
    'Basketball',
    'Cricket',
    'Travel',
    'Food & Cooking',
    'Couple Vlogs',
    'Cartoons',
    'Educational for kids',
    'Family Movies',
    'World News',
    'Local News',
    'Politics',
    'Gaming Videos',
    'Live Strams',
    'Walkthroughs',
  ];

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _gender != null;
      case 1:
        return _age != null;
      case 2:
        return _category != null;
      case 3:
        return _watchCategory != null;
      default:
        return _interests.length >= _minInterest;
    }
  }

  Future<void> _next() async {
    if (!_canGoNext) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    // sab 5 step complete — gender/age/category/watchCategory/interests
    // sab yaha available hai agar MainScreen ko pass karne ho.
    // Flag set: agli baar app open pe Splash seedha MainScreen bhejega,
    // pura Permission→Privacy→Language→Onboarding→Home flow dobara nahi.
    await LanguageStore.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _toggleInterest(String tag) {
    setState(() {
      if (_interests.contains(tag)) {
        _interests.remove(tag);
        return;
      }
      if (_interests.length >= _maxInterest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can select up to 5 interests only')),
        );
        return;
      }
      _interests.add(tag);
    });
  }

  Widget _genderCard(String labelKey, String imageAsset, _Gender value) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _gender = value),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).appColors.tileBg,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(imageAsset, fit: BoxFit.cover),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<_Gender>(
                  value: value,
                  groupValue: _gender,
                  activeColor: kAccent,
                  onChanged: (v) => setState(() => _gender = v),
                ),
                Text(labelKey.trans(),
                    style: TextStyle(
                        color: onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(_Option opt, String? groupValue, ValueChanged<String?> onChanged) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = opt.key == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(opt.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).appColors.tileBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? kAccent : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              opt.pngAsset != null
                  ? ClipOval(
                      child: Image.asset(
                        opt.pngAsset!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          color: kAccent.withOpacity(0.12),
                          child: Icon(opt.icon, color: kAccent, size: 22),
                        ),
                      ),
                    )
                  : opt.svgAsset == null
                  ? Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: kAccent.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt.icon, color: kAccent, size: 22),
                    )
                  : opt.hasBakedBg
                      ? ClipOval(
                          child: SvgPicture.asset(
                            opt.svgAsset!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kAccent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            opt.svgAsset!,
                            width: 22,
                            height: 22,
                            colorFilter:
                                const ColorFilter.mode(kAccent, BlendMode.srcIn),
                          ),
                        ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(opt.labelKey.trans(),
                    style: TextStyle(
                        color: onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Radio<String>(
                value: opt.key,
                groupValue: groupValue,
                activeColor: kAccent,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ottTile(_OttOption opt) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = opt.name == _watchCategory;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _watchCategory = opt.name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).appColors.tileBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? kAccent : Colors.transparent, width: 1.5),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 36,
                child: SvgPicture.asset(
                  opt.svgAsset,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(opt.name,
                    style: TextStyle(
                        color: onSurface, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Radio<String>(
                value: opt.name,
                groupValue: _watchCategory,
                activeColor: kAccent,
                onChanged: (v) => setState(() => _watchCategory = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _interestChip(String tag) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final selected = _interests.contains(tag);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => _toggleInterest(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? kAccent : Theme.of(context).appColors.tileBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: selected ? kAccent : Theme.of(context).appColors.divider, width: 1.2),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: selected ? Colors.white : onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _genderStep(Color onSurface) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text('personalized_title'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 8),
        Text('personalized_subtitle'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13.5)),
        const SizedBox(height: 16),
        const NativeAdPlacement(),
        Text('select_gender'.trans(),
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 20),
        Row(
          children: [
            _genderCard('gender_female', 'assets/svgs/female.png', _Gender.female),
            const SizedBox(width: 20),
            _genderCard('gender_male', 'assets/svgs/male.png', _Gender.male),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'gender_warning'.trans(),
                style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ageStep(Color onSurface) {
    return Column(
      children: [
        Text('select_age_range'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 6),
        Text('select_age_subtitle'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13.5)),
        const SizedBox(height: 14),
        const NativeAdPlacement(),
        ..._ageOptions.map((o) => _optionTile(o, _age, (v) => setState(() => _age = v))),
      ],
    );
  }

  Widget _categoryStep(Color onSurface) {
    return Column(
      children: [
        Text('select_category'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 6),
        Text('select_category_subtitle'.trans(),
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13.5)),
        const SizedBox(height: 14),
        const NativeAdPlacement(),
        ..._categoryOptions.map((o) => _optionTile(o, _category, (v) => setState(() => _category = v))),
      ],
    );
  }

  Widget _watchCategoryStep(Color onSurface) {
    return Column(
      children: [
        Text('Select Watch Category',
            textAlign: TextAlign.center,
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 6),
        Text('Select watch category to discover people or content that suits you best',
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13.5)),
        const SizedBox(height: 14),
        for (int i = 0; i < _ottOptions.length; i++) ...[
          _ottTile(_ottOptions[i]),
          if (i == _adAfterOttIndex) const NativeAdPlacement(),
        ],
      ],
    );
  }

  Widget _interestStep(Color onSurface) {
    return Column(
      children: [
        Text('What is your Interest?',
            textAlign: TextAlign.center,
            style: TextStyle(color: kAccent, fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 6),
        Text('Share your hobbies and interests to discover relevant content for you',
            textAlign: TextAlign.center,
            style: TextStyle(color: onSurface.withOpacity(0.6), fontSize: 13.5)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: _interestOptions.map(_interestChip).toList(),
        ),
        const SizedBox(height: 16),
        const NativeAdPlacement(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final Widget stepWidget;
    switch (_step) {
      case 0:
        stepWidget = _genderStep(onSurface);
        break;
      case 1:
        stepWidget = _ageStep(onSurface);
        break;
      case 2:
        stepWidget = _categoryStep(onSurface);
        break;
      case 3:
        stepWidget = _watchCategoryStep(onSurface);
        break;
      default:
        stepWidget = _interestStep(onSurface);
    }
    return Scaffold(
      // Back navigation nahi — koi AppBar/leading arrow kisi step pe nahi.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(child: stepWidget),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: _canGoNext
                          ? const [Color(0xFFE0473C), Color(0xFFF7941D)]
                          : [kAccent.withOpacity(0.4), const Color(0xFFF7941D).withOpacity(0.4)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _next,
                      child: Center(
                        child: Text('next_btn'.trans(),
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