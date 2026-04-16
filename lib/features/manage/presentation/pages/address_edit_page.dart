import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/footer_bar.dart';
import 'location_pick_page.dart';

// ── 表单状态 ──────────────────────────────────────────────────────

class _FormState {
  String contactName = '';
  String contactPhone = '';
  String province = '';
  String city = '';
  String district = '';
  String detail = '';
  String country = '中国';
  String latitude = '';
  String longitude = '';
  int isDefault = 0;
}

// ── 校验规则 ──────────────────────────────────────────────────────

final _mobileRE = RegExp(r'^1\d{10}$');
final _landlineRE = RegExp(r'^0\d{2,3}-?\d{7,8}(-\d{1,6})?$');

String _validateContactName(String v) {
  final t = v.trim();
  if (t.isEmpty) return '请填写联系人姓名';
  if (t.length < 2) return '联系人姓名至少2个字符';
  if (t.length > 20) return '联系人姓名不能超过20个字符';
  return '';
}

String _validateContactPhone(String v) {
  final t = v.trim();
  if (t.isEmpty) return '请填写联系方式';
  if (_mobileRE.hasMatch(t) || _landlineRE.hasMatch(t)) return '';
  return '请输入正确的手机号或座机号（如：010-12345678）';
}

String _validateDetail(String v) {
  final t = v.trim();
  if (t.isEmpty) return '请填写详细地址';
  if (t.length < 5) return '详细地址至少5个字符';
  if (t.length > 200) return '详细地址不能超过200个字符';
  return '';
}

// ── Page ─────────────────────────────────────────────────────────

class AddressEditPage extends ConsumerStatefulWidget {
  final String? id;
  const AddressEditPage({super.key, this.id});

  @override
  ConsumerState<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends ConsumerState<AddressEditPage> {
  final _form = _FormState();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();

  final _errors = <String, String>{};
  bool _saving = false;
  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) _loadDetail(widget.id!);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────

  Future<void> _loadDetail(String id) async {
    setState(() => _loadingDetail = true);
    try {
      final res =
          await ref.read(dioProvider).post(AddressApi.get, data: {'id': id});
      final data = res.data as Map<String, dynamic>?;
      final success = data?['success'] == true || data?['code'] == 200;
      if (success && mounted) {
        final addr = data?['content'] as Map<String, dynamic>? ?? {};
        setState(() {
          _form.contactName = addr['contactName'] as String? ?? '';
          _form.contactPhone = addr['contactPhone'] as String? ?? '';
          _form.province = addr['province'] as String? ?? '';
          _form.city = addr['city'] as String? ?? '';
          _form.district = addr['district'] as String? ?? '';
          _form.detail = addr['detail'] as String? ?? '';
          _form.country = addr['country'] as String? ?? '中国';
          _form.latitude = addr['latitude']?.toString() ?? '';
          _form.longitude = addr['longitude']?.toString() ?? '';
          _form.isDefault = (addr['isDefault'] as num?)?.toInt() ?? 0;

          _nameCtrl.text = _form.contactName;
          _phoneCtrl.text = _form.contactPhone;
          _detailCtrl.text = _form.detail;
        });
      }
    } catch (_) {
      if (mounted) _showToast('加载地址失败');
    } finally {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // ── 校验 ────────────────────────────────────────────────────────

  bool _validate() {
    final errs = <String, String>{};

    final nameErr = _validateContactName(_nameCtrl.text);
    if (nameErr.isNotEmpty) errs['contactName'] = nameErr;

    final phoneErr = _validateContactPhone(_phoneCtrl.text);
    if (phoneErr.isNotEmpty) errs['contactPhone'] = phoneErr;

    if (_form.province.trim().isEmpty) errs['province'] = '请选择省份';
    if (_form.city.trim().isEmpty) errs['city'] = '请选择城市';
    if (_form.district.trim().isEmpty) errs['district'] = '请选择区县';

    final detailErr = _validateDetail(_detailCtrl.text);
    if (detailErr.isNotEmpty) errs['detail'] = detailErr;

    setState(() => _errors.addAll(errs));
    if (errs.isNotEmpty) {
      _showToast(errs.values.first);
    }
    return errs.isEmpty;
  }

  Future<void> _onSave() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();

    // 更新表单值（确保 controller 中的最新值同步）
    _form.contactName = _nameCtrl.text;
    _form.contactPhone = _phoneCtrl.text;
    _form.detail = _detailCtrl.text;

    if (!_validate()) return;

    setState(() => _saving = true);
    try {
      final params = {
        'contactName': _form.contactName.trim(),
        'contactPhone': _form.contactPhone.trim(),
        'country': _form.country,
        'province': _form.province,
        'city': _form.city,
        'district': _form.district,
        'detail': _form.detail.trim(),
        'latitude': _form.latitude,
        'longitude': _form.longitude,
        'isDefault': _form.isDefault,
        'geoType': 3,
      };

      if (widget.id != null) params['id'] = widget.id as dynamic;

      final endpoint =
          widget.id != null ? AddressApi.update : AddressApi.create;
      final res =
          await ref.read(dioProvider).post(endpoint, data: params);
      final data = res.data as Map<String, dynamic>?;
      if ((data?['success'] == true || data?['code'] == 200) && mounted) {
        _showToast(widget.id != null ? '修改成功' : '添加成功');
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.pop();
      }
    } catch (_) {
      // errors handled by interceptor
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 地区选择 ────────────────────────────────────────────────────

  void _onPickRegion() {
    final pCtrl = TextEditingController(text: _form.province);
    final cCtrl = TextEditingController(text: _form.city);
    final dCtrl = TextEditingController(text: _form.district);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _RegionPickerSheet(
          pCtrl: pCtrl,
          cCtrl: cCtrl,
          dCtrl: dCtrl,
          onConfirm: () {
            setState(() {
              _form.province = pCtrl.text.trim();
              _form.city = cCtrl.text.trim();
              _form.district = dCtrl.text.trim();
              _errors.remove('province');
              _errors.remove('city');
              _errors.remove('district');
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    ).whenComplete(() {
      pCtrl.dispose();
      cCtrl.dispose();
      dCtrl.dispose();
    });
  }

  // ── 地图选点 ─────────────────────────────────────────────────────

  Future<void> _onPickLocation() async {
    final initLat = double.tryParse(_form.latitude);
    final initLng = double.tryParse(_form.longitude);

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
      _form.latitude = result.latitude.toString();
      _form.longitude = result.longitude.toString();
      if (result.province.isNotEmpty) {
        _form.province = result.province;
        _errors.remove('province');
      }
      if (result.city.isNotEmpty) {
        _form.city = result.city;
        _errors.remove('city');
      }
      if (result.district.isNotEmpty) {
        _form.district = result.district;
        _errors.remove('district');
      }
    });
  }

  // ── 工具 ────────────────────────────────────────────────────────

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.id != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppNavBar(
        title: isEdit ? '编辑地址' : '新增地址',
        showBack: true,
      ),
      bottomNavigationBar: FooterBar(
        buttonText: '保存',
        buttonDisabled: _saving,
        onButtonTap: _onSave,
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 联系人 + 联系方式 ──────────────────────────
                  _FormCard(children: [
                    _FieldRow(
                      label: '联系人',
                      required: true,
                      child: TextField(
                        controller: _nameCtrl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF666666)),
                        decoration: const InputDecoration(
                          hintText: '请输入联系人姓名',
                          hintStyle: TextStyle(
                              fontSize: 15, color: Color(0xFFBBBBBB)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) =>
                            setState(() => _errors.remove('contactName')),
                      ),
                    ),
                    if (_errors['contactName'] != null)
                      _ErrorTip(_errors['contactName']!),
                    const _RowDivider(),
                    _FieldRow(
                      label: '联系方式',
                      required: true,
                      child: TextField(
                        controller: _phoneCtrl,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xFF666666)),
                        decoration: const InputDecoration(
                          hintText: '请输入手机号或座机号',
                          hintStyle: TextStyle(
                              fontSize: 15, color: Color(0xFFBBBBBB)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) =>
                            setState(() => _errors.remove('contactPhone')),
                      ),
                    ),
                    if (_errors['contactPhone'] != null)
                      _ErrorTip(_errors['contactPhone']!),
                  ]),

                  const SizedBox(height: 16),

                  // ── 所在地区 + 详细地址 ────────────────────────
                  _FormCard(children: [
                    // 地区行
                    _FieldRow(
                      label: '所在地区',
                      required: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 地图选点按钮
                          GestureDetector(
                            onTap: _onPickLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF7E51).withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: const Color(0xFFFF7E51)
                                        .withAlpha(80),
                                    width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.map_outlined,
                                      size: 13,
                                      color: Color(0xFFFF7E51)),
                                  SizedBox(width: 3),
                                  Text('地图选点',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFFF7E51))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 手动输入
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _onPickRegion,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 130),
                                    child: Text(
                                      _form.province.isEmpty &&
                                              _form.city.isEmpty &&
                                              _form.district.isEmpty
                                          ? '手动输入'
                                          : '${_form.province} ${_form.city} ${_form.district}',
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: _form.province.isEmpty
                                            ? const Color(0xFFBBBBBB)
                                            : const Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: Color(0xFFCCCCCC),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errors['province'] != null ||
                        _errors['city'] != null ||
                        _errors['district'] != null)
                      _ErrorTip(_errors['province'] ??
                          _errors['city'] ??
                          _errors['district']!),

                    // 显示已选坐标
                    if (_form.latitude.isNotEmpty &&
                        _form.longitude.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.my_location,
                                size: 12, color: Color(0xFF999999)),
                            const SizedBox(width: 4),
                            Text(
                              '${double.parse(_form.latitude).toStringAsFixed(5)}, '
                              '${double.parse(_form.longitude).toStringAsFixed(5)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      ),

                    const _RowDivider(),

                    // 详细地址
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                '详细地址',
                                style: TextStyle(
                                    fontSize: 15, color: Color(0xFF333333)),
                              ),
                              Text(
                                ' *',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F7FC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: TextField(
                              controller: _detailCtrl,
                              maxLines: 3,
                              maxLength: 200,
                              style: const TextStyle(
                                  fontSize: 15, color: Color(0xFF666666)),
                              decoration: const InputDecoration(
                                hintText: '街道、楼栋、门牌号等',
                                hintStyle: TextStyle(
                                    fontSize: 15, color: Color(0xFFBBBBBB)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                counterText: '',
                              ),
                              onChanged: (_) =>
                                  setState(() => _errors.remove('detail')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errors['detail'] != null)
                      _ErrorTip(_errors['detail']!),
                  ]),
                ],
              ),
            ),
    );
  }
}

// ── 地区选择底部弹窗 ────────────────────────────────────────────

class _RegionPickerSheet extends StatelessWidget {
  final TextEditingController pCtrl;
  final TextEditingController cCtrl;
  final TextEditingController dCtrl;
  final VoidCallback onConfirm;

  const _RegionPickerSheet({
    required this.pCtrl,
    required this.cCtrl,
    required this.dCtrl,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择所在地区',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      size: 20, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          _SheetField(label: '省份', controller: pCtrl, hint: '如：广东省'),
          const SizedBox(height: 10),
          _SheetField(label: '城市', controller: cCtrl, hint: '如：深圳市'),
          const SizedBox(height: 10),
          _SheetField(label: '区/县', controller: dCtrl, hint: '如：南山区'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9E4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('确认', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    const TextStyle(fontSize: 15, color: Color(0xFFBBBBBB)),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 共享小组件 ──────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final List<Widget> children;
  const _FormCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _FieldRow({
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333)),
              ),
              if (required)
                const Text(' *',
                    style: TextStyle(fontSize: 15, color: Colors.red)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFF0F0F0));
}

class _ErrorTip extends StatelessWidget {
  final String text;
  const _ErrorTip(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFFF87171)),
        ),
      ),
    );
  }
}
