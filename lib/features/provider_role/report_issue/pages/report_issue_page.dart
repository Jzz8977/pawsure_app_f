import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:pawsure_app/core/constants/api_constants.dart';
import 'package:pawsure_app/core/network/dio_client.dart';
import 'package:pawsure_app/shared/widgets/app_nav_bar.dart';
import 'package:pawsure_app/shared/widgets/footer_bar.dart';

// exceptionType: 身体异常=1 情绪异常=2 行为异常=3 意外事件=4
const _exceptionTypeMap = {
  'body':     {'label': '身体异常', 'code': 1},
  'emotion':  {'label': '情绪异常', 'code': 2},
  'behavior': {'label': '行为异常', 'code': 3},
  'accident': {'label': '意外事件', 'code': 4},
};

const _measureOptions = [
  {'id': 'comfort',  'label': '已安抚'},
  {'id': 'isolate',  'label': '已隔离'},
  {'id': 'contact',  'label': '已联系客户'},
  {'id': 'prepare',  'label': '准备送医'},
  {'id': 'hospital', 'label': '已送医'},
];

class ReportIssuePage extends ConsumerStatefulWidget {
  final String? orderNo;
  final String? providerId;
  final String? customerId;
  final String? serviceType;

  const ReportIssuePage({
    super.key,
    this.orderNo,
    this.providerId,
    this.customerId,
    this.serviceType,
  });

  @override
  ConsumerState<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends ConsumerState<ReportIssuePage> {
  TimeOfDay _issueTime = TimeOfDay.now();
  String _selectedIssueType = '';
  final Set<String> _selectedMeasures = {};
  final TextEditingController _descCtrl = TextEditingController();
  final List<Map<String, dynamic>> _photos = [];
  bool _submitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = 9 - _photos.length;
    if (remaining <= 0) return;
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: remaining);
    if (picked.isEmpty || !mounted) return;

    final dio = ref.read(dioProvider);
    for (final xfile in picked) {
      try {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(xfile.path, filename: xfile.name),
        });
        final res = await dio.post(IdentityApi.uploadIdCard, data: formData);
        final url = res.data['content']?.toString() ?? '';
        if (url.isNotEmpty && mounted) {
          setState(() => _photos.add({'local': xfile.path, 'url': url}));
        }
      } catch (_) {}
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _issueTime);
    if (picked != null && mounted) setState(() => _issueTime = picked);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (widget.orderNo == null || widget.orderNo!.isEmpty) { _showError('缺少订单信息'); return; }
    if (_selectedIssueType.isEmpty) { _showError('请选择异常类型'); return; }
    if (_selectedMeasures.isEmpty) { _showError('请选择已采取的措施'); return; }
    if (_descCtrl.text.trim().length < 5) { _showError('请输入至少5个字的描述'); return; }

    setState(() => _submitting = true);
    try {
      final now = DateTime.now();
      final exceptionTime = DateTime(now.year, now.month, now.day, _issueTime.hour, _issueTime.minute).toIso8601String();
      final measuresStr = _selectedMeasures.map((id) => _measureOptions.firstWhere((m) => m['id'] == id)['label']!).join(',');
      final exCode = _exceptionTypeMap[_selectedIssueType]!['code'] as int;

      final payload = <String, dynamic>{
        'orderNo': widget.orderNo,
        'checkinType': 2,
        'recordKind': 2,
        'exceptionType': exCode,
        'exceptionTime': exceptionTime,
        'exceptionDesc': _descCtrl.text.trim(),
        'measures': measuresStr,
        'mediaMode': 1,
        'mediaList': _photos.map((p) => {'type': 'image', 'key': p['url'], 'size': 0, 'w': 0, 'h': 0, 'durationMs': 0}).toList(),
        'clientTime': DateTime.now().toIso8601String(),
      };
      if (widget.serviceType?.isNotEmpty == true) payload['serviceType'] = int.tryParse(widget.serviceType!) ?? 0;
      if (widget.providerId?.isNotEmpty == true) payload['providerId'] = int.tryParse(widget.providerId!) ?? 0;
      if (widget.customerId?.isNotEmpty == true) payload['customerId'] = int.tryParse(widget.customerId!) ?? 0;

      await ref.read(dioProvider).post(CheckinApi.submit, data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('上报成功')));
      context.pop();
    } catch (_) {
      if (mounted) _showError('上报失败，请重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const AppNavBar(title: '异常上报', showDivider: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time picker
                    _sectionTitle('异常发生时间'),
                    GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_issueTime.hour.toString().padLeft(2, '0')}:${_issueTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF999999)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Issue type
                    _sectionTitle('异常类型'),
                    _buildOptionGrid(
                      _exceptionTypeMap.entries.map((e) => {'id': e.key, 'label': e.value['label'] as String}).toList(),
                      {_selectedIssueType},
                      (id) => setState(() => _selectedIssueType = _selectedIssueType == id ? '' : id),
                      cols: 2,
                      single: true,
                    ),
                    const SizedBox(height: 20),

                    // Measures
                    _sectionTitle('已采取措施'),
                    _buildOptionGrid(
                      _measureOptions.cast<Map<String, dynamic>>(),
                      _selectedMeasures,
                      (id) => setState(() {
                        if (_selectedMeasures.contains(id)) {
                          _selectedMeasures.remove(id);
                        } else {
                          _selectedMeasures.add(id);
                        }
                      }),
                      cols: 3,
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _sectionTitle('信息描述'),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            controller: _descCtrl,
                            maxLines: 4,
                            maxLength: 200,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: '请描述您遇到的问题（5-200字）',
                              hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(12),
                              counterText: '',
                            ),
                          ),
                          Positioned(
                            right: 8, bottom: 8,
                            child: Text(
                              '${_descCtrl.text.length}/200',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Photos
                    _sectionTitle('上传图片（可选，最多9张）'),
                    _buildPhotoGrid(),
                  ],
                ),
              ),
            ),
          ),
          FooterBar(
            buttonText: '确认异常上报',
            onButtonTap: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
    );
  }

  Widget _buildOptionGrid(
    List<Map<String, dynamic>> options,
    Set<String> selected,
    ValueChanged<String> onTap, {
    int cols = 4,
    bool single = false,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.4,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final opt = options[i];
        final isActive = selected.contains(opt['id'] as String);
        return GestureDetector(
          onTap: () => onTap(opt['id'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF9E4A).withValues(alpha: 0.1) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isActive ? const Color(0xFFFF9E4A) : Colors.transparent),
            ),
            child: Center(
              child: Text(
                opt['label'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: isActive ? const Color(0xFFFF9E4A) : const Color(0xFF666666),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._photos.asMap().entries.map((e) => _photoThumb(e.value, e.key)),
        if (_photos.length < 9) _addPhotoBtn(),
      ],
    );
  }

  Widget _photoThumb(Map<String, dynamic> photo, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(photo['local'] as String), width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addPhotoBtn() {
    return GestureDetector(
      onTap: _addPhotos,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Color(0xFFCCCCCC), size: 24),
            Text('图片', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ],
        ),
      ),
    );
  }
}
