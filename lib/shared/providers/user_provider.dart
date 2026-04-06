import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/storage/secure_storage.dart';

// ── 角色枚举 ───────────────────────────────────────────────────

enum UserRole { petOwner, provider }

// ── UserModel ─────────────────────────────────────────────────
//
// 字段对应服务端 /api/id/customer/detailCustomerInfo 的 content 对象：
//
//  phone          → AES 加密后的手机号
//  displayPhone   → 脱敏手机号，如 "152****6230"
//  name           → 用户昵称
//  avatar         → COS 对象 Key（上传路径）
//  avatarUrl      → COS 签名 CDN 地址（有效期约 30 min，展示用）
//  birthday       → "yyyy-MM-dd"
//  isIdCertified  → 实名认证："1" = 已认证
//  isBusCertified → 业务认证："1" = 已认证
//  sex            → 1=男, 2=女, 0=未知
//  status         → 账号状态，1=正常
//  vipExpireTime  → VIP 到期时间，null=非会员
//  roleIdA/B      → 角色权限 ID
//  userType       → "customer" | "provider"

class UserModel {
  final String id;
  final String name;
  final String phone;          // AES 加密
  final String displayPhone;   // 脱敏手机号
  final UserRole role;
  final String? avatar;        // COS Key
  final String? avatarUrl;     // CDN 签名地址（展示用）
  final String? birthday;
  final bool isIdCertified;
  final bool isBusCertified;
  final int sex;               // 1=男 2=女 0=未知
  final int status;
  final String? vipExpireTime;
  final int roleIdA;
  final int roleIdB;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.displayPhone,
    required this.role,
    this.avatar,
    this.avatarUrl,
    this.birthday,
    this.isIdCertified = false,
    this.isBusCertified = false,
    this.sex = 0,
    this.status = 1,
    this.vipExpireTime,
    this.roleIdA = 0,
    this.roleIdB = 0,
  });

  /// 从服务端 content 对象构建，rawPhone 为用户输入的明文手机号
  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String rawPhone = '',
  }) {
    final userType = json['userType'] as String? ?? 'customer';
    return UserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? rawPhone,
      displayPhone: json['displayPhone'] as String? ??
          _maskPhone(rawPhone),
      role: userType == 'provider' ? UserRole.provider : UserRole.petOwner,
      avatar: json['avatar'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      birthday: json['birthday'] as String?,
      isIdCertified: _parseBool(json['isIdCertified']),
      isBusCertified: _parseBool(json['isBusCertified']),
      sex: (json['sex'] as num?)?.toInt() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 1,
      vipExpireTime: json['vipExpireTime'] as String?,
      roleIdA: (json['roleIdA'] as num?)?.toInt() ?? 0,
      roleIdB: (json['roleIdB'] as num?)?.toInt() ?? 0,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? displayPhone,
    UserRole? role,
    String? avatar,
    String? avatarUrl,
    String? birthday,
    bool? isIdCertified,
    bool? isBusCertified,
    int? sex,
    int? status,
    String? vipExpireTime,
    int? roleIdA,
    int? roleIdB,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      displayPhone: displayPhone ?? this.displayPhone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthday: birthday ?? this.birthday,
      isIdCertified: isIdCertified ?? this.isIdCertified,
      isBusCertified: isBusCertified ?? this.isBusCertified,
      sex: sex ?? this.sex,
      status: status ?? this.status,
      vipExpireTime: vipExpireTime ?? this.vipExpireTime,
      roleIdA: roleIdA ?? this.roleIdA,
      roleIdB: roleIdB ?? this.roleIdB,
    );
  }

  @override
  String toString() =>
      'UserModel(id=$id, name=$name, displayPhone=$displayPhone, '
      'role=${role.name}, isIdCertified=$isIdCertified, '
      'isBusCertified=$isBusCertified, userType=${role.name})';

  // ── 私有工具 ────────────────────────────────────────────────

  static bool _parseBool(dynamic v) =>
      v == '1' || v == 1 || v == true;

  static String _maskPhone(String p) {
    if (p.length < 7) return p;
    return '${p.substring(0, 3)}****${p.substring(p.length - 4)}';
  }
}

// ── UserNotifier ──────────────────────────────────────────────

class UserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    Future.microtask(_loadFromStorage);
    return null;
  }

  // ── 冷启动恢复（读取持久化的关键字段）────────────────────────

  Future<void> _loadFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    final userId   = await storage.read(StorageKeys.userId);
    final roleStr  = await storage.read(StorageKeys.userRole);
    if (userId == null || roleStr == null) return;

    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.petOwner,
    );

    state = UserModel(
      id: userId,
      name: await storage.read(StorageKeys.userName) ?? '',
      phone: '',
      displayPhone: await storage.read(StorageKeys.displayPhone) ?? '',
      role: role,
      avatarUrl: await storage.read(StorageKeys.avatarUrl),
    );
  }

  // ── 登录（持久化关键字段）────────────────────────────────────

  Future<void> login(UserModel user) async {
    state = user;
    final storage = ref.read(secureStorageProvider);
    await Future.wait([
      storage.write(StorageKeys.userId,       user.id),
      storage.write(StorageKeys.userRole,     user.role.name),
      storage.write(StorageKeys.userName,     user.name),
      storage.write(StorageKeys.displayPhone, user.displayPhone),
      if (user.avatarUrl != null)
        storage.write(StorageKeys.avatarUrl, user.avatarUrl!),
    ]);
  }

  // ── 更新头像 CDN 地址（签名刷新后调用）──────────────────────

  void updateAvatarUrl(String url) {
    if (state == null) return;
    state = state!.copyWith(avatarUrl: url);
    ref.read(secureStorageProvider).write(StorageKeys.avatarUrl, url);
  }

  // ── 登出 ─────────────────────────────────────────────────────

  Future<void> logout() async {
    state = null;
    await ref.read(secureStorageProvider).deleteAll();
  }
}

final userNotifierProvider =
    NotifierProvider<UserNotifier, UserModel?>(UserNotifier.new);
