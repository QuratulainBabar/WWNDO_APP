import '../core/config/api_config.dart';

/// Parses API `photos: [{ id, url }]` (or relative `/uploads/...`) into absolute URLs.
List<String> parsePhotoUrls(dynamic raw) {
  if (raw is! List) return const [];
  final urls = <String>[];
  for (final item in raw) {
    String? path;
    if (item is Map) {
      path = item['url']?.toString() ?? item['file_path']?.toString();
    } else if (item is String) {
      path = item;
    }
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) continue;
    urls.add(ApiConfig.resolveUploadUrl(trimmed));
  }
  return urls;
}
