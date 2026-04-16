import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';

const _kPrimary = Color(0xFFFF9E4A);

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  int _unreadCount = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.post(NotificationApi.unreadCount);
      final count = int.tryParse('${resp.data['content'] ?? 0}') ?? 0;
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // silent
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _badge(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Custom nav bar with peach background
          Container(
            color: const Color(0xFFFFE9C3),
            padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 12),
            child: const Row(
              children: [
                Text('消息',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadUnread,
              color: _kPrimary,
              child: ListView(
                children: [
                  const SizedBox(height: 12),
                  // Conversation list
                  Container(
                    color: Colors.white,
                    child: _ConversationTile(
                      onTap: () => context.push('/chatroom/notice'),
                      avatarChild: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0C1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: _kPrimary, size: 28),
                      ),
                      name: '通知公告',
                      preview: '查看系统通知公告',
                      time: '',
                      badge: _badge(_unreadCount),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final VoidCallback onTap;
  final Widget avatarChild;
  final String name;
  final String preview;
  final String time;
  final String badge;

  const _ConversationTile({
    required this.onTap,
    required this.avatarChild,
    required this.name,
    required this.preview,
    required this.time,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: avatarChild,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF424242))),
                      if (time.isNotEmpty)
                        Text(time,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB6B6B6))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                      ),
                      if (badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(badge,
                            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
