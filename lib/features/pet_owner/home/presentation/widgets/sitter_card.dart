import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

// ── 数据模型 ──────────────────────────────────────────────────────

class SitterItem {
  final String id;
  final String serviceName;
  final String thumbnailUrl;
  final String avatarUrl;
  final String merchantRating;
  final String distanceKm;
  final bool collected;
  final String? collectId;
  final String basePrice;   // 已转换为元（字符串）
  final String serviceTypeLabel;

  const SitterItem({
    required this.id,
    required this.serviceName,
    required this.thumbnailUrl,
    required this.avatarUrl,
    required this.merchantRating,
    required this.distanceKm,
    required this.collected,
    this.collectId,
    required this.basePrice,
    required this.serviceTypeLabel,
  });

  factory SitterItem.fromJson(Map<String, dynamic> json) {
    // basePrice 服务端返回分（cents），转为元
    final rawPrice = (json['basePrice'] as num?)?.toDouble() ?? 0;
    final yuan = rawPrice / 100;
    final priceStr = yuan == yuan.truncateToDouble()
        ? yuan.toInt().toString()
        : yuan.toStringAsFixed(2);

    return SitterItem(
      id: json['id']?.toString() ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      merchantRating: json['merchantRating']?.toString() ?? '5.0',
      distanceKm: json['distanceKm']?.toString() ?? '0',
      collected: json['collected'] == true,
      collectId: json['collectId']?.toString(),
      basePrice: priceStr,
      serviceTypeLabel: json['serviceTypeLabel'] as String? ??
          json['serviceTypeName'] as String? ??
          json['serviceTypeText'] as String? ??
          '',
    );
  }

  SitterItem copyWith({bool? collected, String? collectId}) => SitterItem(
        id: id,
        serviceName: serviceName,
        thumbnailUrl: thumbnailUrl,
        avatarUrl: avatarUrl,
        merchantRating: merchantRating,
        distanceKm: distanceKm,
        collected: collected ?? this.collected,
        collectId: collectId,
        basePrice: basePrice,
        serviceTypeLabel: serviceTypeLabel,
      );
}

// ── 卡片组件 ──────────────────────────────────────────────────────

class SitterCard extends StatelessWidget {
  final SitterItem item;
  final VoidCallback? onTap;

  /// 点击收藏/取消收藏；参数为当前 collected 状态（点击后取反）
  final ValueChanged<bool>? onLikeTap;

  const SitterCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCover(),
            _buildMeta(),
            _buildFoot(),
          ],
        ),
      ),
    );
  }

  // ── 封面 + 角标 ─────────────────────────────────────────────────

  Widget _buildCover() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: item.thumbnailUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      _placeholder(),
                  placeholder: (_, __) => _placeholder(),
                )
              : _placeholder(),
        ),

        // 服务类型角标（右上）
        if (item.serviceTypeLabel.isNotEmpty)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0x73000000),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Text(
                item.serviceTypeLabel,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),

        // 评分 + 距离（左下）
        Positioned(
          left: 0,
          bottom: 0,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBA027),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Text(
                  '${item.merchantRating}分',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const BoxDecoration(
                  color: Color(0x73000000),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Text(
                  '≤${item.distanceKm}km',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(color: const Color(0xFFF5F5F5));

  // ── 用户行（头像 + 名字 + 收藏）───────────────────────────────

  Widget _buildMeta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          ClipOval(
            child: item.avatarUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.avatarUrl,
                    width: 18,
                    height: 18,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _avatarFallback(),
                    placeholder: (_, __) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.serviceName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF222222)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onLikeTap?.call(item.collected),
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                item.collected ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: item.collected
                    ? const Color(0xFFFF7E51)
                    : const Color(0xFFCCCCCC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        width: 18,
        height: 18,
        color: const Color(0xFFEEEEEE),
      );

  // ── 底部价格 + 认证标签 ─────────────────────────────────────────

  Widget _buildFoot() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          _chip('¥ ${item.basePrice}起', const Color(0xFFAA5100)),
          const SizedBox(width: 5),
          _chip('已认证', const Color(0xFFAFAA98)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: textColor)),
    );
  }
}
