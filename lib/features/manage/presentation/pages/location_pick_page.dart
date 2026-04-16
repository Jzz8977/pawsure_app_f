import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:tencent_map_flutter/tencent_map_flutter.dart';

import '../../../../core/constants/api_constants.dart';

// ── 结果模型 ──────────────────────────────────────────────────────

class LocationPickResult {
  final double latitude;
  final double longitude;
  final String province;
  final String city;
  final String district;
  final String address;

  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    required this.province,
    required this.city,
    required this.district,
    required this.address,
  });
}

// ── Page ──────────────────────────────────────────────────────────

class LocationPickPage extends StatefulWidget {
  /// 地图初始中心点（可传入已有坐标）
  final double? initialLat;
  final double? initialLng;

  const LocationPickPage({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickPage> createState() => _LocationPickPageState();
}

class _LocationPickPageState extends State<LocationPickPage> {
  // 当前中心坐标
  double _lat = 39.9042; // 默认北京
  double _lng = 116.4074;

  // 当前逆地理信息
  String _address = '移动地图以选择位置';
  String _province = '';
  String _city = '';
  String _district = '';
  bool _geocoding = false;

  // 防抖
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _lat = widget.initialLat!;
      _lng = widget.initialLng!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // ── 地图创建完成后移动到初始位置 ─────────────────────────────────

  void _onMapCreated(TencentMapController ctrl) {
    ctrl.moveCamera(
      CameraPosition(
        position: LatLng(_lat, _lng),
        zoom: 16,
      ),
    );
    // 加载初始点的地址
    _scheduleGeocode(_lat, _lng);
  }

  // ── 相机停止移动时触发逆地理编码 ─────────────────────────────────

  void _onCameraMoveEnd(CameraPosition position) {
    final lat = position.position?.latitude ?? _lat;
    final lng = position.position?.longitude ?? _lng;
    _lat = lat;
    _lng = lng;
    _scheduleGeocode(lat, lng);
  }

  void _scheduleGeocode(double lat, double lng) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(lat, lng);
    });
  }

  // ── 逆地理编码（腾讯地图 HTTP API）──────────────────────────────

  Future<void> _reverseGeocode(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://apis.map.qq.com/ws/geocoder/v1/',
        queryParameters: {
          'location': '$lat,$lng',
          'key': ApiConstants.tencentMapKey,
          'get_poi': 1,
        },
      );
      final data = res.data as Map<String, dynamic>?;
      if (data?['status'] == 0 && mounted) {
        final result = data!['result'] as Map<String, dynamic>? ?? {};
        final comp =
            result['address_component'] as Map<String, dynamic>? ?? {};
        final formatted =
            result['formatted_addresses'] as Map<String, dynamic>? ?? {};
        setState(() {
          _province = comp['province'] as String? ?? '';
          _city = comp['city'] as String? ?? '';
          _district = comp['district'] as String? ?? '';
          _address = formatted['recommend'] as String? ??
              result['address'] as String? ??
              '$_province$_city$_district';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _address = '无法获取地址信息');
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _onConfirm() {
    if (_province.isEmpty && _city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先移动地图选择位置')),
      );
      return;
    }
    Navigator.pop(
      context,
      LocationPickResult(
        latitude: _lat,
        longitude: _lng,
        province: _province,
        city: _city,
        district: _district,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择地点', style: TextStyle(fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF0F0F0)),
        ),
      ),
      body: Stack(
        children: [
          // ── 地图 ──────────────────────────────────────────────
          TencentMap(
            onMapCreated: _onMapCreated,
            onCameraMoveEnd: _onCameraMoveEnd,
          ),

          // ── 中心固定图钉 ───────────────────────────────────
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36),
              child: Icon(
                Icons.location_pin,
                size: 48,
                color: Color(0xFFFF7E51),
              ),
            ),
          ),

          // ── 底部地址栏 + 确认按钮 ──────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: Color(0xFFFF7E51)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _geocoding
                            ? const Text(
                                '正在获取地址...',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF999999)),
                              )
                            : Text(
                                _address,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF333333),
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  if (_province.isNotEmpty || _city.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Text(
                        '$_province$_city$_district',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _geocoding ? null : _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7E51),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFFF7E51).withAlpha(120),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('确认选择',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
