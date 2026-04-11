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

// activityType: 喂食=1 休息=2 洗澡=3 美容=4 如厕=5 训练=6 互动=7 独处=8
// mood: 活泼=1 正常=2 疲惫=3 萎靡=4

class ClockinPage extends ConsumerStatefulWidget {
  final String? orderNo;
  final String? orderId;
  final String? taskId;
  final String? providerId;
  final String? customerId;
  final String? serviceType;
  final String? petId;

  const ClockinPage({
    super.key,
    this.orderNo,
    this.orderId,
    this.taskId,
    this.providerId,
    this.customerId,
    this.serviceType,
    this.petId,
  });

  @override
  ConsumerState<ClockinPage> createState() => _ClockinPageState();
}

class _ClockinPageState extends ConsumerState<ClockinPage> {
  static const _activityTypes = [
    {'id': 'feed',     'label': '喂食',  'code': 1},
    {'id': 'rest',     'label': '休息',  'code': 2},
    {'id': 'bath',     'label': '洗澡',  'code': 3},
    {'id': 'beauty',   'label': '美容',  'code': 4},
    {'id': 'toilet',   'label': '如厕',  'code': 5},
    {'id': 'train',    'label': '训练',  'code': 6},
    {'id': 'play',     'label': '互动',  'code': 7},
    {'id': 'alone',    'label': '独处',  'code': 8},
  ];

  static const _mentalStates = [
    {'id': 'active', 'label': '活泼', 'code': 1},
    {'id': 'normal', 'label': '正常', 'code': 2},
    {'id': 'tired',  'label': '疲惫', 'code': 3},
    {'id': 'weak',   'label': '萎靡', 'code': 4},
  ];

  String _selectedActivity = '';
  String _selectedMentalState = '';
  final List<Map<String, dynamic>> _photos = [];
  bool _submitting = false;

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

  Future<void> _submit() async {
    if (_submitting) return;
    if (widget.orderNo == null || widget.orderNo!.isEmpty) {
      _showError('缺少订单信息');
      return;
    }
    if (_selectedActivity.isEmpty) { _showError('请选择活动类型'); return; }
    if (_selectedMentalState.isEmpty) { _showError('请选择精神状态'); return; }
    if (_photos.isEmpty) { _showError('请上传至少一张照片'); return; }

    setState(() => _submitting = true);
    try {
      final actCode = _activityTypes.firstWhere((e) => e['id'] == _selectedActivity)['code'] as int;
      final moodCode = _mentalStates.firstWhere((e) => e['id'] == _selectedMentalState)['code'] as int;

      final payload = <String, dynamic>{
        'orderNo': widget.orderNo,
        'checkinType': (widget.taskId != null && widget.taskId!.isNotEmpty) ? 1 : 2,
        'recordKind': 1,
        'activityType': actCode,
        'mood': moodCode,
        'mediaMode': 1,
        'mediaList': _photos.map((p) => {'type': 'image', 'key': p['url'], 'size': 0, 'w': 0, 'h': 0, 'durationMs': 0}).toList(),
        'clientTime': DateTime.now().toIso8601String(),
      };
      if (widget.taskId?.isNotEmpty == true) payload['taskId'] = widget.taskId;
      if (widget.serviceType?.isNotEmpty == true) payload['serviceType'] = widget.serviceType;
      if (widget.providerId?.isNotEmpty == true) payload['providerId'] = widget.providerId;
      if (widget.customerId?.isNotEmpty == true) payload['customerId'] = widget.customerId;
      if (widget.petId?.isNotEmpty == true) payload['petId'] = widget.petId;

      await ref.read(dioProvider).post(CheckinApi.submit, data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('打卡成功')));
      context.pop();
    } catch (_) {
      if (mounted) _showError('打卡失败，请重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.taskId?.isNotEmpty == true) ? '固定打卡' : '正常打卡';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          AppNavBar(title: title, showDivider: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: '活动类型',
                    child: _buildOptionGrid(_activityTypes, _selectedActivity, (id) => setState(() => _selectedActivity = id), cols: 4),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    title: '精神状态',
                    child: _buildOptionGrid(_mentalStates, _selectedMentalState, (id) => setState(() => _selectedMentalState = id), cols: 4),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    title: '拍摄上传',
                    subtitle: '请上传宠物活动照片',
                    child: _buildPhotoGrid(),
                  ),
                ],
              ),
            ),
          ),
          FooterBar(
            buttonText: '确认打卡',
            onButtonTap: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, String? subtitle, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildOptionGrid(List<Map<String, dynamic>> options, String selected, ValueChanged<String> onTap, {int cols = 4}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: options.length,
      itemBuilder: (_, i) {
        final opt = options[i];
        final isActive = selected == opt['id'];
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
            Text('点击上传', style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
          ],
        ),
      ),
    );
  }
}
