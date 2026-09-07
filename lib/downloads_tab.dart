import 'dart:io';
import 'package:flutter/material.dart';
import 'package:multilingual/extensions.dart';
import 'package:path_provider/path_provider.dart';
import 'theme.dart';
import 'ad_placement.dart';

class DownloadsTab extends StatefulWidget {
  const DownloadsTab({super.key});

  @override
  State<DownloadsTab> createState() => _DownloadsTabState();
}

enum _MediaType { photos, video }

class _DownloadsTabState extends State<DownloadsTab> {
  static const _platformKeys = [
    'social_whatsapp',
    'social_instagram',
    'social_facebook',
    'social_pinterest',
  ];
  
  int _platformIndex = 0;
  _MediaType _type = _MediaType.photos;
  
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalFiles();
  }

  Future<void> _loadLocalFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      if (await dir.exists()) {
        final List<FileSystemEntity> files = dir.listSync();
        setState(() {
          _downloadedFiles = files.where((file) {
            final path = file.path.toLowerCase();
            return path.endsWith('.mp4') || path.endsWith('.jpg') || path.endsWith('.png');
          }).toList();
        });
      }
    } catch (e) {
      // Handle read errors gracefully
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<FileSystemEntity> get _filteredFiles {
    return _downloadedFiles.where((file) {
      final isVideo = file.path.toLowerCase().endsWith('.mp4');
      return _type == _MediaType.video ? isVideo : !isVideo;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colors = Theme.of(context).appColors;
    final activeFiles = _filteredFiles;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'downloads_title'.trans(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
          
          // Platform Tabs Bar
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _platformKeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 22),
              itemBuilder: (context, i) {
                final selected = i == _platformIndex;
                return InkWell(
                  onTap: () => setState(() => _platformIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _platformKeys[i].trans(),
                        style: TextStyle(
                          color: selected ? kAccent : onSurface.withOpacity(0.5),
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(height: 2, width: 30, color: selected ? kAccent : Colors.transparent),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: colors.divider),
          
          // Media Type Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _typeChip('media_photos'.trans(), _MediaType.photos, onSurface, colors),
                const SizedBox(width: 12),
                _typeChip('media_video'.trans(), _MediaType.video, onSurface, colors),
              ],
            ),
          ),

          // Local Storage Grid View / Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAccent))
                : activeFiles.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadLocalFiles,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 350,
                            child: _buildEmptyState(onSurface, colors),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLocalFiles,
                        color: kAccent,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: activeFiles.length,
                          itemBuilder: (context, index) {
                            final file = activeFiles[index];
                            final isVideo = file.path.toLowerCase().endsWith('.mp4');

                            return Container(
                              decoration: BoxDecoration(
                                color: colors.tileBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colors.divider),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (!isVideo)
                                    Image.file(
                                      File(file.path),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Icon(Icons.broken_image, color: onSurface.withOpacity(0.3)),
                                    )
                                  else
                                    Container(
                                      color: Colors.black87,
                                      child: const Icon(
                                        Icons.video_library_rounded,
                                        color: Colors.white54,
                                        size: 32,
                                      ),
                                    ),
                                  
                                  // Video Play Overlay Badge
                                  if (isVideo)
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),

                                  // Delete Action
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          await file.delete();
                                          _loadLocalFiles();
                                        } catch (_) {}
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: NativeAdPlacement(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color onSurface, AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.search_rounded, size: 110, color: onSurface.withOpacity(0.15)),
              Positioned(
                bottom: 26,
                child: Text(
                  '404',
                  style: TextStyle(
                    color: onSurface.withOpacity(0.28),
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'downloads_empty'.trans(),
            style: TextStyle(color: onSurface.withOpacity(0.4), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, _MediaType type, Color onSurface, AppColors colors) {
    final selected = _type == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _type = type),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? kAccent.withOpacity(0.12) : Colors.transparent,
            border: Border.all(color: selected ? kAccent : colors.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? kAccent : onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}