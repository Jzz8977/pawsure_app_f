import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/app_nav_bar.dart';

// ── 宠物详情模型 ─────────────────────────────────────────────────

class _PetDetail {
  final String id;
  final String name;
  final int species;
  final int gender;
  final String? birthDate;
  final double? weight;
  final String avatarUrl;
  final String? breedName;
  final int? sterilized;
  final int? toiletFreq;
  final int? activityLevel;
  final int? careInterval;
  final int? medicationNeeds;
  final String? healthDesc;
  final int? friendlyKids;
  final int? friendlyDogs;
  final int? friendlyCats;
  final int? pottyTime;
  final String? otherDesc;
  final List<String> livePhotoUrls;

  const _PetDetail({
    required this.id,
    required this.name,
    required this.species,
    required this.gender,
    this.birthDate,
    this.weight,
    required this.avatarUrl,
    this.breedName,
    this.sterilized,
    this.toiletFreq,
    this.activityLevel,
    this.careInterval,
    this.medicationNeeds,
    this.healthDesc,
    this.friendlyKids,
    this.friendlyDogs,
    this.friendlyCats,
    this.pottyTime,
    this.otherDesc,
    this.livePhotoUrls = const [],
  });

  factory _PetDetail.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['livePhotoList'] as List<dynamic>?;
    return _PetDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      species: (json['species'] as num?)?.toInt() ?? 1,
      gender: (json['gender'] as num?)?.toInt() ?? 0,
      birthDate:
          json['birthDate'] as String? ?? json['birthday'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      breedName: json['breedName'] as String?,
      sterilized: (json['sterilized'] as num?)?.toInt(),
      toiletFreq: (json['toiletFreq'] as num?)?.toInt(),
      activityLevel: (json['activityLevel'] as num?)?.toInt(),
      careInterval: (json['careInterval'] as num?)?.toInt(),
      medicationNeeds: (json['medicationNeeds'] as num?)?.toInt(),
      healthDesc: json['healthDesc'] as String?,
      friendlyKids: (json['friendlyKids'] as num?)?.toInt(),
      friendlyDogs: (json['friendlyDogs'] as num?)?.toInt(),
      friendlyCats: (json['friendlyCats'] as num?)?.toInt(),
      pottyTime: (json['pottyTime'] as num?)?.toInt(),
      otherDesc: json['otherDesc'] as String?,
      livePhotoUrls: rawPhotos
              ?.whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [],
    );
  }
}

// ── 辅助函数 ─────────────────────────────────────────────────────

String _ageText(String? bd) {
  if (bd == null || bd.isEmpty) return '未知年龄';
  final d = DateTime.tryParse(
      bd.replaceAll('.', '-').replaceAll('/', '-'));
  if (d == null) return '未知年龄';
  final now = DateTime.now();
  if (d.isAfter(now)) return '未满1个月';
  int y = now.year - d.year;
  int m = now.month - d.month;
  if (now.day < d.day) m--;
  if (m < 0) {
    y--;
    m += 12;
  }
  if (y > 0) return '$y岁';
  if (m > 0) return '$m个月';
  return '未满1个月';
}

String _genderText(int? g) {
  if (g == 1) return '公';
  if (g == 2) return '母';
  return '未知';
}

String _weightText(double? w) {
  if (w == null || w == 0) return '-';
  return '${w % 1 == 0 ? w.toInt() : w}kg';
}

List<String> _buildChips(_PetDetail p) {
  final chips = <String>[];
  if (p.breedName?.isNotEmpty == true) chips.add(p.breedName!);
  if (p.sterilized == 1) {
    chips.add('已绝育');
  } else if (p.sterilized == 0) {
    chips.add('未绝育');
  }
  const tMap = {1: '每1h/厕所', 2: '每2h/厕所', 3: '每4h/厕所', 4: '每8h/厕所'};
  if (p.toiletFreq != null) chips.add(tMap[p.toiletFreq] ?? '');
  const aMap = {1: '高活动量', 2: '中活动量', 3: '低活动量'};
  if (p.activityLevel != null) chips.add(aMap[p.activityLevel] ?? '');
  const cMap = {1: '<1h看护/次', 2: '1-4h看护/次', 3: '4-8h看护/次', 4: '不可离开'};
  if (p.careInterval != null) chips.add(cMap[p.careInterval] ?? '');
  if (p.friendlyKids == 1) chips.add('对人友好');
  if (p.friendlyDogs == 1) chips.add('对狗友好');
  if (p.friendlyCats == 1) chips.add('对猫友好');
  if (p.pottyTime == 1) chips.add('定点如厕');
  return chips.where((s) => s.isNotEmpty).toList();
}

String _medicationText(int? v) {
  if (v == null) return '';
  return {0: '无需用药', 1: '需按时服药', 2: '需要营养品'}[v] ?? '';
}

// ── Page ─────────────────────────────────────────────────────────

class PetDetailPage extends ConsumerStatefulWidget {
  final String id;
  const PetDetailPage({super.key, required this.id});

  @override
  ConsumerState<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends ConsumerState<PetDetailPage> {
  _PetDetail? _pet;
  bool _loading = true;
  int _photoIndex = 0;
  final _pageCtrl = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post(
        PetApi.getById,
        data: {'id': widget.id},
      );
      final data = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>?;
      if (content != null && mounted) {
        setState(() => _pet = _PetDetail.fromJson(content));
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppNavBar(title: ''),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pet == null
              ? const Center(child: Text('加载失败'))
              : Stack(
                  children: [
                    _buildContent(),
                    // 底部编辑按钮
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildEditBar(bottom),
                    ),
                  ],
                ),
    );
  }

  Widget _buildContent() {
    final p = _pet!;
    final photos = p.livePhotoUrls.isNotEmpty
        ? p.livePhotoUrls
        : (p.avatarUrl.isNotEmpty ? [p.avatarUrl] : <String>[]);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        children: [
          // 图片轮播
          _buildGallery(photos),
          const SizedBox(height: 12),
          // 主信息卡
          _buildInfoCard(p),
        ],
      ),
    );
  }

  // ── 图片区 ────────────────────────────────────────────────────

  Widget _buildGallery(List<String> photos) {
    if (photos.isEmpty) {
      return Container(
        height: 260,
        color: const Color(0xFFF0EDE8),
        child: const Center(
          child: Icon(Icons.pets, size: 72, color: Color(0xFFCCBBAA)),
        ),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: photos.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (ctx, i) => CachedNetworkImage(
              imageUrl: photos[i],
              fit: BoxFit.cover,
              width: double.infinity,
              errorWidget: (ctx2, url, err) => Container(
                color: const Color(0xFFF0EDE8),
                child: const Icon(Icons.pets, size: 72, color: Color(0xFFCCBBAA)),
              ),
            ),
          ),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => Container(
                  width: i == _photoIndex ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _photoIndex
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── 信息卡 ────────────────────────────────────────────────────

  Widget _buildInfoCard(_PetDetail p) {
    final chips = _buildChips(p);
    final medText = _medicationText(p.medicationNeeds);
    final hasExtraInfo = medText.isNotEmpty ||
        (p.healthDesc?.isNotEmpty == true) ||
        (p.otherDesc?.isNotEmpty == true);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像 + 名字 + 基础信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像
                ClipOval(
                  child: p.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: p.avatarUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorWidget: (ctx, url, err) =>
                              _avatarFallback(p.species),
                        )
                      : _avatarFallback(p.species),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name.isNotEmpty ? p.name : '未命名',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _metaTag(_ageText(p.birthDate)),
                          _metaTag(_weightText(p.weight)),
                          _metaTag(_genderText(p.gender)),
                          if (p.birthDate != null &&
                              p.birthDate!.isNotEmpty)
                            _metaTag(p.birthDate!
                                .replaceAll('-', '.')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 标签区
          if (chips.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: Color(0xFFFF7E51)),
                      const SizedBox(width: 6),
                      const Text('关于我',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips
                        .map((t) => _chip(t))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],

          // 用药 / 健康 / 其他
          if (hasExtraInfo) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (medText.isNotEmpty) ...[
                    _sectionLabel(
                        Icons.medication_outlined, '用药情况'),
                    const SizedBox(height: 6),
                    Text(medText,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.5)),
                    const SizedBox(height: 12),
                  ],
                  if (p.healthDesc?.isNotEmpty == true) ...[
                    _sectionLabel(
                        Icons.health_and_safety_outlined, '健康情况'),
                    const SizedBox(height: 6),
                    Text(p.healthDesc!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.5)),
                    const SizedBox(height: 12),
                  ],
                  if (p.otherDesc?.isNotEmpty == true) ...[
                    _sectionLabel(
                        Icons.notes_rounded, '其他描述'),
                    const SizedBox(height: 6),
                    Text(p.otherDesc!,
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                            height: 1.5)),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _avatarFallback(int species) {
    return Container(
      width: 64,
      height: 64,
      color: const Color(0xFFF5F0EA),
      child: Icon(
        species == 2 ? Icons.cruelty_free : Icons.pets,
        size: 32,
        color: const Color(0xFFCCBBAA),
      ),
    );
  }

  Widget _metaTag(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF666666))),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFFAA5100))),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Color(0xFFFF7E51)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666))),
      ],
    );
  }

  // ── 底部编辑按钮 ──────────────────────────────────────────────

  Widget _buildEditBar(double bottom) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () async {
            await context.push('/pet-add?id=${widget.id}');
            _load(); // 返回后刷新
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF7E51),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('编辑宠物信息',
              style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
