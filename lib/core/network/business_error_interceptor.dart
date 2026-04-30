import 'package:dio/dio.dart';

/// 把后端 `{ success, code, message, content }` 这种"HTTP 200 但业务失败"的响应
/// 统一转成 [DioException]，让所有调用方只用 `on DioException catch (e)` 处理错误。
///
/// 成功判定（满足任一即视为成功）：
/// - `success == true`
/// - `code in [200, 10001]`（后端 10001 在部分接口表示成功）
class BusinessErrorInterceptor extends Interceptor {
  static const Set<int> _successCodes = {200, 10001};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (_isSuccess(data)) {
      handler.next(response);
      return;
    }

    final message = _extractMessage(data) ?? '请求失败';
    handler.reject(
      DioException.badResponse(
        statusCode: response.statusCode ?? 0,
        requestOptions: response.requestOptions,
        response: response,
      ).copyWith(
        type: DioExceptionType.badResponse,
        error: message,
        message: message,
      ),
      true,
    );
  }

  bool _isSuccess(dynamic data) {
    if (data is! Map) {
      // 非 JSON 响应交给业务层自行判断（比如二进制流），不视为失败
      return true;
    }
    if (data['success'] == true) return true;
    final code = data['code'];
    if (code is num) return _successCodes.contains(code.toInt());
    if (code is String) {
      final n = int.tryParse(code);
      if (n != null) return _successCodes.contains(n);
    }
    // 没有 code 字段则不拦截，交给业务层
    return code == null;
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final v = data['message'] ?? data['msg'] ?? data['errorMessage'];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
