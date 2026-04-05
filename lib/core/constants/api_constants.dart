class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.pawsure.com/v1';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // 登录相关路径（响应拦截器据此判断是否需要提取 token）
  static const List<String> loginPaths = [
    '/auth/login',
    '/auth/login/phone',
  ];

  // 服务端在响应 Header 中携带 token 的字段名
  static const String accessTokenHeader = 'x-access-token';
  static const String refreshTokenHeader = 'x-refresh-token';
}
