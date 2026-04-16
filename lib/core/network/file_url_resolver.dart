import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// 批量将 COS fileId（格式 `1:bucket:region:path`）解析为可访问 URL。
/// 调用后端 POST /api/lib/file/getLink，body: { keyList: [...] }
/// 后端 content 可能是 List（与入参同序）或 Map<fileId, url>。
/// 返回 { fileId: url } 映射，失败时返回空 Map。
Future<Map<String, String>> resolveFileUrls(
  Dio dio,
  List<String> fileIds,
) async {
  final keys = fileIds.where((k) => k.isNotEmpty).toSet().toList();
  if (keys.isEmpty) return {};
  try {
    final res = await dio.post(FileApi.getLink, data: {'keyList': keys});
    final content = (res.data as Map<String, dynamic>?)?['content'];
    final result = <String, String>{};
    if (content is List) {
      for (var i = 0; i < keys.length && i < content.length; i++) {
        final v = content[i];
        if (v != null && v.toString().isNotEmpty) result[keys[i]] = v.toString();
      }
    } else if (content is Map) {
      content.forEach((k, v) {
        if (k != null && v != null && v.toString().isNotEmpty) {
          result[k.toString()] = v.toString();
        }
      });
    }
    return result;
  } catch (_) {
    return {};
  }
}
