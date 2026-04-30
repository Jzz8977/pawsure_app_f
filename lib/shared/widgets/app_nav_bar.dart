import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 通用顶部导航栏
///
/// 布局：[返回 + 头像名] | [标题 / 搜索框（绝对居中）] | [自定义右侧]
///
/// ──────────────────────────────────────────
/// 基础用法：
/// ```dart
/// Scaffold(
///   appBar: AppNavBar(title: '订单详情', showBack: true),
/// )
/// ```
///
/// 透明 + 滑动变色（配合 extendBodyBehindAppBar: true）：
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: AppNavBar(
///     title: '服务商详情',
///     showBack: true,
///     backgroundColor: Colors.transparent,
///     titleColor: Colors.white,
///     enableScrollEffect: true,
///     scrollController: _scrollController,
///   ),
///   body: SingleChildScrollView(controller: _scrollController, ...),
/// )
/// ```
///
/// 搜索框模式：
/// ```dart
/// AppNavBar(
///   showSearch: true,
///   searchPlaceholder: '搜索附近看护师',
///   onSearchChanged: (v) { ... },
/// )
/// ```
class AppNavBar extends StatefulWidget implements PreferredSizeWidget {
  const AppNavBar({
    super.key,
    // 标题
    this.title,
    this.titleAlign = TextAlign.center,
    this.titleColor = const Color(0xFF333333),
    this.titleWeight = FontWeight.w600,
    // 外观
    this.backgroundColor = Colors.white,
    this.showDivider = true,
    // 返回按钮
    this.showBack = true,
    this.backColor,
    this.onBack,
    // 用户信息（紧跟返回按钮右侧）
    this.showUserInfo = false,
    this.avatar,
    this.userName,
    // 滑动变色
    this.enableScrollEffect = false,
    this.scrollController,
    this.scrollThreshold = 60.0,
    this.scrolledBackground = const Color(0xF2FFFFFF),
    this.scrolledTitleColor = const Color(0xFF333333),
    this.scrolledBackColor = const Color(0xFF333333),
    // 搜索框
    this.showSearch = false,
    this.searchPlaceholder = '搜索',
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchFocus,
    this.onSearchBlur,
    // 右侧自定义
    this.actions,
  });

  // ── 标题
  final String? title;
  final TextAlign titleAlign;
  final Color titleColor;
  final FontWeight titleWeight;

  // ── 外观
  final Color backgroundColor;
  final bool showDivider;

  // ── 返回按钮
  final bool showBack;
  final Color? backColor;

  /// null = 调用 Navigator.pop
  final VoidCallback? onBack;

  // ── 用户信息（showBack = true 时生效）
  final bool showUserInfo;

  /// 网络图片 URL 或 AssetImage 字符串
  final String? avatar;
  final String? userName;

  // ── 滑动变色
  final bool enableScrollEffect;
  final ScrollController? scrollController;
  final double scrollThreshold;
  final Color scrolledBackground;
  final Color scrolledTitleColor;
  final Color scrolledBackColor;

  // ── 搜索框
  final bool showSearch;
  final String searchPlaceholder;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;
  final VoidCallback? onSearchFocus;
  final VoidCallback? onSearchBlur;

  // ── 右侧按钮/控件
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(_kNavHeight);

  static const double _kNavHeight = 44.0;

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar> {
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(AppNavBar old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController!.offset;
    final scrolled = offset >= widget.scrollThreshold;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  // ── 有效值（根据滑动状态切换）─────────────────────────────────

  bool get _scrollEffectActive => widget.enableScrollEffect && _isScrolled;

  Color get _effectiveBg =>
      _scrollEffectActive ? widget.scrolledBackground : widget.backgroundColor;

  Color get _effectiveTitleColor =>
      _scrollEffectActive ? widget.scrolledTitleColor : widget.titleColor;

  Color get _effectiveBackColor =>
      widget.backColor ??
      (_scrollEffectActive ? widget.scrolledBackColor : widget.titleColor);

  @override
  Widget build(BuildContext context) {
    // 状态栏图标颜色：背景亮则用深色
    final isDark = ThemeData.estimateBrightnessForColor(_effectiveBg) == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: ClipRect(
        child: BackdropFilter(
          filter: _scrollEffectActive
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _effectiveBg,
              border: widget.showDivider && !widget.enableScrollEffect
                  ? const Border(
                      bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5))
                  : widget.showDivider && _scrollEffectActive
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5))
                      : null,
            ),
            child: SafeArea(
              top: true,
              bottom: false,
              left: false,
              right: false,
              child: SizedBox(
                height: AppNavBar._kNavHeight,
                child: widget.showSearch ? _buildSearchLayout() : _buildTitleLayout(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 标题布局（Stack：title 绝对居中，left/right 覆盖其上）─────

  Widget _buildTitleLayout() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 绝对居中的标题
        if (widget.title != null)
          Positioned.fill(
            left: 16,
            right: 16,
            child: IgnorePointer(
              child: Align(
                alignment: widget.titleAlign == TextAlign.left
                    ? Alignment.centerLeft
                    : Alignment.center,
                child: Padding(
                  padding: widget.titleAlign == TextAlign.left && widget.showBack
                      ? const EdgeInsets.only(left: 30)
                      : EdgeInsets.zero,
                  child: Text(
                    widget.title!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: widget.titleWeight,
                      color: _effectiveTitleColor,
                      shadows: _scrollEffectActive
                          ? null
                          : widget.backgroundColor == Colors.transparent
                              ? [
                                  const Shadow(
                                    color: Color(0x26000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ]
                              : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 左右区域（在 title 之上，可交互）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLeft(),
              _buildRight(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 搜索框布局（Row 布局，搜索框占满剩余空间）────────────────

  Widget _buildSearchLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          if (widget.showBack) ...[
            _buildBackButton(),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: _SearchBox(
              placeholder: widget.searchPlaceholder,
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              onSubmitted: widget.onSearchSubmitted,
              onFocus: widget.onSearchFocus,
              onBlur: widget.onSearchBlur,
            ),
          ),
          if (widget.actions != null && widget.actions!.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...widget.actions!,
          ],
        ],
      ),
    );
  }

  // ── 左侧区域 ──────────────────────────────────────────────────

  Widget _buildLeft() {
    if (!widget.showBack &&
        !(widget.showUserInfo &&
            (widget.avatar != null || widget.userName != null))) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showBack) _buildBackButton(),
        if (widget.showUserInfo &&
            (widget.avatar != null || widget.userName != null)) ...[
          const SizedBox(width: 8),
          if (widget.avatar != null)
            ClipOval(
              child: Image.network(
                widget.avatar!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  width: 28,
                  height: 28,
                  color: const Color(0xFFF5F5F5),
                ),
              ),
            ),
          if (widget.avatar != null && widget.userName != null)
            const SizedBox(width: 6),
          if (widget.userName != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                widget.userName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.maybePop(context);
        }
      },
      child: SizedBox(
        width: 36,
        height: 44,
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: _effectiveBackColor,
          ),
        ),
      ),
    );
  }

  // ── 右侧区域 ──────────────────────────────────────────────────

  Widget _buildRight() {
    if (!widget.showSearch &&
        (widget.actions == null || widget.actions!.isEmpty)) {
      return const SizedBox(width: 36); // 平衡左侧宽度，保证标题真正居中
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: widget.actions ?? [],
    );
  }
}

// ── 搜索框 ─────────────────────────────────────────────────────

class _SearchBox extends StatelessWidget {
  final String placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  const _SearchBox({
    required this.placeholder,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFocus,
    this.onBlur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: Color(0xFF999999)),
          const SizedBox(width: 6),
          Expanded(
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) {
                  onFocus?.call();
                } else {
                  onBlur?.call();
                }
              },
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
