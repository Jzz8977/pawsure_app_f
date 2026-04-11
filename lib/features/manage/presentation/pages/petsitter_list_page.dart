import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

class PetsitterListPage extends ConsumerStatefulWidget {
  const PetsitterListPage({super.key});

  @override
  ConsumerState<PetsitterListPage> createState() => _PetsitterListPageState();
}

class _PetsitterListPageState extends ConsumerState<PetsitterListPage> {
  bool _loading = false;
  List<Map<String, dynamic>> _applications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(PetsitterApi.queryApplication);
      final content = res.data['content'];
      if (content is List) {
        setState(() {
          _applications = content.map<Map<String, dynamic>>((e) {
            return _normalizeItem(Map<String, dynamic>.from(e as Map));
          }).toList();
        });
      }
    } catch (_) {
      // ignore network errors
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _normalizeItem(Map<String, dynamic> item) {
    return {
      ...item,
      'statusText': _statusText(item['auditStatus']),
      'applicantTypeText': item['applicantType'] == 2 ? '商家申请' : '个人申请',
      'applyTime': _formatTime(item['applyTime']),
    };
  }

  String _statusText(dynamic status) {
    const map = {'-1': '草稿', '0': '待审核', '1': '通过', '2': '拒绝', '3': '已撤销'};
    return map[(status ?? -1).toString()] ?? '未知';
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--';
    final d = DateTime.tryParse(value.toString().replaceAll('-', '/'));
    if (d == null) return value.toString();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _onWithdraw(dynamic id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('撤销确认'),
        content: const Text('确定要撤销这条申请吗？撤销后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('再想想')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF6B6B)),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.post('${PetsitterApi.withdrawApplication}/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('撤销成功')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('撤销失败，请重试')));
        _load();
      }
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 1: return const Color(0xFF52C41A);
      case 0: return const Color(0xFFFF9E4A);
      case 2: return const Color(0xFFFF4D4F);
      default: return const Color(0xFF999999);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '成为陪伴师', showDivider: true),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _applications.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _applications.length,
                          itemBuilder: (ctx, i) => _buildCard(_applications[i]),
                        ),
                      ),
          ),
          FooterBar(
            buttonText: '发起新的申请',
            onButtonTap: () => context.push('/petsitter-application'),
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
          Icon(Icons.article_outlined, size: 80, color: Color(0xFFCCCCCC)),
          SizedBox(height: 16),
          Text('暂无申请记录', style: TextStyle(fontSize: 16, color: Color(0xFF666666))),
          SizedBox(height: 8),
          Text('点击下方按钮发起新的陪伴师申请', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final auditStatus = (item['auditStatus'] ?? -1) as int;
    final statusText = item['statusText'] as String;
    final statusColor = _statusColor(auditStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
                              item['serviceName']?.toString() ?? '未命名',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item['serviceType'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              item['serviceType'].toString(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _metaRow('申请角色：', item['applicantTypeText']?.toString() ?? ''),
                      const SizedBox(height: 4),
                      _metaRow('提交时间：', item['applyTime']?.toString() ?? '--'),
                      if (auditStatus == 2 && (item['auditRemark']?.toString().isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        _metaRow('拒绝原因：', item['auditRemark'].toString()),
                      ],
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
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                  ),
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
                _buildAction(item, auditStatus),
                GestureDetector(
                  onTap: () => context.push('/petsitter-application?id=${item['id']}&mode=view'),
                  child: Row(
                    children: const [
                      Text('查看详情', style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16, color: Color(0xFF999999)),
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

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF666666)))),
      ],
    );
  }

  Widget _buildAction(Map<String, dynamic> item, int auditStatus) {
    if (auditStatus == -1 || auditStatus == 2) {
      return GestureDetector(
        onTap: () => context.push('/petsitter-application?id=${item['id']}'),
        child: const Text('继续申请', style: TextStyle(fontSize: 14, color: Color(0xFFFF9E4A), fontWeight: FontWeight.w500)),
      );
    } else if (auditStatus == 0) {
      return GestureDetector(
        onTap: () => _onWithdraw(item['id']),
        child: const Text('撤销申请', style: TextStyle(fontSize: 14, color: Color(0xFFFF4D4F), fontWeight: FontWeight.w500)),
      );
    } else {
      return const Text('已通过审核', style: TextStyle(fontSize: 14, color: Color(0xFF52C41A)));
    }
  }
}
