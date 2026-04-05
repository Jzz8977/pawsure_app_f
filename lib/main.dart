import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart'; // 导入你刚才写的逻辑
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 读取状态：watch 会在状态改变时自动刷新 UI
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Auth 示例')),
      body: Center(
        child: authAsync.when(
          // 数据加载完成（包括 null 情况）
          data: (token) =>
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(token == null
                      ? '当前状态：未登录'
                      : '已登录！Token: $token'),
                  const SizedBox(height: 20),
                  if (token == null)
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).login(
                              'SECRET_TOKEN_123'),
                      child: const Text('点击登录'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => ref.read(authProvider.notifier).logout(),
                      child: const Text('退出登录'),
                    ),
                ],
              ),
          // 正在从 SharedPreferences 读取或正在登录中
          loading: () => const CircularProgressIndicator(),
          // 出错处理
          error: (err, stack) => Text('出错啦: $err'),
        ),
      ),
    );
  }
}
