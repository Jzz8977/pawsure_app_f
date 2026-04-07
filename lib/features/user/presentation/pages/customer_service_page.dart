import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_nav_bar.dart';

// ── 消息模型 ──────────────────────────────────────────────────────

class _Message {
  final String id;
  final String content;
  final bool isMe;
  final DateTime time;

  _Message({
    required this.id,
    required this.content,
    required this.isMe,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

// ── Page ─────────────────────────────────────────────────────────

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final List<_Message> _messages = [
    _Message(
      id: '0',
      content: '您好！我是宠信客服，很高兴为您服务。请问有什么可以帮助您的吗？',
      isMe: false,
    ),
  ];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _showTools = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        isMe: true,
      ));
    });
    _ctrl.clear();
    _scrollToBottom();
    // 模拟回复
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_Message(
          id: '${DateTime.now().millisecondsSinceEpoch}r',
          content: '感谢您的反馈，我们会尽快为您处理，请您稍候。',
          isMe: false,
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: '联系客服'),
      body: Column(
        children: [
          // 客服信息卡
          _buildAgentCard(),

          // 消息列表
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() => _showTools = false);
              },
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildBubble(_messages[i]),
              ),
            ),
          ),

          // 输入栏
          _buildInputBar(bottom),
        ],
      ),
    );
  }

  Widget _buildAgentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7E51),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent,
                size: 26, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('宠信客服',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('在线',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF4CAF50))),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF7E51)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 14, color: Color(0xFFFF7E51)),
                  SizedBox(width: 4),
                  Text('电话联系',
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFFFF7E51))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_Message msg) {
    final isMe = msg.isMe;
    final timeStr =
        '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFFF7E51),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFFF7E51)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                      fontSize: 14,
                      color: isMe
                          ? Colors.white
                          : const Color(0xFF333333),
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F0EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person,
                  size: 20, color: Color(0xFFCCBBAA)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar(double safeBottom) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + safeBottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showTools = !_showTools),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    _showTools ? Icons.close : Icons.add_circle_outline,
                    size: 26,
                    color: const Color(0xFF888888),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      hintStyle: TextStyle(
                          color: Color(0xFFAAAAAA), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF333333)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _ctrl.text.trim().isNotEmpty
                    ? GestureDetector(
                        key: const ValueKey('send'),
                        onTap: _send,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF7E51),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              size: 18, color: Colors.white),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), width: 36),
              ),
            ],
          ),
          if (_showTools) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _ToolBtn(
                  icon: Icons.image_outlined,
                  label: '图片',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _ToolBtn(
                  icon: Icons.video_camera_back_outlined,
                  label: '视频',
                  onTap: () {},
                ),
                const SizedBox(width: 20),
                _ToolBtn(
                  icon: Icons.folder_outlined,
                  label: '文件',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888888))),
        ],
      ),
    );
  }
}
