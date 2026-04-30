import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

import '../../../manage/presentation/pages/location_pick_page.dart';

const _kPrimary = Color(0xFFFF9E4A);

/// 服务者档案 / 修改个人信息页
class ProviderProfilePage extends ConsumerStatefulWidget {
  const ProviderProfilePage({super.key});

  @override
  ConsumerState<ProviderProfilePage> createState() =>
      _ProviderProfilePageState();
}

class _ProviderProfilePageState extends ConsumerState<ProviderProfilePage> {
  // ── 表单 ───────────────────────────────────────────────────────
  String? _applicationId;
  final TextEditingController _bioCtrl = TextEditingController();
  final TextEditingController _wechatCtrl = TextEditingController();
  final TextEditingController _professionCtrl = TextEditingController();

  String _applicantType = '1'; // 1=个人 2=商家
  String _serviceAddress = '';
  String _latitude = '';
  String _longitude = '';

  final Set<String> _petTypes = {};
  bool _hasPetExperience = false;
  bool _puppyExperience = false;
  bool _seniorDogExperience = false;

  // ── 字典 ───────────────────────────────────────────────────────
  List<({String value, String label, String icon})> _petTypeOpts = [
    (value: '1', label: '狗狗', icon: '🐶'),
    (value: '2', label: '猫猫', icon: '🐱'),
  ];

  // ── 评价 ───────────────────────────────────────────────────────
  double _avgScore = 0;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  // ── 状态 ───────────────────────────────────────────────────────
  bool _loading = true;
  bool _saving = false;
  bool _aiLoading = false;
  int? _ownerId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _wechatCtrl.dispose();
    _professionCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([_loadDict(), _loadProfile()]);
    if (_ownerId != null) await _loadReviews(_ownerId!);
    if (mounted) setState(() => _loading = false);
  }

  // ─── 字典 ──────────────────────────────────────────────────────

  Future<void> _loadDict() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(LibApi.dictBatchList, data: ['pet_species']);
      final content = res.data['content'];
      if (content is! Map) return;
      final list = content['pet_species'];
      if (list is! List || list.isEmpty) return;
      const iconMap = {'1': '🐶', '2': '🐱'};
      setState(() {
        _petTypeOpts = list.map((e) {
          final m = e as Map;
          final v = m['key']?.toString() ?? '';
          return (
            value: v,
            label: m['value']?.toString() ?? '',
            icon: iconMap[v] ?? '🐾',
          );
        }).toList();
      });
    } catch (_) {}
  }

  // ─── 加载详情 ──────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(PetsitterApi.queryApplication, data: {});
      final data = res.data['content'];
      if (data is! Map) return;

      final info = (data['info'] as Map?) ?? const {};
      final application = (data['application'] as Map?) ?? const {};

      final petTypes = (info['petTypes']?.toString() ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();

      _applicationId = application['id']?.toString();
      _bioCtrl.text = data['description']?.toString() ??
          application['description']?.toString() ??
          '';
      _applicantType = application['applicantType']?.toString() ?? '1';
      _wechatCtrl.text = info['wechatId']?.toString() ?? '';
      _serviceAddress = info['serviceAddress']?.toString() ?? '';
      _latitude = info['latitude']?.toString() ?? '';
      _longitude = info['longitude']?.toString() ?? '';
      _professionCtrl.text = info['profession']?.toString() ?? '';
      _petTypes
        ..clear()
        ..addAll(petTypes);
      _hasPetExperience = info['hasPetExperience'] == true;
      _puppyExperience = info['puppyExperience'] == true;
      _seniorDogExperience = info['seniorDogExperience'] == true;

      _ownerId = _resolveOwnerId(data);

      if (mounted) setState(() {});
    } catch (_) {}
  }

  int? _resolveOwnerId(Map data) {
    final info = (data['info'] as Map?) ?? const {};
    final application = (data['application'] as Map?) ?? const {};
    final candidates = <dynamic>[
      application['userId'],
      application['serverId'],
      application['providerId'],
      info['userId'],
      info['serverId'],
      info['providerId'],
      data['userId'],
      data['serverId'],
      application['id'],
      info['id'],
    ];
    for (final v in candidates) {
      final n = int.tryParse(v?.toString() ?? '');
      if (n != null && n > 0) return n;
    }
    return null;
  }

  // ─── 评价 ──────────────────────────────────────────────────────

  Future<void> _loadReviews(int ownerId) async {
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        dio.post(CommentApi.avgScoreByServer, data: {'serverId': ownerId}),
        dio.post(CommentApi.listByUserId, data: {'userId': ownerId}),
      ]);
      final avg = results[0].data['content'];
      _avgScore = (avg is num) ? avg.toDouble() : 0;
      final raw = results[1].data['content'];
      if (raw is List) {
        _reviews = raw.cast<Map<String, dynamic>>();
        _reviewCount = _reviews.length;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  // ─── AI ────────────────────────────────────────────────────────

  Future<void> _onAiPolish() async {
    final text = _bioCtrl.text.trim();
    if (text.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先输入至少50字的内容')),
      );
      return;
    }
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(AiApi.polish, data: {'content': text});
      final out = _extractAiText(res.data);
      if (out.isNotEmpty) {
        _bioCtrl.text = out;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI润色失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _onAiGenerate() async {
    if (_aiLoading) return;
    setState(() => _aiLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final ctxParts = <String>[
        _applicantType == '2' ? '商家' : '个人',
        if (_professionCtrl.text.trim().isNotEmpty)
          '职业：${_professionCtrl.text.trim()}',
        if (_petTypes.isNotEmpty)
          '养宠类型：${_petTypeOpts.where((o) => _petTypes.contains(o.value)).map((o) => o.label).join('、')}',
      ];
      final content =
          ctxParts.isEmpty ? '宠物陪伴师个人简介' : ctxParts.join('，');
      final res = await dio.post(AiApi.generate, data: {'content': content});
      final out = _extractAiText(res.data);
      if (out.isNotEmpty) {
        _bioCtrl.text = out;
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI生成失败')),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  String _extractAiText(dynamic resp) {
    if (resp == null) return '';
    if (resp is String) return resp;
    if (resp is Map) {
      for (final k in ['content', 'data', 'result', 'message']) {
        final v = resp[k];
        if (v is String && v.trim().isNotEmpty) return v;
        if (v is Map) {
          for (final kk in ['content', 'text', 'description', 'result', 'value']) {
            final vv = v[kk];
            if (vv is String && vv.trim().isNotEmpty) return vv;
          }
        }
      }
    }
    return '';
  }

  // ─── 选地址 ────────────────────────────────────────────────────

  Future<void> _onPickLocation() async {
    final initLat = double.tryParse(_latitude);
    final initLng = double.tryParse(_longitude);
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickPage(
          initialLat: initLat,
          initialLng: initLng,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _serviceAddress = result.address;
      _latitude = result.latitude.toString();
      _longitude = result.longitude.toString();
    });
  }

  // ─── 保存 ──────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (_saving) return;
    if (_serviceAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择服务地址')),
      );
      return;
    }
    if (_petTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择养宠类型')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(PetsitterApi.saveOrUpdateApplication, data: {
        if (_applicationId != null) 'id': _applicationId,
        'description': _bioCtrl.text,
        'application': {
          if (_applicationId != null) 'id': _applicationId,
          'applicantType': _applicantType,
        },
        'info': {
          'wechatId': _wechatCtrl.text.trim(),
          'serviceAddress': _serviceAddress,
          'latitude': _latitude,
          'longitude': _longitude,
          'profession': _professionCtrl.text.trim(),
          'petTypes': _petTypes.join(','),
          'hasPetExperience': _hasPetExperience,
          'puppyExperience': _puppyExperience,
          'seniorDogExperience': _seniorDogExperience,
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存成功')),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const AppNavBar(title: '修改个人信息'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Column(
                children: [
                  _bioCard(),
                  _roleCard(),
                  _reviewCard(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: FooterBar(
        buttonText: '保存信息',
        buttonDisabled: _saving,
        onButtonTap: _saving ? null : _onSave,
      ),
    );
  }

  // ── 个人简介卡 ────────────────────────────────────────────────

  Widget _bioCard() {
    final len = _bioCtrl.text.length;
    return _card(
      children: [
        _sectionLabel('个人简介', required: true),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE3C7)),
              ),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 6,
                maxLength: 500,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '编辑50字时，即可使用下方AI写作进行内容润色…',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
                  contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 24),
                  border: InputBorder.none,
                  counterText: '',
                ),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF333333), height: 1.5),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 6,
              child: Text(
                '$len/500',
                style:
                    const TextStyle(fontSize: 11, color: Color(0xFF999999)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _aiBtn(label: 'AI润色', onTap: _onAiPolish),
            const SizedBox(width: 12),
            _aiBtn(label: 'AI生成', onTap: _onAiGenerate),
          ],
        ),
      ],
    );
  }

  Widget _aiBtn({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _aiLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF9E4A), Color(0xFFFF7E51)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_aiLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            else
              const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── 角色卡 ───────────────────────────────────────────────────

  Widget _roleCard() {
    return _card(children: [
      _sectionLabel('角色', required: true),
      const SizedBox(height: 8),
      Row(
        children: [
          _toggleBtn(
              value: '1',
              label: '个人',
              active: _applicantType == '1',
              onTap: () => setState(() => _applicantType = '1')),
          const SizedBox(width: 8),
          _toggleBtn(
              value: '2',
              label: '商家',
              active: _applicantType == '2',
              onTap: () => setState(() => _applicantType = '2')),
        ],
      ),
      _divider(),

      // 微信
      _formItem(
        label: '微信号',
        hint: '选填',
        child: TextField(
          controller: _wechatCtrl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: '请输入',
            hintStyle:
                TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      _divider(),

      // 服务地址
      _sectionLabel('服务地址', required: true),
      const SizedBox(height: 4),
      const Text('位置错误会导致用户找不到该地点，请仔细确认',
          style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _onPickLocation,
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt_outlined,
                  size: 28, color: _kPrimary),
              SizedBox(height: 6),
              Text('选择位置',
                  style: TextStyle(fontSize: 13, color: _kPrimary)),
            ],
          ),
        ),
      ),
      if (_serviceAddress.isNotEmpty) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _serviceAddress,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF333333)),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
          ],
        ),
      ],
      _divider(),

      // 职业
      _formItem(
        label: '职业/工作背景',
        child: TextField(
          controller: _professionCtrl,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: '如：北京朝阳宠物之家',
            hintStyle:
                TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      _divider(),

      // 养宠类型
      Row(
        children: [
          const Text('* ',
              style:
                  TextStyle(color: Color(0xFFFF4D4F), fontSize: 14)),
          const Text('养宠类型',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333))),
          const SizedBox(width: 4),
          const Text('（多选）',
              style:
                  TextStyle(fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _petTypeOpts.map((o) {
          final active = _petTypes.contains(o.value);
          return GestureDetector(
            onTap: () => setState(() {
              if (active) {
                _petTypes.remove(o.value);
              } else {
                _petTypes.add(o.value);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active ? _kPrimary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active
                        ? _kPrimary
                        : const Color(0xFFDDDDDD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(o.icon,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(o.label,
                      style: TextStyle(
                          fontSize: 13,
                          color: active
                              ? Colors.white
                              : const Color(0xFF666666),
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      _divider(),

      _switchRow('是否有过养宠经验', _hasPetExperience,
          (v) => setState(() => _hasPetExperience = v)),
      _switchRow('是否具备幼犬服务经验', _puppyExperience,
          (v) => setState(() => _puppyExperience = v)),
      _switchRow('是否具备老年犬服务经验', _seniorDogExperience,
          (v) => setState(() => _seniorDogExperience = v)),
    ]);
  }

  // ── 评价卡 ───────────────────────────────────────────────────

  Widget _reviewCard() {
    return _card(children: [
      Row(
        children: [
          const Text('我的评价',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333))),
          const Spacer(),
          if (_avgScore > 0) ...[
            const Icon(Icons.star, color: _kPrimary, size: 14),
            const SizedBox(width: 4),
            Text(_avgScore.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF333333))),
            const SizedBox(width: 6),
          ],
          Text('共 $_reviewCount 条',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF999999))),
        ],
      ),
      if (_reviews.isEmpty) ...[
        const SizedBox(height: 24),
        const Center(
          child: Text('暂无评价',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF999999))),
        ),
        const SizedBox(height: 16),
      ] else
        ..._reviews.take(5).map((r) {
          final tail = (r['customerId']?.toString() ?? '');
          final t = tail.length >= 4 ? tail.substring(tail.length - 4) : tail;
          final userName = r['anonymous'] == true
              ? '匿名用户'
              : (t.isNotEmpty ? '用户$t' : '匿名用户');
          final score = (r['overallScore'] as num?)?.toDouble() ?? 0;
          final content = r['content']?.toString() ?? '';
          final time = r['commentTime']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(userName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333))),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < score.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 13,
                          color: i < score.round()
                              ? _kPrimary
                              : const Color(0xFFDDDDDD),
                        ),
                      ),
                    ),
                  ],
                ),
                if (content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(content,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF666666),
                          height: 1.5)),
                ],
                if (time.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF999999))),
                ],
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
              ],
            ),
          );
        }),
    ]);
  }

  // ─── UI helpers ────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionLabel(String text, {bool required = false}) {
    return Row(
      children: [
        if (required)
          const Text('* ',
              style:
                  TextStyle(color: Color(0xFFFF4D4F), fontSize: 14)),
        Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333))),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Divider(height: 1, color: Color(0xFFF0F0F0)),
      );

  Widget _toggleBtn({
    required String value,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? _kPrimary : const Color(0xFFDDDDDD)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color:
                    active ? Colors.white : const Color(0xFF666666),
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _formItem({
    required String label,
    String? hint,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF333333))),
        if (hint != null) ...[
          const SizedBox(width: 4),
          Text('（$hint）',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF999999))),
        ],
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF333333))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _kPrimary,
          ),
        ],
      ),
    );
  }
}
