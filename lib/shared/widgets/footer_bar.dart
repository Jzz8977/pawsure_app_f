import 'package:flutter/material.dart';

// ── Design tokens ──────────────────────────────────────────────
const _kPrimary = Color(0xFFFF9E4A);
const _kOutline = Color(0xFFFF9730);
const _kDisabledBg = Color(0xFFE5E5E5);
const _kDisabledText = Color(0xFF999999);

// ── Public data classes ────────────────────────────────────────

class AmountDetailItem {
  final String id;
  final String label;
  final String amount;
  const AmountDetailItem({required this.id, required this.label, required this.amount});
}

class FooterButton {
  final String text;
  final bool isPrimary;
  final String action;
  final bool disabled;
  const FooterButton({
    required this.text,
    this.isPrimary = true,
    required this.action,
    this.disabled = false,
  });
}

// ── FooterBar ──────────────────────────────────────────────────

/// 底部操作栏，支持：
/// - 左侧图标按钮（收藏、客服、分享、平台介入、理赔规则、打卡记录、退押金）
/// - 金额展示区（点击弹出明细抽屉）
/// - 单按钮或多按钮模式
/// - 取消订单底部弹窗（当 outlineText = '取消订单' 或 action = 'cancel'）
///
/// 用法示例：
/// ```dart
/// FooterBar(
///   buttonText: '立即预订',
///   amountLabel: '合计',
///   totalAmount: '120.00',
///   hasHeart: true,
///   isFavorite: false,
///   onButtonTap: () { ... },
///   onHeartTap: (isFav) { ... },
/// )
/// ```
class FooterBar extends StatefulWidget {
  // ── 金额区域
  final String? amountLabel;
  final String totalAmount;
  final String? subAmountText;
  final List<AmountDetailItem> amountDetails;

  // ── 多按钮模式（优先级高于单按钮）
  final List<FooterButton>? buttons;

  // ── 单按钮模式
  final String? outlineText;
  final String buttonText;
  final bool buttonDisabled;

  // ── 左侧图标开关
  final bool hasHeart;
  final bool hasService;
  final bool hasShare;
  final bool hasPlatform;
  final bool hasInsurse;
  final bool hasClockRecord;
  final bool hasRefundDeposit;
  final String refundDepositText;

  // ── 图标状态
  final bool isFavorite;
  final bool isPlatformInvolved;
  final List<String> ruleLines;

  // ── 回调
  final VoidCallback? onButtonTap;
  final VoidCallback? onOutlineTap;
  final ValueChanged<bool>? onHeartTap;
  final VoidCallback? onServiceTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onPlatformTap;
  final VoidCallback? onClockRecordTap;
  final VoidCallback? onRefundDepositTap;
  final void Function(String action, int index)? onButtonAction;
  final void Function(String reasonId, String reasonText)? onCancelConfirm;

  const FooterBar({
    super.key,
    this.amountLabel,
    this.totalAmount = '0.00',
    this.subAmountText,
    this.amountDetails = const [],
    this.buttons,
    this.outlineText,
    this.buttonText = '提交订单',
    this.buttonDisabled = false,
    this.hasHeart = false,
    this.hasService = false,
    this.hasShare = false,
    this.hasPlatform = false,
    this.hasInsurse = false,
    this.hasClockRecord = false,
    this.hasRefundDeposit = false,
    this.refundDepositText = '退押金',
    this.isFavorite = false,
    this.isPlatformInvolved = false,
    this.ruleLines = const [],
    this.onButtonTap,
    this.onOutlineTap,
    this.onHeartTap,
    this.onServiceTap,
    this.onShareTap,
    this.onPlatformTap,
    this.onClockRecordTap,
    this.onRefundDepositTap,
    this.onButtonAction,
    this.onCancelConfirm,
  });

  @override
  State<FooterBar> createState() => FooterBarState();
}

class FooterBarState extends State<FooterBar> {
  bool _debouncing = false;

  /// 外部调用：重置防抖状态（请求失败时允许用户重试）
  void resetDebounce() {
    if (mounted) setState(() => _debouncing = false);
  }

  bool get _hasLeftIcons =>
      widget.hasHeart ||
      widget.hasService ||
      widget.hasShare ||
      widget.hasPlatform ||
      widget.hasInsurse ||
      widget.hasClockRecord ||
      widget.hasRefundDeposit;

  bool get _isMultiMode => widget.buttons != null && widget.buttons!.isNotEmpty;

  void _onOutlineTap() {
    if (widget.outlineText == '取消订单') {
      _showCancelModal();
      return;
    }
    if (_debouncing) return;
    setState(() => _debouncing = true);
    widget.onOutlineTap?.call();
    Future.delayed(const Duration(seconds: 3), resetDebounce);
  }

  void _onPrimaryTap() {
    if (widget.buttonDisabled || _debouncing) return;
    setState(() => _debouncing = true);
    widget.onButtonTap?.call();
    Future.delayed(const Duration(seconds: 3), resetDebounce);
  }

  void _onMultiTap(FooterButton btn, int index) {
    if (btn.disabled) return;
    if (btn.action == 'cancel') {
      _showCancelModal();
      return;
    }
    widget.onButtonAction?.call(btn.action, index);
  }

  void _showAmountDetail() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AmountDetailSheet(items: widget.amountDetails),
    );
  }

  void _showCancelModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CancelOrderSheet(
        onConfirm: (id, text) => widget.onCancelConfirm?.call(id, text),
      ),
    );
  }

  void _showRulesModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RulesSheet(lines: widget.ruleLines),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.white.withValues(alpha: 0.96),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_hasLeftIcons) ...[_buildLeftIcons(), const SizedBox(width: 12)],
          if (widget.amountLabel != null) ...[
            Flexible(child: _buildAmountArea()),
            const SizedBox(width: 12),
          ],
          ..._buildButtons(),
        ],
      ),
    );
  }

  // ── 左侧图标区 ────────────────────────────────────────────────

  Widget _buildLeftIcons() {
    final items = <Widget>[
      if (widget.hasHeart)
        _IconBtn(
          icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorite ? _kPrimary : _kDisabledText,
          label: '收藏',
          onTap: () => widget.onHeartTap?.call(widget.isFavorite),
        ),
      if (widget.hasService)
        _IconBtn(icon: Icons.headset_mic_outlined, label: '客服', onTap: widget.onServiceTap),
      if (widget.hasShare)
        _IconBtn(icon: Icons.share_outlined, label: '分享', onTap: widget.onShareTap),
      if (widget.hasPlatform)
        _IconBtn(
          icon: widget.isPlatformInvolved ? Icons.gavel : Icons.support_agent_outlined,
          label: '平台介入',
          onTap: widget.onPlatformTap,
        ),
      if (widget.hasInsurse)
        _IconBtn(icon: Icons.shield_outlined, label: '理赔规则', onTap: _showRulesModal),
      if (widget.hasClockRecord)
        _IconBtn(icon: Icons.access_time_outlined, label: '打卡记录', onTap: widget.onClockRecordTap),
      if (widget.hasRefundDeposit)
        _IconBtn(
          icon: Icons.account_balance_wallet_outlined,
          label: widget.refundDepositText,
          onTap: widget.onRefundDepositTap,
        ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          items[i],
        ],
      ],
    );
  }

  // ── 金额显示区 ────────────────────────────────────────────────

  Widget _buildAmountArea() {
    return GestureDetector(
      onTap: widget.amountDetails.isNotEmpty ? _showAmountDetail : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.amountLabel!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
                  ),
                  const Text(
                    ' ¥',
                    style: TextStyle(fontSize: 11, color: _kPrimary, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    widget.totalAmount,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (widget.subAmountText != null)
                Text(
                  widget.subAmountText!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
            ],
          ),
          if (widget.amountDetails.isNotEmpty) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_up, size: 14, color: Color(0xFF999999)),
          ],
        ],
      ),
    );
  }

  // ── 按钮区 ────────────────────────────────────────────────────

  List<Widget> _buildButtons() {
    if (_isMultiMode) {
      return [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (int i = 0; i < widget.buttons!.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: _FooterBtn(
                    text: widget.buttons![i].text,
                    isPrimary: widget.buttons![i].isPrimary,
                    disabled: widget.buttons![i].disabled,
                    onTap: () => _onMultiTap(widget.buttons![i], i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    // 单按钮模式：无金额区时两个按钮各占 Expanded；有金额区时固定宽度
    final hasAmount = widget.amountLabel != null;
    return [
      if (!hasAmount && widget.outlineText != null) ...[
        Expanded(
          child: _FooterBtn(text: widget.outlineText!, isPrimary: false, onTap: _onOutlineTap),
        ),
        const SizedBox(width: 12),
      ],
      if (widget.buttonText.isNotEmpty)
        hasAmount
            ? _FooterBtn(
                text: widget.buttonText,
                isPrimary: true,
                disabled: widget.buttonDisabled,
                width: 120,
                onTap: _onPrimaryTap,
              )
            : Expanded(
                child: _FooterBtn(
                  text: widget.buttonText,
                  isPrimary: true,
                  disabled: widget.buttonDisabled,
                  onTap: _onPrimaryTap,
                ),
              ),
    ];
  }
}

// ── 内部组件 ───────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _IconBtn({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = _kDisabledText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _kDisabledText)),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final bool disabled;
  final double? width;
  final VoidCallback? onTap;

  const _FooterBtn({
    required this.text,
    this.isPrimary = true,
    this.disabled = false,
    this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    if (disabled) {
      bg = _kDisabledBg;
      fg = _kDisabledText;
    } else if (isPrimary) {
      bg = _kPrimary;
      fg = Colors.white;
    } else {
      bg = Colors.white;
      fg = _kOutline;
      border = Border.all(color: _kOutline);
    }

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: width,
        height: 37,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(7),
          border: border,
        ),
        child: Text(text, style: TextStyle(fontSize: 15, color: fg)),
      ),
    );
  }
}

// ── 金额明细抽屉 ───────────────────────────────────────────────

class _AmountDetailSheet extends StatelessWidget {
  final List<AmountDetailItem> items;
  const _AmountDetailSheet({required this.items});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // 预留底部操作栏高度（约 61dp）+ 安全区
      padding: EdgeInsets.only(bottom: 61 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: const Center(
              child: Text('订单明细', style: TextStyle(fontSize: 15, color: Color(0xFF3D3D3D))),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.label,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF333333))),
                          Text('¥ ${item.amount}',
                              style: const TextStyle(fontSize: 13, color: _kPrimary)),
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
}

// ── 取消订单弹窗 ───────────────────────────────────────────────

class _CancelOrderSheet extends StatefulWidget {
  final void Function(String id, String text) onConfirm;
  const _CancelOrderSheet({required this.onConfirm});

  @override
  State<_CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<_CancelOrderSheet> {
  static const _reasons = [
    ('change_time', '行程有变，需要改期'),
    ('found_better', '找到了更合适的服务'),
    ('price_high', '价格太贵'),
    ('no_need', '暂时不需要了'),
    ('other', '其他原因'),
  ];

  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '取消订单',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // 原因列表
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '请选择取消原因',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 12),
                for (final r in _reasons) _ReasonItem(
                  text: r.$2,
                  selected: _selectedId == r.$1,
                  onTap: () => setState(() => _selectedId = r.$1),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          // 底部按钮
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: _FooterBtn(
                    text: '再想想',
                    isPrimary: false,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FooterBtn(
                    text: '仍要取消',
                    isPrimary: true,
                    disabled: _selectedId == null,
                    onTap: () {
                      final id = _selectedId;
                      if (id == null) return;
                      final text = _reasons.firstWhere((r) => r.$1 == id).$2;
                      Navigator.pop(context);
                      widget.onConfirm(id, text);
                    },
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

class _ReasonItem extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const _ReasonItem({required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8F0) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _kPrimary : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
            // 自定义 radio
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _kPrimary : const Color(0xFFD8D8D8),
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _kPrimary : Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 理赔规则弹窗 ───────────────────────────────────────────────

class _RulesSheet extends StatelessWidget {
  final List<String> lines;
  const _RulesSheet({required this.lines});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: const Center(
              child: Text(
                '理赔规则',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              alignment: Alignment.center,
              child: const Text('取消', style: TextStyle(fontSize: 16, color: Color(0xFF3D7FFF))),
            ),
          ),
        ],
      ),
    );
  }
}
