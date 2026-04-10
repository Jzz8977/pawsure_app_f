import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── 数据模型 ──────────────────────────────────────────────────────

class FlowOption {
  final String label;
  final dynamic value; // int or String
  const FlowOption({required this.label, required this.value});
}

enum FlowType { input, single, multi, date, textarea, picker }

class FlowQuestion {
  final String id;
  final FlowType type;
  final String title;
  final String? title2;   // 用于 summary 展示的短标签
  final String? placeholder;
  final String? suffix;
  final bool required;
  final List<FlowOption>? options;
  final int? max;          // multi 最多选 n 项
  final int? maxLength;    // textarea 最大字数
  final bool numericInput; // input 是否数字键盘
  final double? minNum;
  final double? maxNum;

  const FlowQuestion({
    required this.id,
    required this.type,
    required this.title,
    this.title2,
    this.placeholder,
    this.suffix,
    this.required = false,
    this.options,
    this.max,
    this.maxLength,
    this.numericInput = false,
    this.minNum,
    this.maxNum,
  });

  /// 返回替换了 options 的副本（用于动态注入品种列表等）
  FlowQuestion copyWithOptions(List<FlowOption> opts) => FlowQuestion(
        id: id,
        type: type,
        title: title,
        title2: title2,
        placeholder: placeholder,
        suffix: suffix,
        required: required,
        options: opts,
        max: max,
        maxLength: maxLength,
        numericInput: numericInput,
        minNum: minNum,
        maxNum: maxNum,
      );
}

// ── Widget ────────────────────────────────────────────────────────

/// 对应小程序 flow-ask 组件：逐题引导填写。
/// [questions] 问题列表。
/// [initialAnswers] 预填答案 Map。
/// [onFinish] 完成回调，[skipped]=true 表示点了跳过。
/// [showIntro] 首屏是否显示引导文字（对应 showI）。
/// [entryMode] 只编辑单题后立即返回。
class FlowAskWidget extends StatefulWidget {
  final List<FlowQuestion> questions;
  final Map<String, dynamic> initialAnswers;
  final bool showIntro;
  final bool entryMode;
  final void Function(Map<String, dynamic> answers, {bool skipped}) onFinish;

  const FlowAskWidget({
    super.key,
    required this.questions,
    required this.onFinish,
    this.initialAnswers = const {},
    this.showIntro = false,
    this.entryMode = false,
  });

  @override
  State<FlowAskWidget> createState() => _FlowAskWidgetState();
}

class _FlowAskWidgetState extends State<FlowAskWidget> {
  int _idx = 0;
  late Map<String, dynamic> _answers;
  dynamic _temp;
  String _err = '';
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _answers = Map.from(widget.initialAnswers);
    _loadQuestion();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  FlowQuestion get _q => widget.questions[_idx];

  void _loadQuestion() {
    final q = _q;
    final saved = _answers[q.id];
    if (q.type == FlowType.multi) {
      _temp = saved is List ? List.from(saved) : [];
    } else if (q.type == FlowType.input || q.type == FlowType.textarea) {
      _temp = saved?.toString() ?? '';
      _ctrl.text = _temp ?? '';
    } else {
      _temp = saved;
    }
    _err = '';
  }

  bool _isFilled(FlowQuestion q, dynamic val) {
    if (q.type == FlowType.multi) return val is List && val.isNotEmpty;
    return val != null && val != '';
  }

  String? _validate() {
    final q = _q;
    final v = _temp;
    if (q.required && !_isFilled(q, v)) return '请完成此项';
    if (q.type == FlowType.input && v != null && v != '') {
      final n = double.tryParse(v.toString());
      if (q.minNum != null && n != null && n < q.minNum!) return '不能小于 ${q.minNum}';
      if (q.maxNum != null && n != null && n > q.maxNum!) return '不能大于 ${q.maxNum}';
    }
    if (q.type == FlowType.multi && q.max != null) {
      if (v is List && v.length > q.max!) return '最多选择 ${q.max} 项';
    }
    return null;
  }

  void _confirm() {
    final err = _validate();
    if (err != null) {
      setState(() => _err = err);
      return;
    }
    _answers[_q.id] = _temp;
    if (widget.entryMode) {
      widget.onFinish(_answers);
      return;
    }
    if (_idx >= widget.questions.length - 1) {
      widget.onFinish(_answers);
    } else {
      setState(() {
        _idx++;
        _loadQuestion();
      });
    }
  }

  void _prev() {
    if (_idx > 0) {
      setState(() {
        _idx--;
        _loadQuestion();
      });
    }
  }

  void _skip() => widget.onFinish(_answers, skipped: true);

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProgressBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _q.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInput(),
                if (_err.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_err,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFFF4D4F))),
                ],
                const SizedBox(height: 28),
                _buildFooter(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final total = widget.questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(total, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _idx
                          ? const Color(0xFFFF7E51)
                          : const Color(0xFFECECEC),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _skip,
            child: const Text('跳过',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    switch (_q.type) {
      case FlowType.input:
        return _buildTextField();
      case FlowType.textarea:
        return _buildTextarea();
      case FlowType.single:
        return _buildSingle();
      case FlowType.multi:
        return _buildMulti();
      case FlowType.date:
        return _buildDate();
      case FlowType.picker:
        return _buildPicker();
    }
  }

  Widget _buildTextField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              keyboardType: _q.numericInput
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: _q.numericInput
                  ? [FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'))]
                  : null,
              maxLength: _q.maxLength,
              decoration: InputDecoration(
                hintText: _q.placeholder ?? '请输入',
                hintStyle: const TextStyle(
                    fontSize: 15, color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                counterText: '',
              ),
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF222222)),
              onChanged: (v) {
                _temp = v;
                if (_err.isNotEmpty) setState(() => _err = '');
              },
              onSubmitted: (_) => _confirm(),
            ),
          ),
          if (_q.suffix != null) ...[
            const SizedBox(width: 8),
            Text(_q.suffix!,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF888888))),
          ],
        ],
      ),
    );
  }

  Widget _buildTextarea() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: 5,
        maxLength: _q.maxLength ?? 200,
        decoration: InputDecoration(
          hintText: _q.placeholder ?? '请输入',
          hintStyle: const TextStyle(
              fontSize: 14, color: Color(0xFFBBBBBB)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
            fontSize: 14, color: Color(0xFF222222), height: 1.5),
        onChanged: (v) {
          _temp = v;
          if (_err.isNotEmpty) setState(() => _err = '');
        },
      ),
    );
  }

  Widget _buildSingle() {
    final opts = _q.options ?? [];
    final vertical = opts.length > 2;
    if (vertical) {
      return Column(
        children: opts.map(_singleOpt).toList(),
      );
    }
    return Row(
      children: opts
          .map((o) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _singleOpt(o),
                ),
              ))
          .toList(),
    );
  }

  Widget _singleOpt(FlowOption opt) {
    final sel = _temp == opt.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _temp = opt.value;
          _err = '';
        });
        Future.microtask(_confirm);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFFFF0E8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? const Color(0xFFFF7E51) : const Color(0xFFEEEEEE),
            width: sel ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            opt.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  sel ? FontWeight.w600 : FontWeight.normal,
              color: sel
                  ? const Color(0xFFFF7E51)
                  : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMulti() {
    final opts = _q.options ?? [];
    return Column(
      children: opts.map((o) {
        final list = _temp as List? ?? [];
        final sel = list.contains(o.value);
        return GestureDetector(
          onTap: () {
            setState(() {
              final next = List.from(list);
              if (sel) {
                next.remove(o.value);
              } else {
                next.add(o.value);
              }
              _temp = next;
              _err = '';
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFFFF0E8) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? const Color(0xFFFF7E51)
                    : const Color(0xFFEEEEEE),
                width: sel ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    o.label,
                    style: TextStyle(
                      fontSize: 15,
                      color: sel
                          ? const Color(0xFFFF7E51)
                          : const Color(0xFF333333),
                    ),
                  ),
                ),
                if (sel)
                  const Icon(Icons.check_circle_rounded,
                      size: 18, color: Color(0xFFFF7E51)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDate() {
    final s = _temp?.toString() ?? '';
    return GestureDetector(
      onTap: () async {
        final init = s.isNotEmpty
            ? DateTime.tryParse(s) ?? DateTime(2020)
            : DateTime(2020);
        final picked = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: DateTime(1990),
          lastDate: DateTime.now(),
          locale: const Locale('zh'),
        );
        if (picked != null && mounted) {
          final ds =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          setState(() {
            _temp = ds;
            _err = '';
          });
          _confirm();
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                s.isNotEmpty ? s : '请选择日期',
                style: TextStyle(
                  fontSize: 15,
                  color: s.isNotEmpty
                      ? const Color(0xFF222222)
                      : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker() {
    final opts = _q.options ?? [];
    final label = opts
        .where((o) => o.value == _temp)
        .map((o) => o.label)
        .firstOrNull ?? '';
    return GestureDetector(
      onTap: () => _showPickerSheet(opts),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label.isNotEmpty ? label : (_q.placeholder ?? '请选择'),
                style: TextStyle(
                  fontSize: 15,
                  color: label.isNotEmpty
                      ? const Color(0xFF222222)
                      : const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFFAAAAAA)),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet(List<FlowOption> opts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: _q.title,
        options: opts,
        selectedValue: _temp,
        onSelect: (val) {
          Navigator.pop(context);
          setState(() {
            _temp = val;
            _err = '';
          });
          Future.microtask(_confirm);
        },
      ),
    );
  }

  Widget _buildFooter() {
    final isLast = _idx == widget.questions.length - 1;
    return Row(
      children: [
        if (_idx > 0)
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _prev,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('上一步',
                  style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666))),
            ),
          ),
        if (_idx > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _q.type == FlowType.single ||
                    _q.type == FlowType.date ||
                    _q.type == FlowType.picker
                ? null // 这几种类型点选后自动确认，按钮灰显提示
                : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7E51),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFF7E51).withValues(alpha: 0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              widget.entryMode
                  ? '完成此项'
                  : (isLast ? '完成' : '确认'),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Picker 搜索底部弹窗 ───────────────────────────────────────────

class _PickerSheet extends StatefulWidget {
  final String title;
  final List<FlowOption> options;
  final dynamic selectedValue;
  final ValueChanged<dynamic> onSelect;

  const _PickerSheet({
    required this.title,
    required this.options,
    this.selectedValue,
    required this.onSelect,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _q.isEmpty
        ? widget.options
        : widget.options
            .where((o) => o.label.contains(_q))
            .toList();
    final bottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 标题栏
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333))),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: '搜索...',
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('无匹配结果',
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFAAAAAA))))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final opt = filtered[i];
                      final sel =
                          opt.value == widget.selectedValue;
                      return ListTile(
                        title: Text(opt.label),
                        trailing: sel
                            ? const Icon(
                                Icons.check_rounded,
                                color: Color(0xFFFF7E51))
                            : null,
                        onTap: () =>
                            widget.onSelect(opt.value),
                      );
                    },
                  ),
          ),
          SizedBox(height: bottom),
        ],
      ),
    );
  }
}
