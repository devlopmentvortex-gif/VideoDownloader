import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
// import '../config/backend_config.dart'; // yt-dlp backend hata diya — ab RapidAPI/SaveFrom use hoga
import 'download_metadata_store.dart';

class ExtractionFailure implements Exception {
  final String code;
  final String messageKey;

  ExtractionFailure(this.code, this.messageKey);

  @override
  String toString() => code;
}

class DownloadedMediaResult {
  final String directUrl;
  final String title;
  final String thumbnail;
  final bool isVideo;
  final String platform;
  final String type;
  final String extension;

  DownloadedMediaResult({
    required this.directUrl,
    required this.title,
    required this.thumbnail,
    required this.isVideo,
    required this.platform,
    required this.type,
    required this.extension,
  });
}

class MediaDownloaderService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  static final Dio _downloadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  static const _errorKeys = {
    'INVALID_URL': 'err_invalid_url',
    'UNSUPPORTED_PLATFORM': 'err_unsupported_platform',
    'UNSUPPORTED_URL': 'err_unsupported_url',
    'PRIVATE_CONTENT': 'err_private_content',
    'LOGIN_REQUIRED': 'err_login_required',
    'MEDIA_NOT_FOUND': 'err_media_not_found',
    'EXTRACTION_FAILED': 'err_extract_failed',
    'TIMEOUT': 'err_timeout',
    'RATE_LIMITED': 'err_rate_limited',
    'SERVER_ERROR': 'err_server',
  };

  static String _normalizeUrl(String inputUrl) {
    String url = inputUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    try {
      final uri = Uri.parse(url);

      if (url.contains('instagram.com')) {
        final cleanPath = uri.path;
        return 'https://www.instagram.com$cleanPath';
      }

      if (url.contains('pin.it/')) {
        return url.split('?').first;
      }
    } catch (_) {}

    return url;
  }

  static String _extensionFor({
    required String type,
    required String mediaUrl,
  }) {
    final path = mediaUrl.split('?').first.toLowerCase();
    final known = ['.mp4', '.webm', '.mov', '.m4v', '.jpg', '.jpeg', '.png', '.webp', '.gif', '.mp3', '.m4a', '.aac'];
    for (final ext in known) {
      if (path.endsWith(ext)) {
        return ext == '.jpeg' ? 'jpg' : ext.substring(1);
      }
    }
    if (type == 'image') return 'jpg';
    if (type == 'audio') return 'mp3';
    return 'mp4';
  }

  static String safeFileName({
    required String platform,
    required String extension,
  }) {
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final safePlatform = platform.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    return '${safePlatform}_$stamp.$extension';
  }

  // ===================== YT-DLP BACKEND (COMMENTED — ab use nahi) =====================
  // static Future<DownloadedMediaResult?> extractMediaUrl(String rawUrl) async {
  //   final String cleanUrl = _normalizeUrl(rawUrl);
  //   final backendUrl = BackendConfig.baseUrl;
  //
  //   try {
  //     final response = await _dio.post(
  //       '$backendUrl/api/extract',
  //       data: {'url': cleanUrl},
  //     );
  //
  //     final data = response.data;
  //     if (data is! Map) {
  //       throw ExtractionFailure('EXTRACTION_FAILED', 'err_extract_failed');
  //     }
  //
  //     if (data['success'] != true) {
  //       final code = (data['error'] as String?) ?? 'EXTRACTION_FAILED';
  //       throw ExtractionFailure(code, _errorKeys[code] ?? 'err_extract_failed');
  //     }
  //
  //     return _mapResult(data);
  //   } on ExtractionFailure {
  //     rethrow;
  //   } on DioException catch (e) {
  //     throw _fromDio(e);
  //   } catch (_) {
  //     throw ExtractionFailure('EXTRACTION_FAILED', 'err_extract_failed');
  //   }
  // }

  // TODO: naya extractMediaUrl yaha likhna — SaveFrom/RapidAPI hit karega,
  // response ko _mapResult() ke expected shape (success/type/media_url/items/platform/title/thumbnail) me convert karna
  static Future<DownloadedMediaResult?> extractMediaUrl(String rawUrl) async {
    throw ExtractionFailure('EXTRACTION_FAILED', 'err_extract_failed');
  }
  // =======================================================================================

  static DownloadedMediaResult _mapResult(Map data) {
    var type = (data['type'] as String?) ?? 'video';
    String? mediaUrl = data['media_url'] as String?;
    final items = data['items'];

    if (type == 'carousel' && items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        mediaUrl = first['media_url'] as String? ?? mediaUrl;
        type = (first['type'] as String?) ?? 'video';
      }
    } else if ((mediaUrl == null || mediaUrl.isEmpty) && items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        mediaUrl = first['media_url'] as String?;
        type = (first['type'] as String?) ?? type;
      }
    }

    if (mediaUrl == null || mediaUrl.isEmpty) {
      throw ExtractionFailure('EXTRACTION_FAILED', 'err_extract_failed');
    }

    final platform = (data['platform'] as String?) ?? 'unknown';
    final title = (data['title'] as String?) ?? 'Downloaded Media';
    final thumbnail = (data['thumbnail'] as String?) ?? '';
    final isVideo = type == 'video' || type == 'audio';

    return DownloadedMediaResult(
      directUrl: mediaUrl,
      title: title,
      thumbnail: thumbnail,
      isVideo: isVideo,
      platform: platform,
      type: type,
      extension: _extensionFor(type: type, mediaUrl: mediaUrl),
    );
  }

  static ExtractionFailure _fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ExtractionFailure('TIMEOUT', 'err_timeout');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ExtractionFailure('SERVER_ERROR', 'err_offline');
    }
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      final code = data['error'] as String;
      return ExtractionFailure(code, _errorKeys[code] ?? 'err_extract_failed');
    }
    final status = e.response?.statusCode;
    if (status == 429) {
      return ExtractionFailure('RATE_LIMITED', 'err_rate_limited');
    }
    if (status == 504) {
      return ExtractionFailure('TIMEOUT', 'err_timeout');
    }
    return ExtractionFailure('SERVER_ERROR', 'err_offline');
  }

  static Future<File?> downloadFile({
    required String downloadUrl,
    required String fileName,
    required Function(int received, int total) onProgress,
    String? platform,
    String? type,
    String? title,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';

      final referers = {
        'pinterest': 'https://www.pinterest.com/',
        'instagram': 'https://www.instagram.com/',
        'facebook': 'https://www.facebook.com/',
        'whatsapp': 'https://www.whatsapp.com/',
      };
      await _downloadDio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: onProgress,
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': '*/*',
            'Referer': referers[platform] ?? 'https://www.google.com/',
          },
        ),
      );

      final file = File(filePath);
      if (!await file.exists()) return null;
      if (await file.length() <= 0) return null;

      await DownloadMetadataStore.add(
        DownloadRecord(
          filePath: filePath,
          platform: platform ?? 'unknown',
          type: type ?? (fileName.toLowerCase().endsWith('.mp4') ? 'video' : 'image'),
          title: title ?? fileName,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      return file;
    } catch (e) {
      return null;
    }
  }
}