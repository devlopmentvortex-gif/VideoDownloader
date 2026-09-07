import 'package:flutter/material.dart';
import 'theme.dart';

// Native ad placement — real native ad SDK (AdMob NativeAd / etc.) yaha
// wire karna. Abhi same size/spacing/structure ka static placeholder hai
// taaki ad load hone se pehle/baad UI shift na ho. Isse har jagah use karo
// jaha pehle "Download Video Now" wala AdPlaceholderCard tha.
class NativeAdPlacement extends StatelessWidget {
  const NativeAdPlacement({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).appColors.tileBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // media view — native ad ka MediaContent/video yaha render hoga
              Container(
                height: 140,
                width: double.infinity,
                color: onSurface.withOpacity(0.06),
                alignment: Alignment.center,
                child: Icon(Icons.play_circle_fill_rounded,
                    size: 48, color: onSurface.withOpacity(0.35)),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Ad',
                      style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // native ad icon (NativeAd.icon)
                CircleAvatar(radius: 16, backgroundColor: kAccent.withOpacity(0.2)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // headline (NativeAd.headline)
                      Text('Sponsored Content',
                          style: TextStyle(
                              color: onSurface, fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      // ad attribution / advertiser (NativeAd.advertiser)
                      Text('Sponsored',
                          style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0473C), Color(0xFFF7941D)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: const Center(
                  // call-to-action (NativeAd.callToAction)
                  child: Text('INSTALL',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}