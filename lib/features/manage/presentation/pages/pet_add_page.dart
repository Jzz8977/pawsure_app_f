import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/circle_progress.dart';
import '../../../../shared/widgets/flow_ask.dart';

// ── 问题配置 ─────────────────────────────────────────────────────

const _kBasicQuestions = [
  FlowQuestion(
    id: 'species',
    type: FlowType.single,
    title: '请问您的宠物类型是？',
    title2: '类型',
    required: true,
    options: [
      FlowOption(label: '狗狗 🐶', value: 1),
      FlowOption(label: '猫猫 🐱', value: 2),
    ],
  ),
  FlowQuestion(
    id: 'name',
    type: FlowType.input,
    title: '给您的宠物起个昵称',
    title2: '昵称',
    placeholder: '如：奶糖、雪球',
    required: true,
    maxLength: 12,
  ),
  FlowQuestion(
    id: 'birthDate',
    type: FlowType.date,
    title: '请问您的宠物生日是？',
    title2: '生日',
    required: true,
  ),
  FlowQuestion(
    id: 'weight',
    type: FlowType.input,
    title: '请问您的宠物体重是？',
    title2: '体重(kg)',
    placeholder: '如：3.5',
    required: true,
    numericInput: true,
    suffix: 'kg',
    minNum: 0.1,
    maxNum: 200,
  ),
  FlowQuestion(
    id: 'gender',
    type: FlowType.single,
    title: '请问您的宠物性别是？',
    title2: '性别',
    required: true,
    options: [
      FlowOption(label: '公', value: 1),
      FlowOption(label: '母', value: 2),
      FlowOption(label: '未知', value: 3),
    ],
  ),
  FlowQuestion(
    id: 'sterilized',
    type: FlowType.single,
    title: '是否已绝育？',
    title2: '绝育状态',
    required: false,
    options: [
      FlowOption(label: '已绝育', value: 1),
      FlowOption(label: '未绝育', value: 0),
    ],
  ),
  // 品种将在运行时注入 options
  FlowQuestion(
    id: 'breedId',
    type: FlowType.picker,
    title: 'Ta 的品种是？',
    title2: '具体品种',
    placeholder: '请选择品种',
    required: false,
  ),
];

const _kCareQuestions = [
  FlowQuestion(
    id: 'toiletFreq',
    type: FlowType.single,
    title: '上厕所频率',
    title2: '如厕频率',
    required: false,
    options: [
      FlowOption(label: '每1小时', value: 1),
      FlowOption(label: '每2小时', value: 2),
      FlowOption(label: '每4小时', value: 3),
      FlowOption(label: '每8小时', value: 4),
    ],
  ),
  FlowQuestion(
    id: 'activityLevel',
    type: FlowType.single,
    title: 'Ta 的活动量是？',
    title2: '活动量',
    required: false,
    options: [
      FlowOption(label: '高', value: 1),
      FlowOption(label: '中', value: 2),
      FlowOption(label: '低', value: 3),
    ],
  ),
  FlowQuestion(
    id: 'careInterval',
    type: FlowType.single,
    title: '看护间隔时间',
    title2: '看护频次',
    required: false,
    options: [
      FlowOption(label: '小于1小时', value: 1),
      FlowOption(label: '1-4小时', value: 2),
      FlowOption(label: '4-8小时', value: 3),
      FlowOption(label: '不可离开', value: 4),
    ],
  ),
  FlowQuestion(
    id: 'medicationNeeds',
    type: FlowType.single,
    title: '用药需求',
    title2: '用药情况',
    required: false,
    options: [
      FlowOption(label: '无', value: 0),
      FlowOption(label: '按时服药', value: 1),
      FlowOption(label: '需要营养品', value: 2),
    ],
  ),
  FlowQuestion(
    id: 'healthDesc',
    type: FlowType.textarea,
    title: '健康情况说明',
    title2: '健康说明',
    placeholder: '如：有轻微皮肤病，已绝育，易对牛肉过敏',
    required: false,
    maxLength: 200,
  ),
];

const _kBehaviorQuestions = [
  FlowQuestion(
    id: 'friendlyKids',
    type: FlowType.single,
    title: '是否对人友好？',
    title2: '对人友好',
    required: false,
    options: [
      FlowOption(label: '是', value: 1),
      FlowOption(label: '否', value: 0),
    ],
  ),
  FlowQuestion(
    id: 'friendlyDogs',
    type: FlowType.single,
    title: '是否对其他狗狗友好？',
    title2: '对狗友好',
    required: false,
    options: [
      FlowOption(label: '是', value: 1),
      FlowOption(label: '否', value: 0),
    ],
  ),
  FlowQuestion(
    id: 'friendlyCats',
    type: FlowType.single,
    title: '是否对其他猫猫友好？',
    title2: '对猫友好',
    required: false,
    options: [
      FlowOption(label: '是', value: 1),
      FlowOption(label: '否', value: 0),
    ],
  ),
  FlowQuestion(
    id: 'pottyTime',
    type: FlowType.single,
    title: '是否会定点大小便？',
    title2: '定点如厕',
    required: false,
    options: [
      FlowOption(label: '是', value: 1),
      FlowOption(label: '否', value: 0),
    ],
  ),
  FlowQuestion(
    id: 'otherDesc',
    type: FlowType.textarea,
    title: '其他描述',
    title2: '其他说明',
    placeholder: '例如：特殊习惯、注意事项等（选填）',
    required: false,
    maxLength: 200,
  ),
];

// ── 摘要显示标签 ──────────────────────────────────────────────────

String _labelOf(String fieldId, dynamic value) {
  if (value == null || value == '') return '';
  switch (fieldId) {
    case 'species':
      return value == 1 ? '狗狗' : value == 2 ? '猫猫' : '$value';
    case 'gender':
      return {1: '公', 2: '母', 3: '未知'}[value] ?? '$value';
    case 'sterilized':
      return {0: '未绝育', 1: '已绝育'}[value] ?? '$value';
    case 'toiletFreq':
      return {1: '每1小时', 2: '每2小时', 3: '每4小时', 4: '每8小时'}[value] ?? '$value';
    case 'activityLevel':
      return {1: '高', 2: '中', 3: '低'}[value] ?? '$value';
    case 'careInterval':
      return {1: '<1小时', 2: '1-4小时', 3: '4-8小时', 4: '不可离开'}[value] ?? '$value';
    case 'medicationNeeds':
      return {0: '无', 1: '按时服药', 2: '需要营养品'}[value] ?? '$value';
    case 'friendlyKids':
    case 'friendlyDogs':
    case 'friendlyCats':
    case 'pottyTime':
      return {0: '否', 1: '是'}[value] ?? '$value';
    case 'weight':
      return '${value}kg';
    default:
      return '$value';
  }
}

int _countFilled(List<FlowQuestion> questions, Map<String, dynamic> answers) {
  int done = 0;
  for (final q in questions) {
    final v = answers[q.id];
    if (v != null && v != '' && !(v is List && v.isEmpty)) done++;
  }
  return done;
}

// ── Page ─────────────────────────────────────────────────────────

class PetAddPage extends ConsumerStatefulWidget {
  final String? id; // null = 新增，非 null = 编辑
  const PetAddPage({super.key, this.id});

  @override
  ConsumerState<PetAddPage> createState() => _PetAddPageState();
}

class _PetAddPageState extends ConsumerState<PetAddPage> {
  // 视图：'flow' | 'summary'
  String _view = 'flow';
  // 当前 flow 面向哪个板块
  String _activeSection = 'basic';

  String? _petId;
  bool _saving = false;

  // 各板块答案
  final Map<String, dynamic> _basicAnswers = {};
  final Map<String, dynamic> _careAnswers = {};
  final Map<String, dynamic> _behaviorAnswers = {};

  // 品种列表（picker 注入）
  List<FlowOption> _breeds = [];

  // 展开状态
  bool _careOpen = true;
  bool _behaviorOpen = true;

  @override
  void initState() {
    super.initState();
    _petId = widget.id;
    _loadBreeds();
    if (widget.id != null) {
      _loadExistingPet();
    }
  }

  // ── 品种加载 ─────────────────────────────────────────────────

  Future<void> _loadBreeds() async {
    try {
      final res =
          await ref.read(dioProvider).post(LibApi.breeds, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _breeds = raw.map((e) {
            final m = e as Map<String, dynamic>;
            return FlowOption(
              label: m['name'] as String? ?? '',
              value: m['id'],
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  // ── 加载已有宠物（编辑模式）────────────────────────────────────

  Future<void> _loadExistingPet() async {
    try {
      final res = await ref.read(dioProvider).post(
        PetApi.getById,
        data: {'id': widget.id},
      );
      final data = res.data as Map<String, dynamic>?;
      final p = data?['content'] as Map<String, dynamic>?;
      if (p == null || !mounted) return;

      setState(() {
        _view = 'summary';
        _petId = p['id']?.toString() ?? widget.id;
        // 基础
        _basicAnswers['species'] = (p['species'] as num?)?.toInt();
        _basicAnswers['name'] = p['name'];
        _basicAnswers['birthDate'] =
            p['birthDate'] ?? p['birthday'];
        _basicAnswers['weight'] =
            p['weight'] != null ? '${p['weight']}' : null;
        _basicAnswers['gender'] = (p['gender'] as num?)?.toInt();
        _basicAnswers['sterilized'] =
            (p['sterilized'] as num?)?.toInt();
        _basicAnswers['breedId'] = p['breedId'];
        // 护理
        _careAnswers['toiletFreq'] =
            (p['toiletFreq'] as num?)?.toInt();
        _careAnswers['activityLevel'] =
            (p['activityLevel'] as num?)?.toInt();
        _careAnswers['careInterval'] =
            (p['careInterval'] as num?)?.toInt();
        _careAnswers['medicationNeeds'] =
            (p['medicationNeeds'] as num?)?.toInt();
        _careAnswers['healthDesc'] = p['healthDesc'];
        // 行为
        _behaviorAnswers['friendlyKids'] =
            (p['friendlyKids'] as num?)?.toInt();
        _behaviorAnswers['friendlyDogs'] =
            (p['friendlyDogs'] as num?)?.toInt();
        _behaviorAnswers['friendlyCats'] =
            (p['friendlyCats'] as num?)?.toInt();
        _behaviorAnswers['pottyTime'] =
            (p['pottyTime'] as num?)?.toInt();
        _behaviorAnswers['otherDesc'] = p['otherDesc'];
      });
    } catch (_) {}
  }

  // ── API 保存 ─────────────────────────────────────────────────

  Future<void> _createPet(Map<String, dynamic> answers) async {
    setState(() => _saving = true);
    try {
      final payload = {
        'species': answers['species'],
        'name': answers['name'],
        'birthday': answers['birthDate'],
        'weight': double.tryParse('${answers['weight'] ?? ''}'),
        'gender': answers['gender'],
        'sterilized': answers['sterilized'],
      };
      if (answers['breedId'] != null && answers['breedId'] != '') {
        final bid = answers['breedId'];
        if (bid is int) {
          payload['breedId'] = bid;
        } else {
          final n = int.tryParse('$bid');
          if (n != null) {
            payload['breedId'] = n;
          } else {
            payload['breedName'] = bid;
          }
        }
      }
      payload.removeWhere((_, v) => v == null);

      final res = await ref.read(dioProvider).post(
        PetApi.create,
        data: payload,
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'];
      final newId = content is Map
          ? content['id']?.toString()
          : content?.toString();
      if (newId != null && mounted) {
        setState(() => _petId = newId);
      }
      if (mounted) {
        setState(() {
          _basicAnswers.addAll(answers);
          _view = 'summary';
        });
        _showToast('宠物信息已保存');
      }
    } catch (_) {
      if (mounted) _showToast('保存失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updatePet(Map<String, dynamic> fields) async {
    if (_petId == null) return;
    setState(() => _saving = true);
    try {
      final payload = Map<String, dynamic>.from(fields)
        ..['id'] = _petId
        ..removeWhere((_, v) => v == null);

      // weight 特殊处理
      if (payload.containsKey('weight')) {
        payload['weight'] =
            double.tryParse('${payload['weight']}') ??
                payload['weight'];
      }
      if (payload.containsKey('birthDate')) {
        payload['birthday'] = payload.remove('birthDate');
      }

      await ref.read(dioProvider).post(PetApi.update, data: payload);
      if (mounted) _showToast('信息已保存');
    } catch (_) {
      if (mounted) _showToast('保存失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ── FlowAsk 完成回调 ─────────────────────────────────────────

  void _onFlowFinish(
      Map<String, dynamic> answers, {
      bool skipped = false,
    }) {
    if (skipped && _activeSection != 'basic') {
      setState(() => _view = 'summary');
      return;
    }

    switch (_activeSection) {
      case 'basic':
        _basicAnswers.addAll(answers);
        if (_petId == null) {
          _createPet(answers);
        } else {
          _updatePet(answers).then((_) {
            if (mounted) setState(() => _view = 'summary');
          });
        }
      case 'care':
        _careAnswers.addAll(answers);
        if (_petId != null) {
          _updatePet(answers).then((_) {
            if (mounted) setState(() => _view = 'summary');
          });
        } else {
          setState(() => _view = 'summary');
        }
      case 'behavior':
        _behaviorAnswers.addAll(answers);
        if (_petId != null) {
          _updatePet(answers).then((_) {
            if (mounted) setState(() => _view = 'summary');
          });
        } else {
          setState(() => _view = 'summary');
        }
    }
  }

  // ── 构建带品种选项的 basic questions ─────────────────────────

  List<FlowQuestion> _getBasicQuestions() {
    return _kBasicQuestions.map((q) {
      if (q.id == 'breedId') {
        // 注入全量品种列表（可按 _basicAnswers['species'] 过滤）
        return q.copyWithOptions(_breeds);
      }
      return q;
    }).toList();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppNavBar(
        title: _view == 'flow'
            ? (_activeSection == 'basic'
                ? (isEdit ? '编辑基本信息' : '添加宠物')
                : _activeSection == 'care'
                    ? '护理信息'
                    : '附加信息')
            : (isEdit ? '编辑宠物' : '完善资料'),
      ),
      body: _view == 'flow'
          ? _buildFlowView()
          : _buildSummaryView(),
    );
  }

  // ── Flow 视图 ─────────────────────────────────────────────────

  Widget _buildFlowView() {
    final (questions, answers) = switch (_activeSection) {
      'care' => (_kCareQuestions.toList(), _careAnswers),
      'behavior' => (_kBehaviorQuestions.toList(), _behaviorAnswers),
      _ => (_getBasicQuestions(), _basicAnswers),
    };

    return Stack(
      children: [
        FlowAskWidget(
          key: ValueKey(_activeSection),
          questions: questions,
          initialAnswers: answers,
          onFinish: (a, {bool skipped = false}) =>
              _onFlowFinish(a, skipped: skipped),
        ),
        if (_saving)
          const ColoredBox(
            color: Color(0x66FFFFFF),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  // ── Summary 视图 ──────────────────────────────────────────────

  Widget _buildSummaryView() {
    final basicFilled =
        _countFilled(_kBasicQuestions, _basicAnswers);
    final careFilled =
        _countFilled(_kCareQuestions, _careAnswers);
    final behaviorFilled =
        _countFilled(_kBehaviorQuestions, _behaviorAnswers);

    final basicPct =
        (basicFilled / _kBasicQuestions.length * 100).round().toDouble();
    final carePct =
        (careFilled / _kCareQuestions.length * 100).round().toDouble();
    final behaviorPct =
        (behaviorFilled / _kBehaviorQuestions.length * 100).round().toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        children: [
          // 基础信息卡
          _SectionCard(
            title: '基本资料',
            progress: basicPct,
            isOpen: true,
            onToggle: () {},
            onEdit: () => _openSection('basic'),
            fields: _buildFieldRows(
                _kBasicQuestions, _basicAnswers),
          ),
          const SizedBox(height: 10),
          // 护理信息
          _SectionCard(
            title: '护理信息',
            progress: carePct,
            isOpen: _careOpen,
            onToggle: () =>
                setState(() => _careOpen = !_careOpen),
            onEdit: () => _openSection('care'),
            fields: _buildFieldRows(
                _kCareQuestions, _careAnswers),
          ),
          const SizedBox(height: 10),
          // 附加信息
          _SectionCard(
            title: '附加信息',
            progress: behaviorPct,
            isOpen: _behaviorOpen,
            onToggle: () =>
                setState(() => _behaviorOpen = !_behaviorOpen),
            onEdit: () => _openSection('behavior'),
            fields: _buildFieldRows(
                _kBehaviorQuestions, _behaviorAnswers),
          ),
        ],
      ),
    );
  }

  void _openSection(String section) {
    setState(() {
      _activeSection = section;
      _view = 'flow';
    });
  }

  List<_FieldRow> _buildFieldRows(
      List<FlowQuestion> questions,
      Map<String, dynamic> answers) {
    return questions.map((q) {
      final raw = answers[q.id];
      String display = '';
      if (q.id == 'breedId' && raw != null) {
        display = _breeds
            .where((b) => b.value == raw)
            .map((b) => b.label)
            .firstOrNull ?? '$raw';
      } else {
        display = _labelOf(q.id, raw);
      }
      return _FieldRow(
          label: q.title2 ?? q.title,
          value: display);
    }).toList();
  }
}

// ── Section 卡片 Widget ───────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final double progress;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final List<_FieldRow> fields;

  const _SectionCard({
    required this.title,
    required this.progress,
    required this.isOpen,
    required this.onToggle,
    required this.onEdit,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                CircleProgress(value: progress, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF222222))),
                      Text('完成度 ${progress.round()}%',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888))),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('编辑',
                        style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF7E51))),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedRotation(
                    turns: isOpen ? 0 : 0.5,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 22,
                        color: Color(0xFF888888)),
                  ),
                ),
              ],
            ),
          ),
          // 展开内容
          if (isOpen && fields.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            ...fields.map((f) => _buildFieldRow(f)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldRow(_FieldRow f) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(f.label,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF666666))),
          ),
          Text(
            f.value.isNotEmpty ? f.value : '未填写',
            style: TextStyle(
              fontSize: 14,
              color: f.value.isNotEmpty
                  ? const Color(0xFF333333)
                  : const Color(0xFFCCCCCC),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow {
  final String label;
  final String value;
  const _FieldRow({required this.label, required this.value});
}
