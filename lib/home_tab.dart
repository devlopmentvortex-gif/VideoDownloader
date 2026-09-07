import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multilingual/extensions.dart';
import 'theme.dart';
import 'ad_placement.dart';
import 'services/media_downloader_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _Social {
  final String labelKey;
  final String svgAsset;
  final Color color;
  final bool hasBakedBg;
  const _Social(this.labelKey, this.svgAsset, this.color, {this.hasBakedBg = false});
}

class _HomeTabState extends State<HomeTab> {
  final _controller = TextEditingController();
  bool _isExtracting = false;

  static const _socials = [
    _Social('social_facebook', 'assets/svgs/facebook.svg', Color(0xFF1877F2)),
    _Social('social_instagram', 'assets/svgs/instagram.svg', Color(0xFFE1306C), hasBakedBg: true),
    _Social('social_whatsapp', 'assets/svgs/whatsapp.svg', Color(0xFF25D366), hasBakedBg: true),
    _Social('social_pinterest', 'assets/svgs/pinterest.svg', Color(0xFFE60023)),
  ];

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;
    setState(() => _controller.text = data!.text!);
  }

  Future<void> _download() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('err_empty_url'.trans())),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isExtracting = true);

    DownloadedMediaResult? result;
    String errorKey = 'err_extract_failed';
    try {
      result = await MediaDownloaderService.extractMediaUrl(url);
    } on ExtractionFailure catch (e) {
      errorKey = e.messageKey;
    }

    setState(() => _isExtracting = false);

    if (result == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorKey.trans())),
      );
      return;
    }

    // 2. Start File Download with UI Loader
    if (!mounted) return;
    _showDownloadProgressDialog(result);
  }

  void _showDownloadProgressDialog(DownloadedMediaResult result) {
    double progress = 0.0;
    String progressText = '0%';
    bool isCompleted = false;
    bool isFailed = false;
    bool started = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            if (!started) {
              started = true;
              final fileName = MediaDownloaderService.safeFileName(
                platform: result.platform,
                extension: result.extension,
              );
              MediaDownloaderService.downloadFile(
                downloadUrl: result.directUrl,
                fileName: fileName,
                platform: result.platform,
                type: result.type,
                title: result.title,
                onProgress: (received, total) {
                  if (total > 0) {
                    final currentProgress = (received / total).clamp(0.0, 0.99);
                    setDialogState(() {
                      progress = currentProgress;
                      progressText = '${(currentProgress * 100).toStringAsFixed(0)}%';
                    });
                  }
                },
              ).then((file) {
                setDialogState(() {
                  if (file != null) {
                    progress = 1.0;
                    progressText = '100%';
                    isCompleted = true;
                  } else {
                    isFailed = true;
                  }
                });
              });
            }
            return AlertDialog(
              backgroundColor: Theme.of(context).appColors.tileBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isFailed
                    ? 'err_download_failed'.trans()
                    : (isCompleted ? 'download_complete'.trans() : 'downloading_media'.trans()),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompleted && !isFailed) ...[
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      color: kAccent,
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      progressText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ] else if (isFailed) ...[
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
                    const SizedBox(height: 8),
                    Text('err_download_failed'.trans()),
                  ] else ...[
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 50),
                    const SizedBox(height: 8),
                    Text('saved_to_device'.trans()),
                  ]
                ],
              ),
              actions: [
                if (isCompleted || isFailed)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isCompleted) _controller.clear();
                    },
                    child: const Text('OK', style: TextStyle(color: kAccent)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colors = Theme.of(context).appColors;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        children: [
          Text(
            'home_disclaimer'.trans(),
            style: const TextStyle(
                color: kAccent, fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.link_rounded, color: kAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: onSurface, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: 'link_hint'.trans(),
                      hintStyle: TextStyle(color: colors.hint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _paste,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.content_paste_rounded,
                        color: onSurface.withOpacity(0.7), size: 18),
                    label: Text('paste_btn'.trans(),
                        style: TextStyle(
                            color: onSurface.withOpacity(0.8), fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE0473C), Color(0xFFF7941D)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _isExtracting ? null : _download,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isExtracting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            else ...[
                              const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text('download_btn'.trans(),
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text('supported_socials'.trans(),
              style: TextStyle(
                  color: onSurface.withOpacity(0.5), fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 22,
            crossAxisSpacing: 12,
            childAspectRatio: 2.0,
            children: _socials
                .map((s) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        s.hasBakedBg
                            ? ClipOval(
                                child: SvgPicture.asset(
                                  s.svgAsset,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CircleAvatar(
                                radius: 22,
                                backgroundColor: s.color,
                                child: SvgPicture.asset(
                                  s.svgAsset,
                                  width: 22,
                                  height: 22,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.white, BlendMode.srcIn),
                                ),
                              ),
                        const SizedBox(height: 6),
                        Text(s.labelKey.trans(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: onSurface, fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Material(
              color: kAccent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('how_to_download'.trans(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const NativeAdPlacement(),
        ],
      ),
    );
  }
}