class Validators {
  Validators._();

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return '请输入手机号';
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value)) return '手机号格式不正确';
    return null;
  }

  static String? required(String? value, [String? label]) {
    if (value == null || value.trim().isEmpty) return '${label ?? '此项'}不能为空';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) return '密码至少6位';
    return null;
  }
}
