import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

class ClockinTasksPage extends ConsumerStatefulWidget {
  final String? orderNo;
  final String? orderId;
  final String? customerId;
  final String? providerId;

  const ClockinTasksPage({
    super.key,
    this.orderNo,
    this.orderId,
    this.customerId,
    this.providerId,
  });

  @override
  ConsumerState<ClockinTasksPage> createState() => _ClockinTasksPageState();
}

class _ClockinTasksPageState extends ConsumerState<ClockinTasksPage> {
  bool _loading = false;
  bool _dayLoading = false;
  List<Map<String, dynamic>> _streakDays = [];
  String _activeDayKey = '';
  List<Map<String, dynamic>> _fixedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadPageData({String preferredDayKey = ''}) async {
    if (_loading) return;
    final orderNo = widget.orderNo ?? '';
    if (orderNo.isEmpty) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(CheckinApi.taskDatesList, data: {'orderNo': orderNo});
      final content = res.data['content'];
      final dates = (content is Map ? content['dates'] : null) as List? ?? [];
      final streakDays = _buildStreakDays(dates, preferredDayKey);
      final activeDayKey = _resolveActiveDayKey(streakDays, preferredDayKey);
      final decorated = _decorateActiveDay(streakDays, activeDayKey);
      setState(() {
        _streakDays = decorated;
        _activeDayKey = activeDayKey;
        _fixedTasks = [];
      });
      if (activeDayKey.isNotEmpty) {
        await _loadDailyTasks(activeDayKey);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDailyTasks(String dayKey) async {
    final orderNo = widget.orderNo ?? '';
    if (orderNo.isEmpty || dayKey.isEmpty) return;
    setState(() => _dayLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(CheckinApi.tasksDailyList, data: {
        'orderNo': orderNo,
        'date': dayKey,
      });
      final content = res.data['content'];
      final tasks = (content is Map ? content['tasks'] : null) as List? ?? [];
      setState(() {
        _fixedTasks = tasks.map<Map<String, dynamic>>((t) => _formatTask(Map<String, dynamic>.from(t as Map), dayKey)).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _fixedTasks = []);
    } finally {
      if (mounted) setState(() => _dayLoading = false);
    }
  }

  List<Map<String, dynamic>> _buildStreakDays(List<dynamic> dates, String preferredKey) {
    final sorted = dates.cast<Map>().toList()
      ..sort((a, b) => (a['date'] ?? '').toString().compareTo((b['date'] ?? '').toString()));

    final today = _formatDateKey(DateTime.now());
    return sorted.map((item) {
      final key = item['date']?.toString() ?? '';
      final totalCount = (item['totalCount'] as num?)?.toInt() ?? 0;
      final doneCount = (item['doneCount'] as num?)?.toInt() ?? 0;
      final isToday = item['isCurrentDate'] == true || key == today;
      return {
        'key': key,
        'dateText': _formatMonthDay(key),
        'weekdayText': _formatWeekday(key),
        'countText': '$doneCount/$totalCount',
        'isDone': totalCount > 0 && doneCount >= totalCount,
        'isToday': isToday,
        'isActive': key == preferredKey,
        'doneCount': doneCount,
        'totalCount': totalCount,
      };
    }).toList();
  }

  String _resolveActiveDayKey(List<Map<String, dynamic>> days, String preferred) {
    if (days.isEmpty) return '';
    if (preferred.isNotEmpty && days.any((d) => d['key'] == preferred)) return preferred;
    final today = days.firstWhere((d) => d['isToday'] == true, orElse: () => {});
    if (today.isNotEmpty) return today['key'] as String;
    return days.first['key'] as String;
  }

  List<Map<String, dynamic>> _decorateActiveDay(List<Map<String, dynamic>> days, String activeKey) {
    return days.map((d) => {...d, 'isActive': d['key'] == activeKey}).toList();
  }

  Map<String, dynamic> _formatTask(Map<String, dynamic> task, String dayKey) {
    final status = task['status']?.toString() ?? 'PENDING';
    final isDone = status == 'DONE_ON_TIME' || status == 'DONE_LATE';
    final isExcused = status == 'EXCUSED';
    final doneAt = _parseTime(task['doneAt']);

    String hint;
    String buttonText;
    String buttonType;
    bool disabled;

    if (isDone) {
      hint = doneAt != null ? '已完成 ${_formatHHmm(doneAt)}' : '已完成';
      buttonText = '已完成';
      buttonType = 'done';
      disabled = true;
    } else if (isExcused) {
      hint = '已豁免';
      buttonText = '已豁免';
      buttonType = 'disabled';
      disabled = true;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final windowStart = _parseTime(task['windowStart']);
      final windowEnd = _parseTime(task['windowEnd']);
      final makeupStart = _parseTime(task['makeupStart']);
      final makeupEnd = _parseTime(task['makeupEnd']);
      final wsTs = windowStart?.millisecondsSinceEpoch;
      final weTs = windowEnd?.millisecondsSinceEpoch;
      final msTs = makeupStart?.millisecondsSinceEpoch;
      final meTs = makeupEnd?.millisecondsSinceEpoch;
      final windowText = (windowStart != null && windowEnd != null)
          ? '${_formatHHmm(windowStart)} - ${_formatHHmm(windowEnd)}'
          : '';
      final makeupText = (makeupStart != null && makeupEnd != null)
          ? '${_formatHHmm(makeupStart)} - ${_formatHHmm(makeupEnd)}'
          : '';

      if (wsTs != null && weTs != null && now >= wsTs && now <= weTs) {
        hint = windowText.isNotEmpty ? '打卡时段 $windowText' : '当前可打卡';
        buttonText = '打卡';
        buttonType = 'primary';
        disabled = false;
      } else if (wsTs != null && now < wsTs) {
        hint = windowText.isNotEmpty ? '未到打卡时间 $windowText' : '未到打卡时间';
        buttonText = '未开始';
        buttonType = 'disabled';
        disabled = true;
      } else if (msTs != null && meTs != null && now >= msTs && now <= meTs) {
        hint = makeupText.isNotEmpty ? '补卡时段 $makeupText' : '当前可补卡';
        buttonText = '补卡';
        buttonType = 'warning';
        disabled = false;
      } else {
        hint = '已超过补卡截止时间';
        buttonText = '已超时';
        buttonType = 'disabled';
        disabled = true;
      }
    }

    return {
      ...task,
      'id': task['id']?.toString() ?? '',
      'hint': hint,
      'buttonText': buttonText,
      'buttonType': buttonType,
      'actionDisabled': disabled,
      'planDayKey': dayKey,
    };
  }

  void _onDayTap(String dayKey) {
    if (dayKey == _activeDayKey) return;
    setState(() {
      _streakDays = _decorateActiveDay(_streakDays, dayKey);
      _activeDayKey = dayKey;
      _fixedTasks = [];
    });
    _loadDailyTasks(dayKey);
  }

  void _onFixedTaskAction(Map<String, dynamic> task) {
    if (task['actionDisabled'] == true) return;
    final orderNo = widget.orderNo ?? '';
    if (orderNo.isEmpty) return;
    final params = <String, String>{'orderNo': orderNo};
    if (task['id']?.toString().isNotEmpty == true) params['taskId'] = task['id'].toString();
    if (task['serviceType'] != null) params['serviceType'] = task['serviceType'].toString();
    if (task['providerId'] != null) params['providerId'] = task['providerId'].toString();
    if (task['customerId'] != null) params['customerId'] = task['customerId'].toString();
    if (widget.orderId?.isNotEmpty == true) params['orderId'] = widget.orderId!;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    context.push('/clockin?$query');
  }

  void _onFreeCheckin() {
    final orderNo = widget.orderNo ?? '';
    if (orderNo.isEmpty) return;
    final extra = widget.orderId?.isNotEmpty == true ? '&orderId=${widget.orderId}' : '';
    context.push('/clockin?orderNo=$orderNo$extra');
  }

  void _onReportException() {
    final orderNo = widget.orderNo ?? '';
    if (orderNo.isEmpty) return;
    final providerId = widget.providerId ?? (_fixedTasks.isNotEmpty ? _fixedTasks.first['providerId']?.toString() : '');
    final customerId = widget.customerId ?? (_fixedTasks.isNotEmpty ? _fixedTasks.first['customerId']?.toString() : '');
    context.push('/report-issue?orderNo=$orderNo&providerId=${providerId ?? ''}&customerId=${customerId ?? ''}');
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatMonthDay(String key) {
    final d = DateTime.tryParse(key);
    if (d == null) return key;
    return '${d.month}.${d.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekday(String key) {
    final d = DateTime.tryParse(key);
    if (d == null) return '';
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return days[d.weekday % 7];
  }

  DateTime? _parseTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString().replaceAll('-', '/').replaceAll('/', '-'));
  }

  String _formatHHmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '任务中心', showDivider: false),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadPageData(preferredDayKey: _activeDayKey),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildStreakCard(),
                          const SizedBox(height: 12),
                          _buildFixedTasksCard(),
                          const SizedBox(height: 12),
                          _buildActionCard(
                            title: '自由打卡',
                            desc: '记录额外的陪护任务，不受固定计划限制',
                            buttonText: '去打卡',
                            onTap: _onFreeCheckin,
                          ),
                          const SizedBox(height: 12),
                          _buildActionCard(
                            title: '异常打卡',
                            desc: '环境或宠物出现异常时立即上报',
                            buttonText: '去上报',
                            danger: true,
                            onTap: _onReportException,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('连续打卡', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              GestureDetector(
                onTap: () => context.push('/clockin-record?orderNo=${widget.orderNo ?? ''}'),
                child: const Text('打卡记录', style: TextStyle(fontSize: 13, color: Color(0xFFFF9E4A))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: _streakDays.isEmpty
                ? const Center(child: Text('暂无打卡数据', style: TextStyle(color: Color(0xFF999999))))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _streakDays.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _buildStreakDayItem(_streakDays[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDayItem(Map<String, dynamic> day) {
    final isActive = day['isActive'] == true;
    final isDone = day['isDone'] == true;
    final isToday = day['isToday'] == true;
    Color bgColor;
    Color textColor;
    if (isActive) {
      bgColor = const Color(0xFFFF9E4A);
      textColor = Colors.white;
    } else if (isDone) {
      bgColor = const Color(0xFF52C41A).withValues(alpha: 0.1);
      textColor = const Color(0xFF52C41A);
    } else if (isToday) {
      bgColor = const Color(0xFFFF9E4A).withValues(alpha: 0.1);
      textColor = const Color(0xFFFF9E4A);
    } else {
      bgColor = const Color(0xFFF5F5F5);
      textColor = const Color(0xFF999999);
    }

    return GestureDetector(
      onTap: () => _onDayTap(day['key'] as String),
      child: Container(
        width: 54,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day['dateText']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(day['countText']?.toString() ?? '',
                style: TextStyle(fontSize: 11, color: textColor)),
            if (isToday)
              Text('今', style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedTasksCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('固定任务', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 12),
          if (_dayLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
          else if (_fixedTasks.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('当前日期暂无固定任务', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ))
          else
            ...List.generate(_fixedTasks.length, (i) {
              if (i > 0) {
                return Column(children: [const Divider(height: 1), _buildTaskRow(_fixedTasks[i])]);
              }
              return _buildTaskRow(_fixedTasks[i]);
            }),
        ],
      ),
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task) {
    final buttonType = task['buttonType'] as String;
    final disabled = task['actionDisabled'] == true;
    Color btnColor;
    switch (buttonType) {
      case 'primary': btnColor = const Color(0xFFFF9E4A); break;
      case 'warning': btnColor = const Color(0xFFFA8C16); break;
      case 'done':    btnColor = const Color(0xFF52C41A); break;
      default:        btnColor = const Color(0xFFCCCCCC); break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.pets, size: 18, color: Color(0xFFFF9E4A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task['activityTypeDesc']?.toString() ?? '待定',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                Text(task['hint']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          GestureDetector(
            onTap: disabled ? null : () => _onFixedTaskAction(task),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: disabled ? const Color(0xFFF5F5F5) : btnColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: disabled ? const Color(0xFFDDDDDD) : btnColor),
              ),
              child: Text(
                task['buttonText']?.toString() ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: disabled ? const Color(0xFFCCCCCC) : btnColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String desc,
    required String buttonText,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFFF4D4F) : const Color(0xFFFF9E4A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}
