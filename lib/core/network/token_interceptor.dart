import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../constants/storage_keys.dart';
import '../constants/api_constants.dart';

class TokenInterceptor extends Interceptor {
  final Ref _ref;

  TokenInterceptor(this._ref);

  // ── 请求拦截：注入 Authorization Header ─────────────────────────
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(StorageKeys.accessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // ── 响应拦截：登录成功时从 Header 提取并持久化 token ─────────────
  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final path = response.requestOptions.path;
    final isLoginEndpoint =
        ApiConstants.loginPaths.any((p) => path.endsWith(p));

    if (isLoginEndpoint && _isSuccess(response.statusCode)) {
      await _extractAndStoreTokens(response);
    }

    // 直接透传完整响应，业务层自行处理 data
    handler.next(response);
  }

  // ── 错误拦截：401 时清理本地 token ──────────────────────────────
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: 可在此触发 refresh token 逻辑，当前直接清除
      _ref.read(secureStorageProvider).deleteAll();
    }
    handler.next(err);
  }

  // ── 私有工具方法 ────────────────────────────────────────────────
  bool _isSuccess(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  Future<void> _extractAndStoreTokens(Response response) async {
    final headers = response.headers;
    final storage = _ref.read(secureStorageProvider);

    // 读取 access token（header key 不区分大小写，dio 已统一转小写）
    final accessToken = headers.value(ApiConstants.accessTokenHeader);
    if (accessToken != null && accessToken.isNotEmpty) {
      await storage.write(StorageKeys.accessToken, accessToken);
    }

    // 读取 refresh token（如果服务端有返回）
    final refreshToken = headers.value(ApiConstants.refreshTokenHeader);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await storage.write(StorageKeys.refreshToken, refreshToken);
    }
  }
}
