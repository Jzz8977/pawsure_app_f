import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/wechat/fluwx_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 提前注册微信 SDK；用 ProviderContainer 在 runApp 之前触发一次，
  // 之后用同一个 container 包到 ProviderScope，全局复用注册结果。
  final container = ProviderContainer();
  // 不 await：注册期间用户可以正常进入登录页，到达微信入口时 service 内部会再 await 一次
  // ignore: unawaited_futures
  container.read(fluwxRegisterFutureProvider.future);

  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
