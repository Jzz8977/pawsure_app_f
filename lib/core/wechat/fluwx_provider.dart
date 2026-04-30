import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluwx/fluwx.dart';

import '../constants/wechat_constants.dart';

/// 全局共享的 [Fluwx] 实例。
///
/// 真实初始化在 [fluwxRegisterFutureProvider] —— 通过 ProviderContainer 在
/// `main.dart` 启动时 await 一次，保证后续读取这个 provider 时 SDK 已 registerApi。
final fluwxProvider = Provider<Fluwx>((ref) => Fluwx());

/// 注册微信 SDK。返回 true 表示 registerApi 成功。
///
/// 若运行在不支持 fluwx 的平台（Web / Desktop），直接返回 false 而不抛错。
final fluwxRegisterFutureProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) {
    developer.log('[Fluwx] Web 平台跳过 registerApi', name: 'fluwx');
    return false;
  }
  if (!(defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android)) {
    developer.log('[Fluwx] 非 iOS / Android 平台跳过 registerApi', name: 'fluwx');
    return false;
  }

  final fluwx = ref.read(fluwxProvider);
  try {
    final ok = await fluwx.registerApi(
      appId: WeChatConstants.appId,
      universalLink: WeChatConstants.universalLink,
    );
    developer.log('[Fluwx] registerApi=$ok appId=${WeChatConstants.appId}',
        name: 'fluwx');
    return ok;
  } catch (e, st) {
    developer.log('[Fluwx] registerApi 异常: $e',
        name: 'fluwx', error: e, stackTrace: st);
    return false;
  }
});
