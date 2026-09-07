import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadedMediaResult {
  final String directUrl;
  final String title;
  final String thumbnail;
  final bool isVideo;

  DownloadedMediaResult({
    required this.directUrl,
    required this.title,
    required this.thumbnail,
    required this.isVideo,
  });
}

class MediaDownloaderService {
  static final Dio _dio = Dio();

  static final List<String> _fallbackInstances = [
    'https://api.cobalt.tools',
    'https://cobalt.stream',
    'https://cobalt.qtf.si',
  ];

  static String _normalizeUrl(String inputUrl) {
    String url = inputUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);

      // 1. YouTube Shortener Fix
      if (url.contains('youtu.be/')) {
        final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        if (videoId != null && videoId.isNotEmpty) {
          return 'https://www.youtube.com/watch?v=$videoId';
        }
      }

      // 2. Instagram Cleanup (Remove extra track parameters ?igsh=...)
      if (url.contains('instagram.com')) {
        final cleanPath = uri.path;
        return 'https://www.instagram.com$cleanPath';
      }

      // 3. Pinterest Short Link Expand Cleanup
      if (url.contains('pin.it/')) {
        return url.split('?').first;
      }
    } catch (_) {}

    return url;
  }

  static Future<DownloadedMediaResult?> extractMediaUrl(String rawUrl) async {
    final String cleanUrl = _normalizeUrl(rawUrl);
    print("Processing Clean URL: $cleanUrl");

    List<String> instancesToTry = await _getLiveInstances();
    if (instancesToTry.isEmpty) instancesToTry = _fallbackInstances;

    for (String baseUrl in instancesToTry) {
      final String endpoint = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      final result = await _fetchFromCobalt(endpoint, cleanUrl);
      if (result != null) return result;
    }

    // Secondary YouTube Fallback
    if (cleanUrl.contains('youtube.com') || cleanUrl.contains('youtu.be')) {
      return await _fetchFromYoutubeInvidious(cleanUrl);
    }

    return null;
  }

  static Future<List<String>> _getLiveInstances() async {
    try {
      final response = await http
          .get(Uri.parse('https://instances.hyper.space/instances.json'))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .where((item) => item['api'] != null && item['online'] == true)
            .map((item) => item['api'].toString())
            .toList();
      }
    } catch (_) {}
    return _fallbackInstances;
  }

  static Future<DownloadedMediaResult?> _fetchFromCobalt(
      String baseUrl, String socialUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Origin': 'https://cobalt.tools',
              'Referer': 'https://cobalt.tools/',
            },
            body: jsonEncode({
              'url': socialUrl,
              'videoQuality': '720',
              'downloadMode': 'auto',
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? downloadUrl;

        if (data['status'] == 'tunnel' || data['status'] == 'redirect') {
          downloadUrl = data['url'];
        } else if (data['status'] == 'picker' &&
            data['picker'] != null &&
            data['picker'].isNotEmpty) {
          downloadUrl = data['picker'][0]['url'];
        }

        if (downloadUrl != null) {
          final isVideo = downloadUrl.contains('.mp4') ||
              (data['filename'] ?? '').endsWith('.mp4');
          return DownloadedMediaResult(
            directUrl: downloadUrl,
            title: data['filename'] ?? 'Downloaded Media',
            thumbnail: '',
            isVideo: isVideo,
          );
        }
      }
    } catch (e) {
      print("Failed instance $baseUrl: $e");
    }
    return null;
  }

  static Future<DownloadedMediaResult?> _fetchFromYoutubeInvidious(
      String youtubeUrl) async {
    try {
      final uri = Uri.parse(youtubeUrl);
      String? videoId = uri.queryParameters['v'];
      if (videoId == null || videoId.isEmpty) return null;

      final response = await http
          .get(Uri.parse('https://inv.tux.pizza/api/v1/videos/$videoId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final formatStreams = data['formatStreams'] as List?;
        if (formatStreams != null && formatStreams.isNotEmpty) {
          final stream = formatStreams.last;
          return DownloadedMediaResult(
            directUrl: stream['url'],
            title: data['title'] ?? 'YouTube Video',
            thumbnail: data['videoThumbnails']?[0]['url'] ?? '',
            isVideo: true,
          );
        }
      }
    } catch (e) {
      print("Invidious fallback error: $e");
    }
    return null;
  }

  static Future<File?> downloadFile({
    required String downloadUrl,
    required String fileName,
    required Function(int received, int total) onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: onProgress,
      );

      return File(filePath);
    } catch (e) {
      print("Download Exception: $e");
      return null;
    }
  }
}