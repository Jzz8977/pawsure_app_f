import 'package:flutter/material.dart';

const _kPrimary = Color(0xFFFF9E4A);

class WorkTabPage extends StatefulWidget {
  const WorkTabPage({super.key});

  @override
  State<WorkTabPage> createState() => _WorkTabPageState();
}

class _WorkTabPageState extends State<WorkTabPage> {
  String _activeTab = 'upgrade';

  final List<_StatItem> _stats = const [
    _StatItem(label: '待接单量', value: '2'),
    _StatItem(label: '进行中数量', value: '3'),
    _StatItem(label: '评价待回复', value: '0'),
  ];

  final List<_AlertItem> _alerts = const [
    _AlertItem(label: '打卡异常', value: '3', unit: '个'),
    _AlertItem(label: '用户退款', value: '2', unit: '单'),
    _AlertItem(label: '用户投诉', value: '0', unit: '单'),
  ];

  final List<_MetricItem> _metrics = const [
    _MetricItem(label: '月度收入', value: '2100.00', theme: _MetricTheme.peach),
    _MetricItem(label: '服务完成数', value: '2100.00', theme: _MetricTheme.sky),
    _MetricItem(label: '评价/评分', value: '4.9', theme: _MetricTheme.mint),
  ];

  final List<_ListEntry> _upgradeList = const [
    _ListEntry(id: 'course', icon: Icons.play_circle_outline, title: '课程培训'),
    _ListEntry(id: 'rule', icon: Icons.menu_book_outlined, title: '服务者行为准则'),
    _ListEntry(id: 'score', icon: Icons.trending_up_outlined, title: '如何提升服务分'),
  ];

  final List<_ListEntry> _noticeList = const [
    _ListEntry(id: 'notice-1', icon: Icons.campaign_outlined, title: '系统升级通知'),
    _ListEntry(id: 'notice-2', icon: Icons.event_note_outlined, title: '春节假期安排'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FB),
      body: Stack(
        children: [
          // Gradient header background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 180,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE7C0), Color(0xFFFEF6E5)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPad),
              child: Column(
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '数据中心',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stats summary card
                  _buildCard(
                    child: Row(
                      children: _stats.map((s) => Expanded(
                        child: Column(
                          children: [
                            Text(s.value,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                            const SizedBox(height: 6),
                            Text(s.label,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alert card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('订单异常提醒',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                            GestureDetector(
                              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('功能开发中'), duration: Duration(seconds: 1))),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('去处理', style: TextStyle(fontSize: 12, color: Colors.white)),
                                    SizedBox(width: 2),
                                    Icon(Icons.chevron_right, size: 14, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _alerts.map((a) => Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.label,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFFFF5E54))),
                                const SizedBox(height: 6),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(text: a.value,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                                      TextSpan(text: a.unit,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Metrics card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('数据中心',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                        const SizedBox(height: 12),
                        Row(
                          children: _metrics.map((m) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: m.theme.bgColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(m.label,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: m.theme.textColor)),
                                    const SizedBox(height: 6),
                                    Text(m.value,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: m.theme.textColor)),
                                  ],
                                ),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Upgrade / notice tabs card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Column(
                      children: [
                        // Tab header
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFE3B3), Color(0xFFFFF7E8)],
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildTab('upgrade', '提升中心'),
                              _buildTab('notice', '通知公告'),
                            ],
                          ),
                        ),
                        // List
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: (_activeTab == 'upgrade' ? _upgradeList : _noticeList)
                                .map((item) => _buildListItem(item))
                                .toList(),
                          ),
                        ),
                      ],
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

  Widget _buildCard({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );

  Widget _buildTab(String key, String label) {
    final isActive = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: isActive
              ? const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? _kPrimary : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(_ListEntry item) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('即将进入 ${item.title}'), duration: const Duration(seconds: 1))),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FD),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(color: Color(0xFFEEEFF5), shape: BoxShape.circle),
              child: Icon(item.icon, size: 18, color: const Color(0xFF666666)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.title,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    ),
  );
}

class _StatItem {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
}

class _AlertItem {
  final String label;
  final String value;
  final String unit;
  const _AlertItem({required this.label, required this.value, required this.unit});
}

enum _MetricTheme {
  peach(bgColor: Color(0xFFFFF4EE), textColor: Color(0xFFFFA500)),
  sky(bgColor: Color(0xFFEAF3FF), textColor: Color(0xFF007BFF)),
  mint(bgColor: Color(0xFFE2F4F9), textColor: Color(0xFF2E9FBB));

  const _MetricTheme({required this.bgColor, required this.textColor});
  final Color bgColor;
  final Color textColor;
}

class _MetricItem {
  final String label;
  final String value;
  final _MetricTheme theme;
  const _MetricItem({required this.label, required this.value, required this.theme});
}

class _ListEntry {
  final String id;
  final IconData icon;
  final String title;
  const _ListEntry({required this.id, required this.icon, required this.title});
}
