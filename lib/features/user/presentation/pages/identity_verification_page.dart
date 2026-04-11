import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/providers/user_provider.dart';

class IdentityVerificationPage extends ConsumerStatefulWidget {
  const IdentityVerificationPage({super.key});

  @override
  ConsumerState<IdentityVerificationPage> createState() =>
      _IdentityVerificationPageState();
}

class _IdentityVerificationPageState
    extends ConsumerState<IdentityVerificationPage> {
  // 本地已选的图片路径（选后即上传，所以展示用 _frontPreview/_backPreview）
  String? _frontPreview; // 本地预览路径
  String? _backPreview;

  // 上传成功后的 fileId（提交认证时使用）
  String? _frontFileId;
  String? _backFileId;

  bool _uploadingFront = false;
  bool _uploadingBack = false;
  bool _submitting = false;

  bool get _canSubmit =>
      _frontFileId != null &&
      _backFileId != null &&
      !_uploadingFront &&
      !_uploadingBack &&
      !_submitting;

  // ── 选图 ──────────────────────────────────────────────────────

  Future<void> _pickFront() async {
    final user = ref.read(userNotifierProvider);
    if (user?.isIdCertified == true) {
      final ok = await _confirmReplace('人像面');
      if (!ok) return;
    }
    _doPickAndUpload(isFront: true);
  }

  Future<void> _pickBack() async {
    final user = ref.read(userNotifierProvider);
    if (user?.isIdCertified == true) {
      final ok = await _confirmReplace('国徽面');
      if (!ok) return;
    }
    _doPickAndUpload(isFront: false);
  }

  Future<bool> _confirmReplace(String side) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('替换身份证照片'),
        content: Text('您已完成实名认证，确定要替换身份证$side照片吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确定替换',
                  style: TextStyle(color: Color(0xFFFF9E4A)))),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _doPickAndUpload({required bool isFront}) async {
    // 选择来源
    final source = await _showSourceSheet();
    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (file == null) return;

    final path = file.path;
    setState(() {
      if (isFront) {
        _frontPreview = path;
        _uploadingFront = true;
      } else {
        _backPreview = path;
        _uploadingBack = true;
      }
    });

    try {
      final fileId = await _uploadImage(path);
      if (mounted) {
        setState(() {
          if (isFront) {
            _frontFileId = fileId;
          } else {
            _backFileId = fileId;
          }
        });
        _showSnack(isFront ? '正面上传成功' : '反面上传成功');
      }
    } catch (e) {
      if (mounted) _showSnack('上传失败，请重试');
    } finally {
      if (mounted) {
        setState(() {
          if (isFront) {
            _uploadingFront = false;
          } else {
            _uploadingBack = false;
          }
        });
      }
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('选择图片来源',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333))),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFFFF7E51)),
                title: const Text('拍摄照片'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFFFF7E51)),
                title: const Text('从相册选择'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── 上传 ──────────────────────────────────────────────────────

  Future<String> _uploadImage(String filePath) async {
    final dio = ref.read(dioProvider);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'id_card_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    final res = await dio.post(
      IdentityApi.uploadIdCard,
      data: formData,
    );
    final data = res.data as Map<String, dynamic>?;
    final content = data?['content'];
    // 兼容多种响应格式
    if (content is Map) {
      return content['fileId']?.toString() ??
          content['id']?.toString() ??
          content['url']?.toString() ??
          '';
    }
    return content?.toString() ?? '';
  }

  // ── 提交认证 ──────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final res = await ref.read(dioProvider).post(
        CustomerApi.certified,
        data: {
          'idPicFrontInfo': _frontFileId,
          'idPicBackInfo': _backFileId,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      final success =
          data?['success'] == true || data?['code'] == 200;
      if (success && mounted) {
        // 更新本地用户状态
        final current = ref.read(userNotifierProvider);
        if (current != null) {
          ref.read(userNotifierProvider.notifier).login(
                current.copyWith(isIdCertified: true),
              );
        }
        _showSnack('认证成功');
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) context.pop();
      } else {
        _showSnack('提交失败，请稍后重试');
      }
    } catch (_) {
      if (mounted) _showSnack('提交失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2)),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider);
    final isVerified = user?.isIdCertified == true;

    return Scaffold(
      body: Stack(
        children: [
          // 橙色渐变背景
          _buildHero(),
          // 内容区域（含安全区 + 返回按钮）
          SafeArea(
            child: Column(
              children: [
                // 自定义顶部栏
                _buildTopBar(),
                // 主卡片
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildCard(isVerified),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 橙色渐变背景 ─────────────────────────────────────────────

  Widget _buildHero() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 300,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7E51), Color(0xFFFFB347)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // 装饰圆形
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 顶部导航 ─────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const Text(
            '实名认证',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── 主内容卡片 ────────────────────────────────────────────────

  Widget _buildCard(bool isVerified) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x18000000),
              blurRadius: 20,
              offset: Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text('一次认证  全程安心',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222))),
            const SizedBox(height: 6),
            const Text('为您的账户安全保驾护航',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF888888))),
            const SizedBox(height: 24),

            // 说明
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFE0C0), width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('请上传您本人的真实证件照片',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFAA5100))),
                  SizedBox(height: 4),
                  Text(
                    '请确保二代身份证有效，头像文字清晰，四角对齐，无反光，无遮挡',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF888888)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 人像面
            _buildUploadSection(
              label: isVerified ? '点击替换身份证人像面' : '点击上传身份证原件人像面',
              side: '人像面',
              isFront: true,
              isVerified: isVerified,
              previewPath: _frontPreview,
              uploading: _uploadingFront,
              uploaded: _frontFileId != null,
              onTap: _pickFront,
            ),
            const SizedBox(height: 20),

            // 国徽面
            _buildUploadSection(
              label: isVerified ? '点击替换身份证国徽面' : '点击上传身份证原件国徽面',
              side: '国徽面',
              isFront: false,
              isVerified: isVerified,
              previewPath: _backPreview,
              uploading: _uploadingBack,
              uploaded: _backFileId != null,
              onTap: _pickBack,
            ),
            const SizedBox(height: 32),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7E51),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFFF7E51).withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white),
                      )
                    : const Text('立即认证',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                '您的身份信息将被严格加密保护，仅用于实名认证',
                style: TextStyle(
                    fontSize: 11, color: Color(0xFFAAAAAA)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 上传区域 ──────────────────────────────────────────────────

  Widget _buildUploadSection({
    required String label,
    required String side,
    required bool isFront,
    required bool isVerified,
    required String? previewPath,
    required bool uploading,
    required bool uploaded,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: uploading ? null : onTap,
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: uploaded
                      ? const Color(0xFFFF7E51)
                      : const Color(0xFFEEEEEE),
                  width: uploaded ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _buildUploadContent(
                  isFront: isFront,
                  isVerified: isVerified,
                  previewPath: previewPath,
                  uploading: uploading,
                  uploaded: uploaded,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              uploaded
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              size: 13,
              color: uploaded
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFAAAAAA),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: uploaded
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadContent({
    required bool isFront,
    required bool isVerified,
    required String? previewPath,
    required bool uploading,
    required bool uploaded,
  }) {
    // 上传中
    if (uploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                strokeWidth: 2.5, color: Color(0xFFFF7E51)),
            SizedBox(height: 10),
            Text('上传中...',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
      );
    }

    // 已选图片 → 预览
    if (previewPath != null) {
      return Image.file(
        File(previewPath),
        fit: BoxFit.cover,
      );
    }

    // 已认证但本次未替换 → 马赛克锁定状态
    if (isVerified) {
      return Stack(
        fit: StackFit.expand,
        children: [
          // 蒙层
          Container(color: const Color(0xFFF0EDE8)),
          // 横条纹模拟马赛克
          CustomPaint(painter: _MosaicPainter()),
          // 中央文字
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 28, color: Color(0xFFFF7E51)),
                const SizedBox(height: 6),
                const Text('已保密',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666))),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF7E51).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('点击替换',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF7E51))),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 默认占位 → 身份证卡片插图
    return _buildPlaceholder(isFront);
  }

  Widget _buildPlaceholder(bool isFront) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 身份证示意图
        Container(
          width: 120,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2))
            ],
          ),
          child: Stack(
            children: [
              // 顶部色条
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 22,
                child: Container(
                  decoration: BoxDecoration(
                    color: isFront
                        ? const Color(0xFFFF7E51)
                        : const Color(0xFF8B4513),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(7)),
                  ),
                ),
              ),
              if (isFront) ...[
                // 人像圆形占位
                Positioned(
                  top: 28,
                  left: 10,
                  child: Container(
                    width: 24,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 16, color: Color(0xFFBBBBBB)),
                  ),
                ),
                // 线条
                Positioned(
                  top: 30,
                  left: 42,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      4,
                      (i) => Container(
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // 国徽位置（中央）
                const Center(
                  child: Icon(Icons.shield_outlined,
                      size: 28, color: Color(0xFFCCCCCC)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7E51).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt_outlined,
                  size: 14, color: Color(0xFFFF7E51)),
              const SizedBox(width: 4),
              Text(
                isFront ? '上传人像面' : '上传国徽面',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFFFF7E51)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 马赛克画笔 ─────────────────────────────────────────────────

class _MosaicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x18000000)
      ..style = PaintingStyle.fill;
    const blockSize = 12.0;
    for (double y = 0; y < size.height; y += blockSize * 2) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, blockSize), paint);
    }
  }

  @override
  bool shouldRepaint(_MosaicPainter old) => false;
}
