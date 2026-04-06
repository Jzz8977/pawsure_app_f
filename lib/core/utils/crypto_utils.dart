import 'package:encrypt/encrypt.dart';

/// AES-ECB-PKCS7 加解密工具
///
/// 与小程序保持一致：
///   mode    = ECB
///   padding = PKCS7
///   key     = '0abcd-123:PawSure-2025:123-abcd0' (UTF-8, 32 bytes → AES-256)
///   output  = Base64
class CryptoUtils {
  CryptoUtils._();

  static const _keyStr = '0abcd-123:PawSure-2025:123-abcd0';

  static final _key = Key.fromUtf8(_keyStr);
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.ecb));

  /// 加密 → Base64
  static String aesEncrypt(String text) {
    final encrypted = _encrypter.encrypt(text);
    return encrypted.base64;
  }

  /// Base64 → 解密
  static String aesDecrypt(String base64Text) {
    return _encrypter.decrypt64(base64Text);
  }
}
