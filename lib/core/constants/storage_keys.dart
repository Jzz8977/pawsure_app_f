class StorageKeys {
  StorageKeys._();

  // ── Token
  static const String token  = 'token';
  static const String accessToken  = 'access_token';
  static const String refreshToken = 'refresh_token';

  // ── 用户基础（冷启动恢复，无需重新请求）
  static const String userId       = 'user_id';
  static const String userRole     = 'user_role';
  static const String userName     = 'user_name';
  static const String displayPhone = 'display_phone';
  static const String avatarUrl    = 'avatar_url';

  // ── 偏好设置
  static const String themeMode    = 'theme_mode';
  static const String locale       = 'locale';
}
