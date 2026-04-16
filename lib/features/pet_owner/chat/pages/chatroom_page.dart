import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';

const _kPrimary = Color(0xFFFF9E4A);

// ── Data model ────────────────────────────────────────────────────────────────

class _Notification {
  final String id;
  final String title;
  final String message;
  final List<String> messageLines;
  final String type;
  final bool isImportant;
  bool isRead;
  final DateTime? createdAt;
  final String createdAtText;

  _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.messageLines,
    required this.type,
    required this.isImportant,
    required this.isRead,
    required this.createdAt,
    required this.createdAtText,
  });

  factory _Notification.fromJson(Map<String, dynamic> json) {
    final rawDate = json['createdAt'] ?? json['createAt'] ?? json['create_at'] ?? '';
    DateTime? dt;
    try {
      if (rawDate.toString().isNotEmpty) {
        dt = DateTime.tryParse(rawDate.toString().replaceAll(' ', 'T'));
      }
    } catch (_) {}

    final message = json['message'] ?? json['content'] ?? '';
    return _Notification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['messageTitle'] ?? '通知公告',
      message: message.toString(),
      messageLines: _splitLines(message.toString()),
      type: json['type']?.toString() ?? '',
      isImportant: (json['isImportant'] == 1 || json['isImportant'] == true),
      isRead: (json['isRead'] == 1 || json['isRead'] == true),
      createdAt: dt,
      createdAtText: _formatDate(dt),
    );
  }

  static List<String> _splitLines(String msg) {
    if (msg.isEmpty) return [];
    final normalized = msg.replaceAll('\r', '\n');
    if (normalized.contains('\n')) {
      return normalized.split(RegExp(r'\n+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    }
    if (normalized.contains('；')) {
      return normalized.split('；').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    }
    return [normalized.trim()];
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m-$d $h:$min';
  }
}

// ── Tag config ────────────────────────────────────────────────────────────────

class _TagStyle {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _TagStyle({required this.label, required this.bgColor, required this.textColor});
}

_TagStyle _tagForNotification(_Notification n) {
  final haystack = '${n.type} ${n.title}'.toLowerCase();
  if (haystack.contains('order') || haystack.contains('订单')) {
    return const _TagStyle(label: '订单', bgColor: Color(0x59FFCC99), textColor: Color(0xFFA76324));
  }
  if (haystack.contains('task') || haystack.contains('mission') || haystack.contains('任务')) {
    return const _TagStyle(label: '任务提醒', bgColor: Color(0x72FFE9A3), textColor: Color(0xFFA56A00));
  }
  return const _TagStyle(label: '系统通知', bgColor: Color(0x59FFC1B4), textColor: Color(0xFFA0584A));
}

// ── Date grouping helpers ─────────────────────────────────────────────────────

String _dateLabel(DateTime? dt) {
  if (dt == null) return '其他';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '今天';
  if (diff == 1) return '昨天';
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '${dt.year}-$m-$d';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class ChatroomPage extends ConsumerStatefulWidget {
  final String id; // channel: 'notice' | other
  const ChatroomPage({super.key, required this.id});

  @override
  ConsumerState<ChatroomPage> createState() => _ChatroomPageState();
}

class _ChatroomPageState extends ConsumerState<ChatroomPage> {
  final List<_Notification> _items = [];
  int _pageNo = 1;
  bool _hasMore = true;
  bool _loading = false;

  // grouped: [{dateLabel, items}]
  List<({String dateLabel, List<_Notification> items})> _groups = [];

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    if (!reset && !_hasMore) return;
    setState(() => _loading = true);

    final nextPage = reset ? 1 : _pageNo + 1;
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(NotificationApi.page, data: {
        'pageNo': nextPage,
        'pageSize': 10,
        'sortBy': 'create_at',
        'asc': false,
      });
      final content = resp.data['content'] as Map<String, dynamic>? ?? {};
      final records = (content['records'] as List?) ?? (content['list'] as List?) ?? [];
      final list = records.map((e) => _Notification.fromJson(e as Map<String, dynamic>)).toList();
      final total = int.tryParse('${content['total'] ?? 0}') ?? 0;
      final hasMore = total > 0 ? nextPage * 10 < total : list.length == 10;

      // merge by id
      final map = <String, _Notification>{};
      if (!reset) {
        for (final n in _items) {
          map[n.id] = n;
        }
      }
      for (final n in list) {
        map[n.id] = n;
      }
      final merged = map.values.toList()
        ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

      if (mounted) {
        setState(() {
          _items
            ..clear()
            ..addAll(merged);
          _pageNo = nextPage;
          _hasMore = hasMore;
          _groups = _buildGroups(merged);
        });
      }

      // mark unread as read
      final unreadIds = list.where((n) => !n.isRead).map((n) => n.id).toList();
      if (unreadIds.isNotEmpty) _markRead(unreadIds);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<({String dateLabel, List<_Notification> items})> _buildGroups(List<_Notification> list) {
    final map = <String, List<_Notification>>{};
    for (final n in list) {
      final label = _dateLabel(n.createdAt);
      (map[label] ??= []).add(n);
    }
    final groups = map.entries.map((e) => (dateLabel: e.key, items: e.value)).toList();
    groups.sort((a, b) {
      final ta = a.items.first.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.items.first.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });
    return groups;
  }

  Future<void> _markRead(List<String> ids) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post(NotificationApi.markRead, data: {'ids': ids});
      final set = ids.toSet();
      for (final n in _items) {
        if (set.contains(n.id)) n.isRead = true;
      }
      if (mounted) setState(() => _groups = _buildGroups(_items));
    } catch (_) {}
  }

  void _onCardTap(_Notification n) {
    if (!n.isRead) _markRead([n.id]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(n.title),
        content: SingleChildScrollView(child: Text(n.message.isEmpty ? '暂无正文' : n.message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('我知道了', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.id == 'notice' ? '通知公告' : '消息';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppNavBar(title: title, showDivider: false),
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification && n.metrics.extentAfter < 100) {
            _load();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          color: _kPrimary,
          child: _groups.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: _groups.length + 1, // +1 for footer
                  itemBuilder: (context, index) {
                    if (index == _groups.length) return _buildFooter();
                    final group = _groups[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(group.dateLabel,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9AA1B2))),
                        ),
                        ...group.items.map((n) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _NoticeCard(notification: n, onTap: () => _onCardTap(n)),
                        )),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2));
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('暂无通知公告', style: TextStyle(fontSize: 16, color: Color(0xFF1D2129), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('最新公告会第一时间显示在这里', style: TextStyle(fontSize: 13, color: Color(0xFF969FAF))),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
      );
    }
    if (!_hasMore && _groups.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('没有更多了', style: TextStyle(fontSize: 13, color: Color(0xFFA0A7B6)))),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Card widget ───────────────────────────────────────────────────────────────

class _NoticeCard extends StatelessWidget {
  final _Notification notification;
  final VoidCallback onTap;

  const _NoticeCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final tag = _tagForNotification(n);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead ? Colors.transparent : const Color(0xFFFFCF8B),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: n.isRead
                  ? const Color(0x0D000000)
                  : const Color(0x40FFBC69),
              blurRadius: n.isRead ? 16 : 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tag.bgColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(tag.label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tag.textColor)),
            ),
            const SizedBox(height: 10),
            // Title
            Text(n.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1D2129))),
            const SizedBox(height: 6),
            // Body
            if (n.messageLines.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: n.messageLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(line, style: const TextStyle(fontSize: 13, color: Color(0xFF4A4F5C), height: 1.6)),
                )).toList(),
              )
            else if (n.message.isNotEmpty)
              Text(n.message, style: const TextStyle(fontSize: 13, color: Color(0xFF4A4F5C), height: 1.6)),
            const SizedBox(height: 10),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(n.createdAtText,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFA0A7B6))),
                if (n.isImportant)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x26FF6B37),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('重要',
                      style: TextStyle(fontSize: 11, color: Color(0xFFFF6B37))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
