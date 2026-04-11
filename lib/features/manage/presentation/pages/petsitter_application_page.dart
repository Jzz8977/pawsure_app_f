import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

// ─── Models ────────────────────────────────────────────────────

class _Opt {
  final String label;
  final String value;
  final String icon;
  const _Opt({required this.label, required this.value, this.icon = ''});
}

class _Photo {
  final String? local;
  final String? url;
  const _Photo({this.local, this.url});
  String get display => url ?? local ?? '';
  bool get isUploaded => url != null && url!.isNotEmpty;
}

// ─── Page ──────────────────────────────────────────────────────

class PetsitterApplicationPage extends ConsumerStatefulWidget {
  final String? id;
  final String? mode;
  const PetsitterApplicationPage({super.key, this.id, this.mode});

  @override
  ConsumerState<PetsitterApplicationPage> createState() =>
      _PetsitterApplicationPageState();
}

class _PetsitterApplicationPageState
    extends ConsumerState<PetsitterApplicationPage> {
  // ── Step / meta state ─────────────────────────────────────────
  int _step = 0;
  bool _isReadOnly = false;
  int _auditStatus = -1; // -1=draft, 0=pending, 1=passed, 2=rejected
  String? _applicationId;
  bool _loading = false;
  bool _saving = false;
  bool _submitting = false;
  bool _uploading = false;

  // ── Dict options ──────────────────────────────────────────────
  List<_Opt> _serviceTypeOpts = [];
  List<_Opt> _petTypeOpts = [];
  List<_Opt> _petSizeOpts = [];
  List<_Opt> _residenceTypeOpts = [];
  List<_Opt> _livingConditionOpts = [];
  List<_Opt> _businessRelationOpts = [];

  // ── Text controllers ──────────────────────────────────────────
  late TextEditingController _serviceNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _wechatCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _fosterYearsCtrl;
  late TextEditingController _professionCtrl;
  late TextEditingController _capacityCtrl;
  late TextEditingController _areaCtrl;

  // ── Selections ────────────────────────────────────────────────
  String _applicantType = '1';
  String _serviceType = '';
  final Set<String> _petTypes = {};
  final Set<String> _servicePetTypes = {};
  final Set<String> _servicePetSizes = {};
  bool _puppyExp = false;
  bool _seniorDogExp = false;
  bool _emergencySupport = false;
  bool _pickupService = false;
  String _relationWithOwner = '';
  String _residenceType = '';
  String _residenceCondition = '';

  // ── Photos ────────────────────────────────────────────────────
  _Photo? _bizLicense;
  final List<_Photo> _envPhotos = [];

  static const List<String> _stepLabels = ['基本信息', '个人背景', '服务范围', '环境信息'];

  // ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _serviceNameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _wechatCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _fosterYearsCtrl = TextEditingController();
    _professionCtrl = TextEditingController();
    _capacityCtrl = TextEditingController(text: '2');
    _areaCtrl = TextEditingController();

    _isReadOnly = widget.mode == 'view';
    _applicationId = widget.id;
    if (widget.id != null) _step = 1;

    _init();
  }

  @override
  void dispose() {
    _serviceNameCtrl.dispose();
    _phoneCtrl.dispose();
    _wechatCtrl.dispose();
    _addressCtrl.dispose();
    _fosterYearsCtrl.dispose();
    _professionCtrl.dispose();
    _capacityCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  // ─── Init ─────────────────────────────────────────────────────

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      await _loadDicts();
      if (widget.id != null) await _loadDetail(widget.id!);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDicts() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        LibApi.dictBatchList,
        data: [
          'pet_species',
          'pet_weight',
          'service_type',
          'petsitter_residence_type',
          'petsitter_residence_condition',
          'relationship',
        ],
      );
      final content = res.data['content'];
      if (content is! Map) return;

      _Opt mapEntry(Map e) => _Opt(
            label: e['value']?.toString() ?? '',
            value: e['key']?.toString() ?? '',
          );

      List<_Opt> listOf(String key) =>
          ((content[key] as List?)?.map((e) => mapEntry(e as Map)).toList()) ?? [];

      final petSpecies = ((content['pet_species'] as List?) ?? [])
          .map((e) {
            final m = e as Map;
            final k = m['key']?.toString() ?? '';
            return _Opt(
              label: m['value']?.toString() ?? '',
              value: k,
              icon: k == '1' ? '🐕' : (k == '2' ? '🐱' : '🐾'),
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _serviceTypeOpts = listOf('service_type');
          _petTypeOpts = petSpecies;
          _petSizeOpts = listOf('pet_weight');
          _residenceTypeOpts = listOf('petsitter_residence_type');
          _livingConditionOpts = listOf('petsitter_residence_condition');
          _businessRelationOpts = listOf('relationship');

          if (_serviceType.isEmpty && _serviceTypeOpts.isNotEmpty) {
            _serviceType = _serviceTypeOpts.first.value;
          }
        });
      }
    } catch (_) {
      // dict loading failure is non-fatal
    }
  }

  Future<void> _loadDetail(String id) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '${PetsitterApi.queryApplicationDetail}?applicationId=$id',
      );
      final d = res.data['content'];
      if (d == null || d is! Map) return;

      _applicationId = d['id']?.toString() ?? id;
      _auditStatus = (d['auditStatus'] ?? -1) as int;

      List<String> splitStr(dynamic v) {
        if (v == null) return <String>[];
        if (v is List) return v.map((e) => e.toString()).toList();
        return v.toString().split(',').where((s) => s.isNotEmpty).toList();
      }

      final petTypesList = splitStr(d['petTypes']);
      final svcPetTypesList = splitStr(d['servicePetTypes']);
      final svcPetSizesList = splitStr(d['servicePetSizes']);
      final envPicsList = splitStr(d['environmentPics']);

      setState(() {
        _isReadOnly = _isReadOnly || _auditStatus == 1;
        _step = 1;

        _applicantType = d['applicantType']?.toString() ?? '1';
        _serviceNameCtrl.text = d['serviceName']?.toString() ?? '';
        _serviceType = d['serviceType']?.toString() ?? _serviceType;
        _phoneCtrl.text = d['phoneNumber']?.toString() ?? '';
        _wechatCtrl.text = d['wechatId']?.toString() ?? '';
        _addressCtrl.text = d['serviceAddress']?.toString() ?? '';
        _relationWithOwner = (d['relationWithOwner'] ?? d['relationship'])?.toString() ?? '';

        if (d['businessLicensePic'] != null) {
          _bizLicense = _Photo(url: d['businessLicensePic'].toString());
        }

        _fosterYearsCtrl.text = d['fosterExperienceYears']?.toString() ?? '';
        _professionCtrl.text = d['profession']?.toString() ?? '';
        _petTypes
          ..clear()
          ..addAll(petTypesList);
        _puppyExp = d['puppyExperience'] == 1 || d['puppyExperience'] == true;
        _seniorDogExp = d['seniorDogExperience'] == 1 || d['seniorDogExperience'] == true;

        _servicePetTypes
          ..clear()
          ..addAll(svcPetTypesList);
        _servicePetSizes
          ..clear()
          ..addAll(svcPetSizesList);
        _capacityCtrl.text = (d['serviceCapacity'] ?? 2).toString();
        _emergencySupport = d['emergencySupport'] == 1 || d['emergencySupport'] == true;
        _pickupService = d['pickupService'] == 1 || d['pickupService'] == true;

        _residenceArea(d);
        _residenceType = d['residenceType']?.toString() ?? '';
        _residenceCondition = (d['residenceCondition'] ?? '').toString();

        _envPhotos
          ..clear()
          ..addAll(envPicsList.map((u) => _Photo(url: u)));
      });
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _residenceArea(Map d) {
    _areaCtrl.text = d['residenceArea']?.toString() ?? '';
  }

  // ─── Upload ───────────────────────────────────────────────────

  Future<String?> _uploadImage(String filePath) async {
    final dio = ref.read(dioProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath,
          filename: filePath.split('/').last),
    });
    // Reuse identity upload endpoint; change to a general upload endpoint if available
    final res = await dio.post(IdentityApi.uploadIdCard, data: form);
    final content = res.data['content'];
    if (content is Map) {
      return content['url']?.toString() ??
          content['fileId']?.toString() ??
          content['id']?.toString();
    }
    if (content is String && content.isNotEmpty) return content;
    return null;
  }

  Future<void> _pickBizLicense() async {
    if (_isReadOnly) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await _uploadImage(picked.path);
      if (mounted) {
        setState(() {
          _bizLicense = _Photo(local: picked.path, url: url);
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('上传失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addEnvPhotos() async {
    if (_isReadOnly) return;
    final remaining = 9 - _envPhotos.length;
    if (remaining <= 0) return;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80, limit: remaining);
    if (picked.isEmpty || !mounted) return;

    setState(() => _uploading = true);
    try {
      for (final xf in picked) {
        final url = await _uploadImage(xf.path);
        if (mounted) {
          setState(() {
            _envPhotos.add(_Photo(local: xf.path, url: url));
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('部分照片上传失败')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Validation ───────────────────────────────────────────────

  String? _validateStep() {
    switch (_step) {
      case 1:
        if (_serviceNameCtrl.text.trim().isEmpty) return '请填写服务名称';
        if (_phoneCtrl.text.trim().isEmpty) return '请填写手机号';
        final phoneReg = RegExp(r'^1[3-9]\d{9}$');
        if (!phoneReg.hasMatch(_phoneCtrl.text.trim())) return '请填写正确的手机号';
        if (_addressCtrl.text.trim().isEmpty) return '请填写服务地址';
        if (_applicantType == '2') {
          if (_bizLicense?.isUploaded != true) return '请上传营业执照照片';
          if (_relationWithOwner.isEmpty) return '请选择商家与本人的关系';
        }
        return null;
      case 2:
        final years = _fosterYearsCtrl.text.trim();
        if (years.isEmpty) return '请填写养宠经验年限';
        final y = int.tryParse(years);
        if (y == null || y < 0 || y >= 100) return '养宠经验年限请填写0-99的整数';
        if (_petTypes.isEmpty) return '请选择养宠类型';
        return null;
      case 3:
        if (_servicePetTypes.isEmpty) return '请选择可接待的宠物类型';
        if (_servicePetSizes.isEmpty) return '请选择可接待的体型';
        final cap = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
        if (cap < 1 || cap > 5) return '同时接待数量请填写1-5';
        return null;
      case 4:
        if (_areaCtrl.text.trim().isEmpty) return '请填写居住面积';
        final area = double.tryParse(_areaCtrl.text.trim()) ?? 0;
        if (area <= 0 || area >= 10000) return '居住面积请填写合理数值(1~9999)';
        if (_residenceType.isEmpty) return '请选择居住环境类型';
        if (_residenceCondition.isEmpty) return '请选择居住情况';
        if (_envPhotos.length < 3) return '请至少上传3张环境照片';
        return null;
    }
    return null;
  }

  // ─── Navigation ───────────────────────────────────────────────

  void _onAgreeAndContinue() {
    setState(() => _step = 1);
  }

  Future<void> _onNext() async {
    final err = _validateStep();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_step < 4) {
      if (_canSaveDraft) await _onSaveDraft(silent: true);
      if (!mounted) return;
      setState(() => _step++);
    }
  }

  Future<void> _onSaveDraft({bool silent = true}) async {
    if (!_canSaveDraft) return;
    setState(() => _saving = true);
    try {
      final result = await _doSave();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ? '草稿已保存' : '保存失败，请重试')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _doSave() async {
    try {
      final dio = ref.read(dioProvider);
      final body = _buildRequestBody();
      final res = await dio.post(PetsitterApi.saveOrUpdateApplication, data: body);
      if (res.data['success'] == false) return false;

      final createdId = res.data['content'];
      if (_applicationId == null && createdId != null) {
        setState(() => _applicationId = createdId.toString());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSubmit() async {
    final err = _validateStep();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    setState(() => _submitting = true);
    try {
      // Step 1: save / update
      final saved = await _doSave();
      if (!saved) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
        return;
      }
      if (!mounted) return;

      // Step 2: submit
      await ref.read(dioProvider).post(
            '${PetsitterApi.submitApplication}/$_applicationId',
          );

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('提交成功'),
          content: const Text('您的申请已提交，我们将在1-2个工作日内完成审核，请耐心等待。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('提交失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _canSaveDraft => !_isReadOnly && (_auditStatus == -1 || _auditStatus == 2);

  Map<String, dynamic> _buildRequestBody() {
    final app = <String, dynamic>{
      'applicantType': _applicantType,
      'serviceName': _serviceNameCtrl.text.trim(),
      'serviceType': _serviceType,
      'phoneNumber': _phoneCtrl.text.trim(),
    };
    if (_applicationId != null) app['id'] = _applicationId;

    final info = <String, dynamic>{
      'wechatId': _wechatCtrl.text.trim(),
      'serviceAddress': _addressCtrl.text.trim(),
      'profession': _professionCtrl.text.trim(),
      'petTypes': _petTypes.toList(),
      'fosterExperienceYears': int.tryParse(_fosterYearsCtrl.text.trim()) ?? 0,
      'puppyExperience': _puppyExp ? 1 : 0,
      'seniorDogExperience': _seniorDogExp ? 1 : 0,
      if (_applicantType == '2') ...{
        'businessLicensePic': _bizLicense?.url ?? '',
        'relationWithOwner': int.tryParse(_relationWithOwner) ?? 0,
        'relationship': _relationWithOwner,
      },
    };
    if (_applicationId != null) info['applicationId'] = _applicationId;

    final env = <String, dynamic>{
      'servicePetTypes': _servicePetTypes.toList(),
      'servicePetSizes': _servicePetSizes.toList(),
      'serviceCapacity': int.tryParse(_capacityCtrl.text.trim()) ?? 2,
      'emergencySupport': _emergencySupport ? 1 : 0,
      'pickupService': _pickupService ? 1 : 0,
      'residenceType': _residenceType,
      'residenceArea': _areaCtrl.text.trim(),
      'residenceCondition': int.tryParse(_residenceCondition) ?? 0,
      'environmentPics': _envPhotos.map((p) => p.url ?? p.local ?? '').where((s) => s.isNotEmpty).toList(),
      'environmentVideo': '',
    };
    if (_applicationId != null) env['applicationId'] = _applicationId;

    return {'application': app, 'info': info, 'env': env};
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '成为陪伴师'),
          if (_step > 0) _buildProgressBar(),
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: List.generate(_stepLabels.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 1, color: const Color(0xFFEEEEEE)),
            );
          }
          final idx = i ~/ 2;
          final stepNum = idx + 1;
          return _buildProgressItem(stepNum, _stepLabels[idx]);
        }),
      ),
    );
  }

  Widget _buildProgressItem(int stepNum, String label) {
    final isCurrent = stepNum == _step;
    final isComplete = stepNum < _step;
    const orange = Color(0xFFFF9E4A);
    const grey = Color(0xFFCCCCCC);
    final color = (isCurrent || isComplete) ? orange : grey;

    return GestureDetector(
      onTap: () {
        if (_step > 0 && stepNum < _step) setState(() => _step = stepNum);
      },
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isComplete ? orange : Colors.transparent,
              border: Border.all(color: color, width: 2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isComplete
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : Text(
                      '$stepNum',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  // ── Step content ──────────────────────────────────────────────

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  // Step 0 – Agreement
  Widget _buildStep0() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('您了解', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ],
          ),
          SizedBox(height: 8),
          Text('您必须年满18岁，且曾经或正拥有宠物。', style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6)),
          SizedBox(height: 12),
          Text(
            '1、所提供的信息都必须属实，上传的照片不附版权以便我们推广广告。您需要提供您的电话号码、身份证以进行验证。我们也会进行背景调查，并可能会删除可疑帐户；',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            '2、宠信的存在是为了让宠物的生活变得更安全。平台的费用可帮助宠信的成长，达到社区的需求。当宠物父母雇用您时，您将带走至少86%的费用。如果提前交换了联系信息，且未通过平台预定付款，您将被罚款40%或被暂时停权。',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            '3、同意退还所有的费用，若您未能提供令客人满意的服务。',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            '4、您并非平台的员工，您是提供宠物服务的社区用户。如果发生任何紧急情况或违反地方相关规定，您同意承担全部责任。平台将提供宠物保险服务帮助减少兽医费用或赔偿。',
            style: TextStyle(fontSize: 14, color: Color(0xFF555555), height: 1.6),
          ),
          SizedBox(height: 16),
          Text('仅适用于通过平台交易的工作', style: TextStyle(fontSize: 13, color: Color(0xFF999999))),
        ],
      ),
    );
  }

  // Step 1 – Basic info
  Widget _buildStep1() {
    return Column(
      children: [
        // Service type + name
        _card(children: [
          _fieldLabel('服务类型', required: true),
          _serviceTypePicker(),
          _divider(),
          _fieldLabel('服务名称', required: true, sub: '结合宠物、服务和宠物类型，让您的服务更突出'),
          _textInput(_serviceNameCtrl, '如：北京朝阳宠物之家', maxLength: 30),
        ]),
        // Role + phone + wechat + address
        _card(children: [
          _fieldLabel('角色', required: true),
          _roleToggle(),
          _divider(),
          _fieldLabel('手机号', required: true),
          _textInput(_phoneCtrl, '请输入手机号', keyboardType: TextInputType.phone, maxLength: 11),
          _divider(),
          _fieldLabel('微信号', sub: '选填'),
          _textInput(_wechatCtrl, '请输入微信号（选填）', maxLength: 30),
          _divider(),
          _fieldLabel('服务地址', required: true, sub: '请填写您提供服务的地址'),
          _textInput(_addressCtrl, '如：北京市朝阳区xxx路xx号'),
        ]),
        // Business info (if 商家)
        if (_applicantType == '2')
          _card(children: [
            _fieldLabel('营业执照照片', required: true, sub: '需上传清晰的营业执照照片或扫描件'),
            _bizLicenseUploader(),
            _divider(),
            _fieldLabel('商家与本人的关系', required: true),
            _dropdownPicker(
              options: _businessRelationOpts,
              value: _relationWithOwner,
              hint: '请选择',
              onChanged: _isReadOnly ? null : (v) => setState(() => _relationWithOwner = v),
            ),
          ]),
      ],
    );
  }

  // Step 2 – Background
  Widget _buildStep2() {
    return Column(
      children: [
        _card(children: [
          _fieldLabel('养宠经验年限', required: true, sub: '如：2'),
          _textInput(_fosterYearsCtrl, '请输入养宠经验年限（年）', keyboardType: TextInputType.number),
          _divider(),
          _fieldLabel('职业/工作背景', sub: '选填，如：宠物医生'),
          _textInput(_professionCtrl, '如：宠物医生', maxLength: 50),
        ]),
        _card(children: [
          _fieldLabel('养宠类型', required: true, sub: '多选'),
          const SizedBox(height: 8),
          _multiChips(
            opts: _petTypeOpts,
            selected: _petTypes,
            onToggle: (v) => setState(() {
              if (_petTypes.contains(v)) {
                _petTypes.remove(v);
              } else {
                _petTypes.add(v);
              }
            }),
          ),
        ]),
        _card(children: [
          _switchRow('是否具备幼犬服务经验', _puppyExp, (v) => setState(() => _puppyExp = v)),
          _divider(),
          _switchRow('是否具备老年犬服务经验', _seniorDogExp, (v) => setState(() => _seniorDogExp = v)),
        ]),
      ],
    );
  }

  // Step 3 – Service scope
  Widget _buildStep3() {
    return Column(
      children: [
        _card(children: [
          _fieldLabel('可接待的宠物类型', required: true, sub: '多选'),
          const SizedBox(height: 8),
          _multiChips(
            opts: _petTypeOpts,
            selected: _servicePetTypes,
            onToggle: (v) => setState(() {
              if (_servicePetTypes.contains(v)) {
                _servicePetTypes.remove(v);
              } else {
                _servicePetTypes.add(v);
              }
            }),
          ),
        ]),
        _card(children: [
          _fieldLabel('可接待的体型', required: true),
          const SizedBox(height: 8),
          _multiChips(
            opts: _petSizeOpts,
            selected: _servicePetSizes,
            onToggle: (v) => setState(() {
              if (_servicePetSizes.contains(v)) {
                _servicePetSizes.remove(v);
              } else {
                _servicePetSizes.add(v);
              }
            }),
          ),
          _divider(),
          _fieldLabel('可同时接待数量'),
          _textInput(_capacityCtrl, '请输入同时接待数量（1-5）', keyboardType: TextInputType.number),
        ]),
        _card(children: [
          _switchRow('是否支持紧急单', _emergencySupport, (v) => setState(() => _emergencySupport = v)),
          _divider(),
          _switchRow('是否提供接送服务', _pickupService, (v) => setState(() => _pickupService = v)),
        ]),
      ],
    );
  }

  // Step 4 – Environment
  Widget _buildStep4() {
    return Column(
      children: [
        _card(children: [
          _fieldLabel('居住面积', required: true, sub: '平方米'),
          _textInput(_areaCtrl, '请输入居住面积', keyboardType: TextInputType.number),
          _divider(),
          _fieldLabel('居住环境类型', required: true),
          const SizedBox(height: 8),
          _singleSelectChips(
            opts: _residenceTypeOpts,
            selected: _residenceType,
            onSelect: (v) => setState(() => _residenceType = v),
          ),
          _divider(),
          _fieldLabel('居住情况', required: true),
          const SizedBox(height: 8),
          _singleSelectChips(
            opts: _livingConditionOpts,
            selected: _residenceCondition,
            onSelect: (v) => setState(() => _residenceCondition = v),
          ),
        ]),
        _card(children: [
          _fieldLabel('居住环境照片', required: true, sub: '至少3张，最多9张'),
          const SizedBox(height: 4),
          const Text('请上传客厅、卧室、宠物活动区等照片', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
          const SizedBox(height: 12),
          _envPhotoGrid(),
        ]),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────

  Widget _buildFooter() {
    if (_step == 0) {
      if (_isReadOnly) return const SizedBox();
      return FooterBar(
        buttonText: '同意协议并开通',
        onButtonTap: _onAgreeAndContinue,
      );
    }
    if (_isReadOnly) return const SizedBox();

    final canDraft = _canSaveDraft;
    if (_step == 4) {
      return FooterBar(
        outlineText: canDraft ? '保存草稿' : null,
        buttonText: '提交申请',
        buttonDisabled: _submitting,
        onOutlineTap: canDraft ? () => _onSaveDraft(silent: false) : null,
        onButtonTap: _submitting ? null : _onSubmit,
      );
    }
    return FooterBar(
      outlineText: canDraft ? '保存草稿' : null,
      buttonText: '下一步',
      buttonDisabled: _saving,
      onOutlineTap: canDraft ? () => _onSaveDraft(silent: false) : null,
      onButtonTap: _saving ? null : _onNext,
    );
  }

  // ─── Shared UI helpers ────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Color(0xFFF0F0F0)),
      );

  Widget _fieldLabel(String title, {bool required = false, String? sub}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (required)
            const Text('* ', style: TextStyle(color: Color(0xFFFF4D4F), fontSize: 14, fontWeight: FontWeight.w600)),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          if (sub != null) ...[
            const SizedBox(width: 4),
            Flexible(child: Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF999999)))),
          ],
        ],
      ),
    );
  }

  Widget _textInput(
    TextEditingController ctrl,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return TextField(
      controller: ctrl,
      readOnly: _isReadOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
        counterText: '',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _serviceTypePicker() {
    if (_serviceTypeOpts.isEmpty) return const SizedBox(height: 8);
    final selected = _serviceTypeOpts.firstWhere(
      (o) => o.value == _serviceType,
      orElse: () => _serviceTypeOpts.first,
    );
    return _isReadOnly
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(selected.label, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
          )
        : DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _serviceType.isEmpty ? null : _serviceType,
              hint: const Text('请选择服务类型'),
              isExpanded: true,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              items: _serviceTypeOpts
                  .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _serviceType = v);
              },
            ),
          );
  }

  Widget _roleToggle() {
    return Row(
      children: ['1', '2'].map((v) {
        final label = v == '1' ? '个人' : '商家';
        final active = _applicantType == v;
        return GestureDetector(
          onTap: _isReadOnly ? null : () => setState(() {
            _applicantType = v;
            if (v == '1') {
              _bizLicense = null;
              _relationWithOwner = '';
            }
          }),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF9E4A) : Colors.white,
              border: Border.all(color: active ? const Color(0xFFFF9E4A) : const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: active ? Colors.white : const Color(0xFF666666),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bizLicenseUploader() {
    if (_bizLicense != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 120,
              height: 80,
              child: _bizLicense!.url != null && _bizLicense!.url!.startsWith('http')
                  ? Image.network(_bizLicense!.url!, fit: BoxFit.cover)
                  : _bizLicense!.local != null
                      ? Image.file(File(_bizLicense!.local!), fit: BoxFit.cover)
                      : const ColoredBox(color: Color(0xFFF0F0F0)),
            ),
          ),
          if (!_isReadOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _bizLicense = null),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      );
    }
    return GestureDetector(
      onTap: _uploading ? null : _pickBizLicense,
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: _uploading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFFCCCCCC), size: 28),
                  SizedBox(height: 4),
                  Text('点击上传', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
                ],
              ),
      ),
    );
  }

  Widget _dropdownPicker({
    required List<_Opt> options,
    required String value,
    required String hint,
    required ValueChanged<String>? onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        hint: Text(hint, style: const TextStyle(fontSize: 14, color: Color(0xFFCCCCCC))),
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
        items: options.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label))).toList(),
        onChanged: onChanged == null ? null : (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  Widget _multiChips({
    required List<_Opt> opts,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((o) {
        final active = selected.contains(o.value);
        return GestureDetector(
          onTap: _isReadOnly ? null : () => onToggle(o.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF9E4A) : Colors.white,
              border: Border.all(color: active ? const Color(0xFFFF9E4A) : const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (o.icon.isNotEmpty) ...[
                  Text(o.icon, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                ],
                Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 14,
                    color: active ? Colors.white : const Color(0xFF666666),
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _singleSelectChips({
    required List<_Opt> opts,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: opts.map((o) {
        final active = selected == o.value;
        return GestureDetector(
          onTap: _isReadOnly ? null : () => onSelect(o.value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFF9E4A) : Colors.white,
              border: Border.all(color: active ? const Color(0xFFFF9E4A) : const Color(0xFFDDDDDD)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.label,
              style: TextStyle(
                fontSize: 14,
                color: active ? Colors.white : const Color(0xFF666666),
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _switchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
        Switch(
          value: value,
          onChanged: _isReadOnly ? null : onChanged,
          activeThumbColor: const Color(0xFFFF9E4A),
        ),
      ],
    );
  }

  Widget _envPhotoGrid() {
    final items = <Widget>[];
    for (int i = 0; i < _envPhotos.length; i++) {
      final p = _envPhotos[i];
      items.add(Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: p.isUploaded && p.url!.startsWith('http')
                  ? Image.network(p.url!, fit: BoxFit.cover)
                  : p.local != null
                      ? Image.file(File(p.local!), fit: BoxFit.cover)
                      : const ColoredBox(color: Color(0xFFF0F0F0)),
            ),
          ),
          if (!_isReadOnly)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _envPhotos.removeAt(i)),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ));
    }
    if (_envPhotos.length < 9 && !_isReadOnly) {
      items.add(GestureDetector(
        onTap: _uploading ? null : _addEnvPhotos,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
          ),
          child: _uploading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Color(0xFFCCCCCC), size: 28),
                    SizedBox(height: 4),
                    Text('点击上传', style: TextStyle(fontSize: 11, color: Color(0xFFCCCCCC))),
                  ],
                ),
        ),
      ));
    }
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items,
    );
  }
}
