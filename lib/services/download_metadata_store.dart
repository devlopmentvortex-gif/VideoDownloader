import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadRecord {
  final String filePath;
  final String platform;
  final String type;
  final String title;
  final String createdAt;

  DownloadRecord({
    required this.filePath,
    required this.platform,
    required this.type,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'platform': platform,
        'type': type,
        'title': title,
        'createdAt': createdAt,
      };

  factory DownloadRecord.fromJson(Map<String, dynamic> json) {
    return DownloadRecord(
      filePath: json['filePath'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class DownloadMetadataStore {
  static const _key = 'download_metadata_v1';

  static Future<List<DownloadRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((item) {
          try {
            return DownloadRecord.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<DownloadRecord>()
        .toList();
  }

  static Future<void> add(DownloadRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, raw);
  }

  static Future<void> removeByPath(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((item) {
      try {
        final json = jsonDecode(item) as Map<String, dynamic>;
        return json['filePath'] == filePath;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, raw);
  }
}
