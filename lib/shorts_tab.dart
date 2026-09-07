import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'pexels_service.dart';
import 'theme.dart';

class ShortsTab extends StatefulWidget {
  const ShortsTab({super.key});

  @override
  State<ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<ShortsTab> {
  List<PexelsVideoModel> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShorts();
  }

  Future<void> _loadShorts() async {
    setState(() => _isLoading = true);
    try {
      final videos = await PexelsService.fetchVideos(isShorts: true);
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadShorts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 100,
            child: const Center(child: Text('No Shorts available. Pull down to refresh.')),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShorts,
      child: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return ShortsPlayerItem(
            key: ValueKey(_videos[index].id),
            video: _videos[index],
            index: index,
          );
        },
      ),
    );
  }
}

class ShortsPlayerItem extends StatefulWidget {
  final PexelsVideoModel video;
  final int index;
  const ShortsPlayerItem({super.key, required this.video, required this.index});

  @override
  State<ShortsPlayerItem> createState() => _ShortsPlayerItemState();
}

class _ShortsPlayerItemState extends State<ShortsPlayerItem> {
  late VideoPlayerController _controller;
  bool _isLiked = false;
  late String _likesCount;

  @override
  void initState() {
    super.initState();
    final baseId = widget.video.id;
    _likesCount = '${((baseId % 900) + 100) / 10}k';

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCommentsDisabledBottomSheet() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final colors = Theme.of(context).appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.tileBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.comment_bank_outlined, color: onSurface.withOpacity(0.5), size: 40),
              const SizedBox(height: 12),
              Text(
                'Comments are turned off',
                style: TextStyle(
                  color: onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The creator has disabled comments for this video.',
                style: TextStyle(color: onSurface.withOpacity(0.5), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final handle = widget.video.userName.toLowerCase().replaceAll(' ', '_');

    return _controller.value.isInitialized
        ? Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),

              if (!_controller.value.isPlaying)
                const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      size: 80, color: Colors.white70),
                ),

              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Action Bar - Like Enabled & Comment Disabled Dialog
              Positioned(
                right: 16,
                bottom: 60,
                child: Column(
                  children: [
                    // Like Button (Working)
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() => _isLiked = !_isLiked);
                      },
                    ),
                    Text(
                      _likesCount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comment Button (Opens Disabled Alert Sheet)
                    IconButton(
                      icon: const Icon(
                        Icons.comment_rounded,
                        color: Colors.white70,
                        size: 30,
                      ),
                      onPressed: _showCommentsDisabledBottomSheet,
                    ),
                    const Text(
                      'Off',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Left Description Overlay
              Positioned(
                left: 16,
                right: 80,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '@$handle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Video by ${widget.video.userName} • Dynamic short reel content #viral #trending',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Progress Line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFFE0473C),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
            ],
          )
        : const Center(child: CircularProgressIndicator());
  }
}