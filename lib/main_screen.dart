import 'package:flutter/material.dart';
import 'theme.dart';
import 'home_tab.dart';
import 'shorts_tab.dart';
import 'watch_tab.dart';
import 'downloads_tab.dart';

// Abhi ke liye body blank hai — sirf bottom nav bar functional hai
// (tap karke tab switch hota, har tab ka content Container() empty hai).
// Baad me har tab ka real content yaha _pages[index] me daal dena.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItem(this.label, this.icon, this.selectedIcon);
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  final _downloadsKey = GlobalKey<DownloadsTabState>();

  static const _items = [
    _NavItem('Home', Icons.home_outlined, Icons.home_rounded),
    _NavItem('Shorts', Icons.bolt_outlined, Icons.bolt_rounded),
    _NavItem('Watch Videos', Icons.smart_display_outlined, Icons.smart_display_rounded),
    _NavItem('Downloads', Icons.download_outlined, Icons.download_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      // Home aur Downloads ab real UI hai — Shorts/Watch Videos abhi
      // blank hi rakhe (jaisa pehle sab tha), baad me unka content daalna.
      body: IndexedStack(
        index: _index,
        children: [
          const HomeTab(),
          const ShortsTab(),
          const WatchTab(),
          DownloadsTab(key: _downloadsKey),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Theme.of(context).appColors.divider)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < _items.length; i++)
                _navButton(_items[i], i, onSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(_NavItem item, int i, Color onSurface) {
    final selected = _index == i;
    final color = selected ? kAccent : onSurface.withOpacity(0.45);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _index = i);
        if (i == 3) _downloadsKey.currentState?.reload();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? item.selectedIcon : item.icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}