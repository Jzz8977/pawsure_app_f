import 'dart:developer' as developer;

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
    final token = await storage.read(StorageKeys.token);
    if (token != null && token.isNotEmpty) {
      // 与小程序版保持一致：直接注入原始 token，不加 Bearer 前缀
      options.headers['Authorization'] = token;
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

    // 仅在 HTTP 200 且业务 code 为成功（200 / 10001）时才写 token
    if (isLoginEndpoint &&
        _isSuccess(response.statusCode) &&
        _isBusinessSuccess(response.data)) {
      await _extractAndStoreTokens(response);
    }

    // 直接透传完整响应，业务层自行处理 data
    handler.next(response);
  }

  /// 判断业务层是否成功（与 `BusinessErrorInterceptor` 同源逻辑）
  bool _isBusinessSuccess(dynamic data) {
    if (data is! Map) return false;
    final code = data['code'];
    final success = data['success'];
    if (success == true) return true;
    if (code is num) return code == 200 || code == 10001;
    if (code is String) return code == '200' || code == '10001';
    return false;
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

    // 后端在响应 header 中放 token = "Bearer eyJhbGc..."
    // ⚠️ Web 环境受 CORS 限制：必须在 Access-Control-Expose-Headers 里包含 token，否则读不到
    developer.log(
      '[Auth] 登录响应 headers keys=${headers.map.keys.toList()}',
      name: 'auth',
    );

    final rawToken = headers.value(ApiConstants.tokenHeader) ??
        headers.value('Token') ??
        headers.value('authorization') ??
        headers.value('Authorization');

    String? finalToken = rawToken;

    // header 拿不到（web 端 CORS 没暴露），尝试从 body 兜底
    if (finalToken == null || finalToken.isEmpty) {
      final body = response.data;
      if (body is Map) {
        final content = body['content'];
        final dataField = body['data'];
        if (content is Map && content['token'] is String) {
          finalToken = content['token'] as String;
        } else if (dataField is Map && dataField['token'] is String) {
          finalToken = dataField['token'] as String;
        } else if (body['token'] is String) {
          finalToken = body['token'] as String;
        }
      }
    }

    if (finalToken != null && finalToken.isNotEmpty) {
      // 完整保存（含 "Bearer " 前缀），下次请求时直接整段塞进 Authorization
      await storage.write(StorageKeys.token, finalToken);
      developer.log('[Auth] token 已保存（前 30 字符）: '
          '${finalToken.length > 30 ? finalToken.substring(0, 30) : finalToken}…',
          name: 'auth');
    } else {
      developer.log(
        '[Auth] 未能取到 token —— 检查后端 CORS 是否在 Access-Control-Expose-Headers 暴露 token，'
        '或将 token 同时放到 body.content.token',
        name: 'auth',
      );
    }

    // 读取 refresh token（如果服务端有返回）
    final refreshToken = headers.value(ApiConstants.refreshTokenHeader);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await storage.write(StorageKeys.refreshToken, refreshToken);
    }
  }
}
