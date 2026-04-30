import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluwx/fluwx.dart';

import '../constants/api_constants.dart';
import '../constants/wechat_constants.dart';
import '../network/dio_client.dart';
import '../../shared/providers/user_provider.dart';
import 'fluwx_provider.dart';

/// 微信登录结果
sealed class WeChatLoginResult {
  const WeChatLoginResult();
}

class WeChatLoginSuccess extends WeChatLoginResult {
  final UserModel user;
  const WeChatLoginSuccess(this.user);
}

class WeChatLoginCancelled extends WeChatLoginResult {
  const WeChatLoginCancelled();
}

class WeChatLoginNotInstalled extends WeChatLoginResult {
  const WeChatLoginNotInstalled();
}

class WeChatLoginUnsupported extends WeChatLoginResult {
  const WeChatLoginUnsupported();
}

class WeChatLoginFailed extends WeChatLoginResult {
  final String message;
  const WeChatLoginFailed(this.message);
}

/// 微信授权登录全流程：
/// 1. 调 fluwx 拉起微信授权
/// 2. 拿到 code 调后端 [AuthApi.wechatLogin] 换 token（token 由 TokenInterceptor 自动持久化）
/// 3. 调 [CustomerApi.getInfo] 拉用户信息并写入 [userNotifierProvider]
class WeChatLoginService {
  WeChatLoginService(this._ref);
  final Ref _ref;

  /// 单次授权超时（含跳转微信 / 用户操作时间）
  static const Duration _authTimeout = Duration(seconds: 60);

  Future<WeChatLoginResult> login() async {
    // 等 SDK 就绪
    final registered = await _ref.read(fluwxRegisterFutureProvider.future);
    if (!registered) {
      return const WeChatLoginUnsupported();
    }

    final fluwx = _ref.read(fluwxProvider);
    if (!await fluwx.isWeChatInstalled) {
      return const WeChatLoginNotInstalled();
    }

    // 监听一次回调
    final codeCompleter = Completer<WeChatAuthResponse>();
    late final FluwxCancelable cancelable;
    cancelable = fluwx.addSubscriber((resp) {
      if (resp is WeChatAuthResponse && !codeCompleter.isCompleted) {
        codeCompleter.complete(resp);
      }
    });

    try {
      final ok = await fluwx.authBy(
        which: NormalAuth(
          scope: WeChatConstants.authScope,
          state: WeChatConstants.authState,
        ),
      );
      if (!ok) {
        return const WeChatLoginFailed('调起微信失败');
      }

      final WeChatAuthResponse resp;
      try {
        resp = await codeCompleter.future.timeout(_authTimeout);
      } on TimeoutException {
        return const WeChatLoginFailed('授权超时，请重试');
      }

      developer.log(
        '[WeChatLogin] errCode=${resp.errCode} state=${resp.state} '
        'codeLen=${resp.code?.length ?? 0}',
        name: 'wechat',
      );

      // 微信错误码
      // 0 成功 / -2 用户取消 / -4 拒绝授权
      if (resp.errCode == -2 || resp.errCode == -4) {
        return const WeChatLoginCancelled();
      }
      if (resp.errCode != 0 || resp.code == null || resp.code!.isEmpty) {
        return WeChatLoginFailed(resp.errStr ?? '授权失败');
      }

      // ── 用 code 换 token ────────────────────────────────────
      return await _exchangeCodeForUser(resp.code!);
    } finally {
      cancelable.cancel();
    }
  }

  Future<WeChatLoginResult> _exchangeCodeForUser(String code) async {
    final dio = _ref.read(dioProvider);
    try {
      final res = await dio.post(
        AuthApi.wechatLogin,
        data: {'code': code},
      );
      final data = res.data;
      final success = data is Map &&
          (data['success'] == true ||
              data['code'] == 200 ||
              data['code'] == 10001);
      if (!success) {
        final msg = (data is Map ? data['message']?.toString() : null) ??
            '微信登录失败';
        return WeChatLoginFailed(msg);
      }
      // token 由 TokenInterceptor 写入；接着拉用户信息
      final user = await _fetchUser();
      if (user == null) {
        return const WeChatLoginFailed('登录成功但获取用户信息失败');
      }
      await _ref.read(userNotifierProvider.notifier).login(user);
      return WeChatLoginSuccess(user);
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response!.data as Map)['message']?.toString()
          : null;
      return WeChatLoginFailed(msg ?? '网络异常，请重试');
    } catch (e) {
      return WeChatLoginFailed(e.toString());
    }
  }

  Future<UserModel?> _fetchUser() async {
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.post(CustomerApi.getInfo);
      final data = res.data as Map<String, dynamic>?;
      final content =
          (data?['content'] as Map<String, dynamic>?) ?? data ?? const {};
      return UserModel.fromJson(content);
    } catch (e) {
      developer.log('[WeChatLogin] 拉取用户信息失败: $e', name: 'wechat', error: e);
      return null;
    }
  }
}

final wechatLoginServiceProvider =
    Provider<WeChatLoginService>((ref) => WeChatLoginService(ref));
