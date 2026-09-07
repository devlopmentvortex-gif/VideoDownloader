import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class PexelsVideoModel {
  final String url;
  final String userName;
  final int id;
  final String image;
  final String title; // Unique Title field

  PexelsVideoModel({
    required this.url,
    required this.userName,
    required this.id,
    required this.image,
    required this.title,
  });
}

class PexelsService {
  static const String _apiKey = 'zqABO797XggqLXxb90St5u9YGKj9voQagayMZwybCzWAcospgIHs8IUi';

  static Future<List<PexelsVideoModel>> fetchVideos({
    required bool isShorts,
    String category = 'Trending',
  }) async {
    final orientation = isShorts ? 'portrait' : 'landscape';
    final randomPage = Random().nextInt(10) + 1;
    
    final endpoint = (category == 'Trending')
        ? 'https://api.pexels.com/videos/popular?orientation=$orientation&per_page=15&page=$randomPage'
        : 'https://api.pexels.com/videos/search?query=$category&orientation=$orientation&per_page=15&page=$randomPage';

    final response = await http.get(
      Uri.parse(endpoint),
      headers: {'Authorization': _apiKey},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List videos = data['videos'] ?? [];

      List<PexelsVideoModel> videoList = [];
      for (var v in videos) {
        final files = v['video_files'] as List;
        final userDict = v['user'] as Map<String, dynamic>?;
        final userName = userDict != null ? userDict['name'] as String? ?? 'Pexels Creator' : 'Pexels Creator';
        final videoId = v['id'] as int? ?? 0;
        final image = v['image'] as String? ?? '';
        final videoPageUrl = v['url'] as String? ?? '';

        // Extracting clean Title from Pexels Video Page URL
        String generatedTitle = '';
        if (videoPageUrl.isNotEmpty) {
          final uriPath = Uri.parse(videoPageUrl).pathSegments;
          if (uriPath.length >= 2) {
            final rawSlug = uriPath[uriPath.length - 2]; 
            final words = rawSlug.split('-').where((e) => int.tryParse(e) == null).toList();
            if (words.isNotEmpty) {
              generatedTitle = words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
            }
          }
        }
        
        if (generatedTitle.isEmpty) {
          generatedTitle = '$category Clip #${videoId.toString().substring(0, 3)}';
        }

        if (files.isNotEmpty) {
          final suitableFile = files.firstWhere(
            (file) => (file['height'] != null && file['height'] <= 1080) || file['quality'] == 'sd',
            orElse: () => files.reduce((curr, next) => 
              ((curr['height'] ?? 4000) < (next['height'] ?? 4000)) ? curr : next
            ),
          );
          
          videoList.add(
            PexelsVideoModel(
              url: suitableFile['link'] as String,
              userName: userName,
              id: videoId,
              image: image,
              title: generatedTitle,
            ),
          );
        }
      }
      return videoList;
    } else {
      throw Exception('Failed to load videos from Pexels');
    }
  }
}