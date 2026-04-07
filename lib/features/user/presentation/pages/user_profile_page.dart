import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/providers/user_provider.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key});

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  bool _saving = false;

  // ── 性别选择 ─────────────────────────────────────────────────
  void _onGenderTap() {
    final user = ref.read(userNotifierProvider);
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenderSheet(
        current: user.sex,
        onSelect: (sex) => _update({'sex': sex}),
      ),
    );
  }

  // ── 生日选择 ─────────────────────────────────────────────────
  void _onBirthdayTap() {
    final user = ref.read(userNotifierProvider);
    if (user == null) return;
    final initial = user.birthday != null
        ? DateTime.tryParse(user.birthday!) ?? DateTime(2000)
        : DateTime(2000);
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      locale: const Locale('zh'),
    ).then((date) {
      if (date == null) return;
      final s = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _update({'birthday': s});
    });
  }

  // ── 昵称编辑 ─────────────────────────────────────────────────
  void _onNameTap() {
    final user = ref.read(userNotifierProvider);
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NameSheet(
        current: user.name,
        onSave: (name) => _update({'name': name}),
      ),
    );
  }

  // ── 更新用户信息 ──────────────────────────────────────────────
  Future<void> _update(Map<String, dynamic> fields) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post(CustomerApi.editInfo, data: fields);
      // 重新拉取用户信息
      final res = await ref.read(dioProvider).post(CustomerApi.getInfo, data: {});
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      if (content != null && mounted) {
        final current = ref.read(userNotifierProvider);
        ref.read(userNotifierProvider.notifier).login(
          UserModel.fromJson(content, rawPhone: current?.phone ?? ''),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '个人资料'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头像 + 名字 + 认证 pill
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  _AvatarWidget(avatarUrl: user?.avatarUrl, sex: user?.sex ?? 0),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _onNameTap,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.name.isNotEmpty == true ? user!.name : '未设置昵称',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333)),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit_outlined,
                            size: 16, color: Color(0xFFAAAAAA)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.push('/identity-verification'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: user?.isIdCertified == true
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user?.isIdCertified == true
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFFC107),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user?.isIdCertified == true
                                ? Icons.verified
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: user?.isIdCertified == true
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFFC107),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.isIdCertified == true ? '已实名认证' : '未实名认证',
                            style: TextStyle(
                                fontSize: 12,
                                color: user?.isIdCertified == true
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFFFC107)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 信息列表
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _ProfileRow(
                    label: '性别',
                    value: _genderLabel(user?.sex),
                    onTap: _onGenderTap,
                  ),
                  const Divider(indent: 16, height: 1, color: Color(0xFFF0F0F0)),
                  _ProfileRow(
                    label: '生日',
                    value: user?.birthday ?? '未设置',
                    onTap: _onBirthdayTap,
                  ),
                  const Divider(indent: 16, height: 1, color: Color(0xFFF0F0F0)),
                  _ProfileRow(
                    label: '手机号',
                    value: user?.displayPhone ?? '未绑定',
                    onTap: () => context.push('/phone-change'),
                  ),
                  const Divider(indent: 16, height: 1, color: Color(0xFFF0F0F0)),
                  _ProfileRow(
                    label: '会员等级',
                    value: user?.vipExpireTime != null ? 'VIP 会员' : '普通用户',
                    highlight: user?.vipExpireTime != null,
                    onTap: () => context.push('/member-center'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _genderLabel(int? sex) {
    if (sex == 1) return '男';
    if (sex == 2) return '女';
    return '未设置';
  }
}

// ── 头像组件 ──────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final int sex;
  const _AvatarWidget({this.avatarUrl, required this.sex});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipOval(
          child: avatarUrl != null && avatarUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, err) => _defaultAvatar(),
                )
              : _defaultAvatar(),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7E51),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFF5F0EA),
      child: Icon(
        sex == 2 ? Icons.face_2 : Icons.face,
        size: 44,
        color: const Color(0xFFCCBBAA),
      ),
    );
  }
}

// ── 信息行 ────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onTap;
  const _ProfileRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333))),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14,
                      color: highlight
                          ? const Color(0xFFFF7E51)
                          : const Color(0xFF888888)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 13, color: Color(0xFFCCCCCC)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── 性别选择底部弹窗 ──────────────────────────────────────────────

class _GenderSheet extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;
  const _GenderSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('选择性别',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333))),
          ),
          const Divider(height: 1),
          _GenderOption(
              label: '男',
              selected: current == 1,
              onTap: () {
                Navigator.pop(context);
                onSelect(1);
              }),
          const Divider(height: 1, indent: 16),
          _GenderOption(
              label: '女',
              selected: current == 2,
              onTap: () {
                Navigator.pop(context);
                onSelect(2);
              }),
          const Divider(height: 1, indent: 16),
          _GenderOption(
              label: '不愿透露',
              selected: current == 0,
              onTap: () {
                Navigator.pop(context);
                onSelect(0);
              }),
          SizedBox(height: 8 + bottom),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderOption(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333))),
            if (selected)
              const Icon(Icons.check_rounded,
                  size: 20, color: Color(0xFFFF7E51)),
          ],
        ),
      ),
    );
  }
}

// ── 昵称编辑底部弹窗 ──────────────────────────────────────────────

class _NameSheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSave;
  const _NameSheet({required this.current, required this.onSave});

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              const Text('修改昵称',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    size: 20, color: Color(0xFF999999)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: '请输入昵称',
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final name = _ctrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context);
                widget.onSave(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E51),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('保存', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
