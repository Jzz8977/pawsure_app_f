import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

class ServiceManagePage extends ConsumerStatefulWidget {
  const ServiceManagePage({super.key});

  @override
  ConsumerState<ServiceManagePage> createState() => _ServiceManagePageState();
}

class _ServiceManagePageState extends ConsumerState<ServiceManagePage> {
  bool _loading = false;
  List<Map<String, dynamic>> _services = [];
  // dict maps for label display
  Map<String, String> _serviceTypeMap = {};
  Map<String, String> _petTypeMap = {};

  static const _auditStatusMap = {
    '-1': '草稿',
    '0':  '待审核',
    '1':  '已发布',
    '2':  '已下架',
    '3':  '已下架',
  };

  @override
  void initState() {
    super.initState();
    _initDicts().then((_) => _load());
  }

  Future<void> _initDicts() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(LibApi.dictBatchList,
          data: ['service_type', 'pet_species', 'pet_weight']);
      final content = res.data['content'];
      if (content is! Map) return;

      final stMap = <String, String>{};
      for (final e in (content['service_type'] as List? ?? [])) {
        final m = e as Map;
        stMap[m['key'].toString()] = (m['remark'] ?? m['value'] ?? '').toString();
      }
      final ptMap = <String, String>{};
      for (final e in (content['pet_species'] as List? ?? [])) {
        final m = e as Map;
        ptMap[m['key'].toString()] = m['value']?.toString() ?? '';
      }
      if (mounted) setState(() { _serviceTypeMap = stMap; _petTypeMap = ptMap; });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(ServicePublishApi.list, data: {});
      final content = res.data['content'];
      final rawList = content is List ? content : <dynamic>[];
      setState(() {
        _services = rawList.map<Map<String, dynamic>>((e) => _normalize(Map<String, dynamic>.from(e as Map))).toList();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> item) {
    final svcType = item['serviceType']?.toString() ?? '';
    final auditStatus = (item['auditStatus'] ?? -1) as int;
    final ptCodes = _splitCodes(item['petTypes']);
    return {
      ...item,
      'serviceTypeLabel': _serviceTypeMap[svcType] ?? svcType,
      'auditStatusLabel': _auditStatusMap[auditStatus.toString()] ?? '未知',
      'auditStatus': auditStatus,
      'petTypesLabel': ptCodes.map((c) => _petTypeMap[c] ?? c).toList(),
    };
  }

  List<String> _splitCodes(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return v.toString().split(',').where((s) => s.isNotEmpty).toList();
  }

  Future<void> _onUnpublish(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认下架'),
        content: const Text('确定要下架该服务吗？下架后用户将无法看到该服务。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9E4A)),
            child: const Text('下架'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(dioProvider).post(ServicePublishApi.unpublish, data: {'serviceId': id});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已下架'))); _load(); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下架失败')));
    }
  }

  Future<void> _onPublish(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认上架'),
        content: const Text('确定要上架该服务吗？上架后用户将可以看到该服务。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9E4A)),
            child: const Text('上架'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(dioProvider).post(ServicePublishApi.submit, data: {'serviceId': id});
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('上架成功'))); _load(); }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('上架失败')));
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1: return const Color(0xFF52C41A);
      case 0: return const Color(0xFFFF9E4A);
      default: return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '我的服务', showDivider: true),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          itemBuilder: (ctx, i) => _buildCard(_services[i]),
                        ),
                      ),
          ),
          FooterBar(
            buttonText: '发布新的服务',
            onButtonTap: () => context.push('/service-publish'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.miscellaneous_services_outlined, size: 80, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text('暂无发布记录', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
          SizedBox(height: 8),
          Text('点击下方按钮发布新的服务', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final auditStatus = item['auditStatus'] as int;
    final statusLabel = item['auditStatusLabel'] as String;
    final statusColor = _statusColor(auditStatus);
    final petTypeLabels = (item['petTypesLabel'] as List).join('、');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['serviceName']?.toString() ?? '--',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(item['serviceTypeLabel']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _meta('手机号：', item['phoneNumber']?.toString() ?? '未填写'),
                      const SizedBox(height: 4),
                      _meta('宠物类型：', petTypeLabels.isEmpty ? '未设置' : petTypeLabels),
                      const SizedBox(height: 4),
                      _meta('最大接待：', '${item['maxPetCount'] ?? 0} 只'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardAction(item, auditStatus),
                GestureDetector(
                  onTap: () async {
                    await context.push('/service-publish?action=edit&id=${item['id']}&mode=view');
                    _load();
                  },
                  child: Row(children: const [
                    Text('查看详情', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF999999)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF666666)))),
      ],
    );
  }

  Widget _buildCardAction(Map<String, dynamic> item, int auditStatus) {
    if (auditStatus == -1) {
      return GestureDetector(
        onTap: () async { await context.push('/service-publish?action=edit&id=${item['id']}'); _load(); },
        child: const Text('编辑', style: TextStyle(fontSize: 14, color: Color(0xFFFF9E4A), fontWeight: FontWeight.w500)),
      );
    } else if (auditStatus == 0) {
      return const Text('待审核', style: TextStyle(fontSize: 14, color: Color(0xFF999999)));
    } else if (auditStatus == 1) {
      return GestureDetector(
        onTap: () => _onUnpublish(item['id']),
        child: const Text('下架', style: TextStyle(fontSize: 14, color: Color(0xFFFF4D4F), fontWeight: FontWeight.w500)),
      );
    } else {
      // 2 or 3 – offline, can publish or edit
      return Row(
        children: [
          GestureDetector(
            onTap: () => _onPublish(item['id']),
            child: const Text('上架', style: TextStyle(fontSize: 14, color: Color(0xFFFF9E4A), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async { await context.push('/service-publish?action=edit&id=${item['id']}'); _load(); },
            child: const Text('编辑', style: TextStyle(fontSize: 14, color: Color(0xFFFF9E4A), fontWeight: FontWeight.w500)),
          ),
        ],
      );
    }
  }
}
