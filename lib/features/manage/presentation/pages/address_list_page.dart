import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/footer_bar.dart';

// ── 地址模型 ──────────────────────────────────────────────────────

class AddressModel {
  final String id;
  final String contactName;
  final String contactPhone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final int isDefault;

  const AddressModel({
    required this.id,
    required this.contactName,
    required this.contactPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id']?.toString() ?? '',
        contactName: json['contactName'] as String? ?? '',
        contactPhone: json['contactPhone'] as String? ?? '',
        province: json['province'] as String? ?? '',
        city: json['city'] as String? ?? '',
        district: json['district'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        isDefault: (json['isDefault'] as num?)?.toInt() ?? 0,
      );
}

// ── Page ─────────────────────────────────────────────────────────

class AddressListPage extends ConsumerStatefulWidget {
  const AddressListPage({super.key});

  @override
  ConsumerState<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends ConsumerState<AddressListPage> {
  List<AddressModel> _list = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post(AddressApi.list, data: {});
      final data = res.data as Map<String, dynamic>?;
      final success = data?['success'] == true || data?['code'] == 200;
      if (success && mounted) {
        final raw = data?['content'] as List<dynamic>? ?? [];
        setState(() {
          _list = raw
              .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
      // errors handled by interceptor
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAdd() async {
    await context.push('/address-edit');
    if (mounted) _loadList();
  }

  Future<void> _onEdit(String id) async {
    await context.push('/address-edit?id=$id');
    if (mounted) _loadList();
  }

  Future<void> _onDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除该地址吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final res =
          await ref.read(dioProvider).post(AddressApi.delete, data: {'id': id});
      final data = res.data as Map<String, dynamic>?;
      if ((data?['success'] == true || data?['code'] == 200) && mounted) {
        _showToast('删除成功');
        _loadList();
      }
    } catch (_) {}
  }

  Future<void> _onSetDefault(String id) async {
    try {
      final res = await ref
          .read(dioProvider)
          .post(AddressApi.setDefault, data: {'id': id});
      final data = res.data as Map<String, dynamic>?;
      if ((data?['success'] == true || data?['code'] == 200) && mounted) {
        _showToast('已设为默认');
        _loadList();
      }
    } catch (_) {}
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppNavBar(title: '收货地址', showBack: true),
      bottomNavigationBar: FooterBar(
        buttonText: '新增地址',
        onButtonTap: _onAdd,
      ),
      body: RefreshIndicator(
        onRefresh: _loadList,
        child: _loading && _list.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _list.length,
                    itemBuilder: (_, i) => _buildCard(_list[i]),
                  ),
      ),
    );
  }

  // ── 空状态 ──────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(
          children: const [
            Icon(Icons.location_off_outlined, size: 80, color: Color(0xFFD1D5DB)),
            SizedBox(height: 16),
            Text(
              '暂无收货地址',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
            ),
            SizedBox(height: 8),
            Text(
              '添加一个地址，方便服务上门或物品寄送',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  // ── 地址卡片 ────────────────────────────────────────────────────

  Widget _buildCard(AddressModel addr) {
    final isDefault = addr.isDefault == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(13, 17, 13, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：姓名 + 电话 + 地址 + 箭头
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _onEdit(addr.id),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            addr.contactName,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFF333333)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            addr.contactPhone,
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${addr.province}${addr.city}${addr.district}${addr.detail}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),

          // 分割线
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFE9E9E9)),
          ),

          // 底部：默认 + 删除
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isDefault ? null : () => _onSetDefault(addr.id),
                  child: isDefault
                      ? const Text(
                          '已设为默认',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFFFF9E4A)),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFD8D8D8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '默认地址',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF333333)),
                            ),
                          ],
                        ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _onDelete(addr.id),
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline,
                          size: 14, color: Color(0xFF666666)),
                      SizedBox(width: 4),
                      Text('删除',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF666666))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
