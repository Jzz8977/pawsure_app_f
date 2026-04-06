import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = true;     // 显示布局边界
  debugPaintBaselinesEnabled = true; // 显示文字基线
  debugPaintLayerBordersEnabled = true; // 显示层边界
  runApp(const ProviderScope(child: App()));
}
