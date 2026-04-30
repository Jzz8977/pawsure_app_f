/// 微信开放平台配置（应用上线前替换为真实值）
///
/// - [appId]：微信开放平台 → 移动应用 → AppID
/// - [universalLink]：iOS 必填，需在自有域名下放置 apple-app-site-association 校验文件
/// - [scope]/[state]：发起 OAuth 授权时使用
class WeChatConstants {
  WeChatConstants._();

  /// TODO 替换为真实 AppID（形如 wxXXXXXXXXXXXXXXXX）
  static const String appId = 'wx0000000000000000';

  /// TODO 替换为真实 Universal Link（含末尾 /），iOS 必填
  static const String universalLink = 'https://www.jiaweiwei.top/uni/';

  /// 授权范围；移动应用一般使用 snsapi_userinfo
  static const String authScope = 'snsapi_userinfo';

  /// 防 CSRF；服务端登录接口可校验该值
  static const String authState = 'pawsure_login';
}
