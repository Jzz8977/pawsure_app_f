import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/network/dio_client.dart';
import '../../../../../shared/widgets/app_nav_bar.dart';

// ── 宠物模型 ──────────────────────────────────────────────────────

class _Pet {
  final String id;
  final String name;
  final String breedName;
  final int species;   // 1=狗 2=猫
  final int gender;    // 1=男 2=女
  final String? birthDate;
  final double? weight;
  final String avatarUrl;
  final String age;
  final int? daysUntilBirthday;

  const _Pet({
    required this.id,
    required this.name,
    required this.breedName,
    required this.species,
    required this.gender,
    this.birthDate,
    this.weight,
    required this.avatarUrl,
    required this.age,
    this.daysUntilBirthday,
  });

  factory _Pet.fromJson(Map<String, dynamic> json) {
    final birthDate = json['birthDate'] as String?;
    return _Pet(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      breedName: json['breedName'] as String? ?? '',
      species: (json['species'] as num?)?.toInt() ?? 1,
      gender: (json['gender'] as num?)?.toInt() ?? 0,
      birthDate: birthDate,
      weight: (json['weight'] as num?)?.toDouble(),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      age: _calcAge(birthDate),
      daysUntilBirthday: _daysUntilBirthday(birthDate),
    );
  }

  // ── 工具函数 ─────────────────────────────────────────────────────

  static String _calcAge(String? birthDate) {
    if (birthDate == null) return '';
    final d = DateTime.tryParse(birthDate);
    if (d == null) return '';
    final now = DateTime.now();
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

  static int? _daysUntilBirthday(String? birthDate) {
    if (birthDate == null) return null;
    final d = DateTime.tryParse(birthDate);
    if (d == null) return null;
    final now = DateTime.now();
    var next = DateTime(now.year, d.month, d.day);
    if (next.isBefore(now)) next = DateTime(now.year + 1, d.month, d.day);
    return next.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String get genderLabel {
    if (gender == 1) return '男孩';
    if (gender == 2) return '女孩';
    return '未知';
  }

  String get weightLabel =>
      weight != null ? '${weight!.toStringAsFixed(1)}kg' : '';
}

// ── Page ─────────────────────────────────────────────────────────

class PetsPage extends ConsumerStatefulWidget {
  const PetsPage({super.key});

  @override
  ConsumerState<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends ConsumerState<PetsPage> {
  List<_Pet> _pets = [];
  bool _loading = false;
  String? _openedId; // 当前展开左滑操作的卡片 id

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  // ── API ─────────────────────────────────────────────────────────

  Future<void> _loadPets() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(dioProvider).post(PetApi.pageQuery, data: {});
      final data = res.data as Map<String, dynamic>?;
      final raw = (data?['content'] as List<dynamic>?) ?? [];
      if (mounted) {
        setState(() {
          _pets = raw
              .map((e) => _Pet.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onDelete(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除宠物"$name"的所有信息吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: Color(0xFF666666))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await ref.read(dioProvider).post(PetApi.delete, data: {
        'delIdList': [id],
      });
      setState(() {
        _pets.removeWhere((p) => p.id == id);
        if (_openedId == id) _openedId = null;
      });
    } catch (_) {}
  }

  // ── 左滑控制 ─────────────────────────────────────────────────────

  void _openSwipe(String id) => setState(() => _openedId = id);

  void _closeSwipe() => setState(() => _openedId = null);

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点空白处关闭展开的卡片
      onTap: _closeSwipe,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppNavBar(
          title: '宠物身份铭牌',
          showBack: false,
          backgroundColor: Colors.white,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF1E0), Color(0x24FFF1E0)],
              stops: [0.0, 0.6],
            ),
          ),
          child: _loading && _pets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _pets.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
        ),
      ),
    );
  }

  // ── 空状态 ───────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets, size: 96, color: Color(0xFFE0C9A6)),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: _onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7E51),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('添加宠物', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 宠物列表 ─────────────────────────────────────────────────────

  Widget _buildList() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPets,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              itemCount: _pets.length,
              itemBuilder: (_, i) => _buildCard(_pets[i]),
            ),
          ),
        ),
      ],
    );
  }

  // 顶部操作栏
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(11, 4, 11, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onAdd,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7E51),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '新增',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/customer-service'),
              child: const Icon(
                Icons.headset_mic_outlined,
                size: 22,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 单张卡片（左滑）─────────────────────────────────────────────

  Widget _buildCard(_Pet pet) {
    final isOpen = _openedId == pet.id;
    const revealWidth = 160.0; // 编辑 80 + 删除 80

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 104,
        child: Stack(
          children: [
            // ── 操作按钮层（在卡片下方，右侧露出）──────────────
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 编辑
                  GestureDetector(
                    onTap: () => _onEdit(pet.id),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF508EF9),
                        borderRadius: isOpen
                            ? BorderRadius.zero
                            : const BorderRadius.horizontal(
                                right: Radius.circular(15)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('编辑',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 2)),
                    ),
                  ),
                  // 删除
                  GestureDetector(
                    onTap: () => _onDelete(pet.id, pet.name),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDA624B),
                        borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(15)),
                      ),
                      alignment: Alignment.center,
                      child: const Text('删除',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 2)),
                    ),
                  ),
                ],
              ),
            ),

            // ── 卡片内容层（可左滑平移）────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                  isOpen ? -revealWidth : 0, 0, 0),
              child: _buildCardContent(pet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(_Pet pet) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_openedId != null) {
          _closeSwipe();
        } else {
          context.push('/pet-detail/${pet.id}');
        }
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        if (d.primaryVelocity! < -200) {
          _openSwipe(pet.id);
        } else if (d.primaryVelocity! > 200) {
          if (_openedId == pet.id) _closeSwipe();
        }
      },
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F23272F),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // 头像
            _buildAvatar(pet),
            const SizedBox(width: 12),
            // 基本信息
            Expanded(child: _buildInfo(pet)),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_Pet pet) {
    return ClipOval(
      child: pet.avatarUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: pet.avatarUrl,
              width: 55,
              height: 55,
              fit: BoxFit.cover,
              errorWidget: (ctx, url, err) => _defaultAvatar(pet.species),
            )
          : _defaultAvatar(pet.species),
    );
  }

  Widget _defaultAvatar(int species) {
    return Container(
      width: 55,
      height: 55,
      color: const Color(0xFFF5F0EA),
      child: Icon(
        Icons.pets,
        size: 30,
        color: species == 1
            ? const Color(0xFFBD8B5E)
            : const Color(0xFF9E8A7A),
      ),
    );
  }

  Widget _buildInfo(_Pet pet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧：名字 + 性别/体重
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                pet.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8F5734)),
              ),
              Text(
                '${pet.genderLabel}  ${pet.weightLabel}',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
        // 右侧：年龄 + 距下次生日
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              pet.age,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8F5734)),
            ),
            Text.rich(
              TextSpan(children: [
                const TextSpan(
                  text: '距离下次生日 ',
                  style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
                TextSpan(
                  text: pet.daysUntilBirthday != null
                      ? '${pet.daysUntilBirthday}'
                      : '-',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8F5734)),
                ),
                const TextSpan(
                  text: ' 天',
                  style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  // ── 导航动作 ─────────────────────────────────────────────────────

  Future<void> _onAdd() async {
    await context.push('/pet-add');
    if (mounted) _loadPets();
  }

  Future<void> _onEdit(String id) async {
    _closeSwipe();
    await context.push('/pet-add?id=$id');
    if (mounted) _loadPets();
  }
}
