import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'pexels_service.dart';
import 'theme.dart';

class WatchTab extends StatefulWidget {
  const WatchTab({super.key});

  @override
  State<WatchTab> createState() => _WatchTabState();
}

class _WatchTabState extends State<WatchTab> {
  final List<String> _categories = [
    'Trending',
    'Food',
    'Music',
    'Entertainment',
    'Dance',
    'Sports',
    'News',
    'Gaming',
    'Nature'
  ];

  String _selectedCategory = 'Trending';
  List<PexelsVideoModel> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryVideos(_selectedCategory);
  }

  Future<void> _fetchCategoryVideos(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      final videos = await PexelsService.fetchVideos(
        isShorts: false,
        category: category,
      );
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colors = Theme.of(context).appColors;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea( // Status bar ke neeche shift karne ke liye
        child: Column(
          children: [
            // Top Horizontal Category Filter Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (cat != _selectedCategory) {
                          _fetchCategoryVideos(cat);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? kAccent : colors.tileBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : onSurface,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Video Feed
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE0473C),
                      ),
                    )
                  : _videos.isEmpty
                      ? Center(
                          child: Text(
                            'No videos found for $_selectedCategory',
                            style: TextStyle(color: onSurface.withOpacity(0.6)),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFE0473C),
                          backgroundColor: colors.tileBg,
                          onRefresh: () => _fetchCategoryVideos(_selectedCategory),
                          child: ListView.builder(
                            itemCount: _videos.length,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return WatchVideoCard(
                                key: ValueKey(_videos[index].id),
                                video: _videos[index],
                                category: _selectedCategory,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchVideoCard extends StatefulWidget {
  final PexelsVideoModel video;
  final String category;

  const WatchVideoCard({
    super.key,
    required this.video,
    required this.category,
  });

  @override
  State<WatchVideoCard> createState() => _WatchVideoCardState();
}

class _WatchVideoCardState extends State<WatchVideoCard> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  late String _views;

  @override
  void initState() {
    super.initState();
    final baseId = widget.video.id;
    _views = '${((baseId % 800) + 50)}k';
  }

  void _togglePlay() {
    if (_controller == null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _controller!.play();
              _isPlaying = true;
            });
          }
        });
    } else {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
          _isPlaying = false;
        } else {
          _controller!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colors = Theme.of(context).appColors;
    final handle = widget.video.userName.toLowerCase().replaceAll(' ', '_');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail / Video Container
          GestureDetector(
            onTap: _togglePlay,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    VideoPlayer(_controller!)
                  else
                    Image.network(
                      widget.video.image,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: colors.tileBg),
                    ),

                  // Play Button Overlay
                  if (!_isPlaying)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),

                  // Seek progress line during playback
                  if (_controller != null && _controller!.value.isInitialized)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFFE0473C),
                          bufferedColor: Colors.white24,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Metadata Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colors.tileBg,
                  child: Icon(Icons.person, color: onSurface.withOpacity(0.7), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$handle • $_views views • Popular in ${widget.category}',
                        style: TextStyle(
                          color: onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}