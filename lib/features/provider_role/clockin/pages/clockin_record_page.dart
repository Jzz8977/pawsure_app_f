import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

class ClockinRecordPage extends ConsumerStatefulWidget {
  final String? orderNo;

  const ClockinRecordPage({super.key, this.orderNo});

  @override
  ConsumerState<ClockinRecordPage> createState() => _ClockinRecordPageState();
}

class _ClockinRecordPageState extends ConsumerState<ClockinRecordPage> {
  bool _loading = false;
  bool _hasMore = true;
  int _pageNum = 1;
  List<Map<String, dynamic>> _records = [];

  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load(refresh: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loading && _hasMore) {
      _load();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    if (!refresh && !_hasMore) return;
    final pageNum = refresh ? 1 : _pageNum;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(CheckinApi.recordsQuery, data: {
        'orderNo': widget.orderNo ?? '',
        'page': pageNum,
        'pageSize': 20,
      });
      final data = res.data['content'];
      final rawRecords = (data is Map ? data['records'] : null) as List? ?? [];
      final total = (data is Map ? (data['total'] as num?)?.toInt() : 0) ?? 0;
      final items = rawRecords.map<Map<String, dynamic>>((e) =>
          _formatRecord(Map<String, dynamic>.from(e as Map))).toList();
      setState(() {
        _records = refresh ? items : [..._records, ...items];
        _pageNum = pageNum + 1;
        _hasMore = _records.length < total;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _formatRecord(Map<String, dynamic> r) {
    final time = (r['clientTime'] ?? r['serverTime'] ?? r['createdAt'] ?? '').toString();
    final isAbnormal = r['recordKind'] == 2;
    return {
      ...r,
      'dateStr': time.length >= 10 ? time.substring(0, 10) : '',
      'timeStr': time.length >= 16 ? time.substring(11, 16) : '',
      'isAbnormal': isAbnormal,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '打卡记录', showDivider: true),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              child: _records.isEmpty && !_loading
                  ? const Center(child: Text('暂无打卡记录', style: TextStyle(color: Color(0xFF999999))))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _records.length) {
                          if (_loading) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          if (!_hasMore && _records.isNotEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('没有更多了',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return _buildCard(_records[i]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final isAbnormal = r['isAbnormal'] as bool;
    final tagColor = isAbnormal ? const Color(0xFFFF4D4F) : const Color(0xFF52C41A);
    final isMakeup = r['isMakeup'] == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isAbnormal
            ? Border.all(color: const Color(0xFFFF4D4F).withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['dateStr']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333))),
                  Text(r['timeStr']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
              Row(
                children: [
                  if (isMakeup) ...[
                    _tag('补卡', const Color(0xFFFF9E4A)),
                    const SizedBox(width: 4),
                  ],
                  _tag(isAbnormal ? '异常上报' : '正常打卡', tagColor),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          if (!isAbnormal) ...[
            _infoRow('活动类型', r['activityTypeDesc']?.toString() ?? '--'),
            if ((r['moodDesc']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow('精神状态', r['moodDesc'].toString()),
            ],
          ] else ...[
            _infoRow('异常类型', r['exceptionTypeDesc']?.toString() ?? '--'),
            if ((r['measures']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              _infoRow('已采取措施', r['measures'].toString()),
            ],
            if ((r['exceptionDesc']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F0),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(r['exceptionDesc'].toString(),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text('$label：',
            style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)))),
      ],
    );
  }
}
