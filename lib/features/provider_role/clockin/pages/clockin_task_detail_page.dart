import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

const _statusMap = {
  'PENDING':     {'text': '待打卡',   'color': Color(0xFFFF9E4A)},
  'DONE_ON_TIME':{'text': '已完成',   'color': Color(0xFF52C41A)},
  'DONE_LATE':   {'text': '补卡完成', 'color': Color(0xFF52C41A)},
  'MISSED':      {'text': '已缺失',   'color': Color(0xFFFF4D4F)},
  'EXCUSED':     {'text': '已豁免',   'color': Color(0xFF999999)},
};

class ClockinTaskDetailPage extends ConsumerStatefulWidget {
  final String id;
  final String? orderNo;
  final String? orderId;
  final String? serviceType;
  final String? providerId;
  final String? customerId;
  final String? status;
  final String? planDate;
  final String? planHour;

  const ClockinTaskDetailPage({
    super.key,
    required this.id,
    this.orderNo,
    this.orderId,
    this.serviceType,
    this.providerId,
    this.customerId,
    this.status,
    this.planDate,
    this.planHour,
  });

  @override
  ConsumerState<ClockinTaskDetailPage> createState() => _ClockinTaskDetailPageState();
}

class _ClockinTaskDetailPageState extends ConsumerState<ClockinTaskDetailPage> {
  bool _loading = true;
  bool _hasRecord = false;
  Map<String, dynamic>? _record;

  String get _statusKey => (widget.status ?? 'PENDING').toUpperCase();
  bool get _canCheckin => _statusKey == 'PENDING';
  bool get _canMakeup => _statusKey == 'MISSED';

  @override
  void initState() {
    super.initState();
    if (widget.id.isNotEmpty) _loadTaskRecord();
  }

  Future<void> _loadTaskRecord() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(CheckinApi.taskRecord, data: {'taskId': int.tryParse(widget.id) ?? 0});
      final data = res.data['content'];
      if (data != null && data['id'] != null) {
        final time = (data['clientTime'] ?? data['serverTime'] ?? data['createdAt'] ?? '').toString();
        setState(() {
          _hasRecord = true;
          _record = {
            'activityTypeDesc': data['activityTypeDesc']?.toString() ?? '',
            'moodDesc': data['moodDesc']?.toString() ?? '',
            'checkinTypeDesc': data['checkinTypeDesc']?.toString() ?? '',
            'isMakeup': data['isMakeup'] == 1,
            'clientTime': time.length >= 16 ? time.substring(0, 16).replaceFirst('T', ' ') : '',
          };
        });
      } else {
        setState(() => _hasRecord = false);
      }
    } catch (_) {
      if (mounted) setState(() => _hasRecord = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goClockin() {
    final params = <String, String>{'orderNo': widget.orderNo ?? ''};
    if (widget.orderId?.isNotEmpty == true) params['orderId'] = widget.orderId!;
    if (widget.id.isNotEmpty) params['taskId'] = widget.id;
    if (widget.serviceType?.isNotEmpty == true) params['serviceType'] = widget.serviceType!;
    if (widget.providerId?.isNotEmpty == true) params['providerId'] = widget.providerId!;
    if (widget.customerId?.isNotEmpty == true) params['customerId'] = widget.customerId!;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    context.push('/clockin?$query');
  }

  @override
  Widget build(BuildContext context) {
    final info = _statusMap[_statusKey] ?? _statusMap['PENDING']!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '任务详情', showDivider: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Task info card
                  _infoCard('任务信息', [
                    if (widget.orderNo?.isNotEmpty == true)
                      _row('订单编号', widget.orderNo!),
                    if (widget.planDate?.isNotEmpty == true)
                      _row('计划日期', widget.planDate!),
                    if (widget.planHour?.isNotEmpty == true)
                      _row('计划时间', widget.planHour!),
                  ], trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (info['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(info['text'] as String,
                        style: TextStyle(fontSize: 12, color: info['color'] as Color, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                  else if (_hasRecord && _record != null)
                    _infoCard('打卡记录', [
                      if ((_record!['activityTypeDesc'] as String).isNotEmpty)
                        _row('活动类型', _record!['activityTypeDesc'] as String),
                      if ((_record!['moodDesc'] as String).isNotEmpty)
                        _row('精神状态', _record!['moodDesc'] as String),
                      if ((_record!['checkinTypeDesc'] as String).isNotEmpty)
                        _row('打卡类型', _record!['checkinTypeDesc'] as String),
                      if ((_record!['clientTime'] as String).isNotEmpty)
                        _row('完成时间', _record!['clientTime'] as String),
                    ], trailing: _record!['isMakeup'] == true
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9E4A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('补卡', style: TextStyle(fontSize: 11, color: Color(0xFFFF9E4A))))
                        : null)
                  else if (!_loading)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('该任务暂无打卡记录', style: TextStyle(fontSize: 14, color: Color(0xFF999999)))),
                    ),
                ],
              ),
            ),
          ),
          if (_canCheckin || _canMakeup)
            FooterBar(
              buttonText: _canMakeup ? '去补卡' : '去打卡',
              onButtonTap: _goClockin,
            ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> rows, {Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              if (trailing case final w?) w,
            ],
          ),
          if (rows.isNotEmpty) ...[
            const Divider(height: 20),
            ...rows,
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF333333)))),
        ],
      ),
    );
  }
}
