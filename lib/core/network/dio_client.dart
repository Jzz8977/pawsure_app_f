import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'business_error_interceptor.dart';
import 'token_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  // 顺序很关键：响应回来时按"添加顺序"依次执行 onResponse
  // 1) TokenInterceptor 先看登录响应，决定是否写 token
  // 2) BusinessErrorInterceptor 再校验业务 code，非成功则 reject 成 DioException
  dio.interceptors.add(TokenInterceptor(ref));
  dio.interceptors.add(BusinessErrorInterceptor());
  return dio;
});
