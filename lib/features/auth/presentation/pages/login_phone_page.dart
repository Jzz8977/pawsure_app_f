import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/crypto_utils.dart';
import '../../../../core/wechat/wechat_login_service.dart';
import '../../../../shared/providers/user_provider.dart';

// ── 设计 Token ─────────────────────────────────────────────────
const _kPrimary = Color(0xFFFF9E4A);
const _kGold = Color(0xFFCC9933);
const _kLink = Color(0xFF1F7AE0);
const _kWechat = Color(0xFF07C160);
const _kBorder = Color(0xFFE5E5E5);
const _kPlaceholder = Color(0x40000000);

class LoginPhonePage extends ConsumerStatefulWidget {
  const LoginPhonePage({super.key});

  @override
  ConsumerState<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends ConsumerState<LoginPhonePage> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  bool _hasAgreed = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  Timer? _timer;

  // 待完成的操作（同意协议后触发）
  _PendingAction? _pending;

  // 微信授权进行中
  bool _wechatLoading = false;

  // ── 表单校验 ─────────────────────────────────────────────────

  bool get _phoneValid => RegExp(r'^1[3-9]\d{9}$').hasMatch(_phoneCtrl.text);
  bool get _canGetCode => _phoneValid && _countdown == 0 && !_isSendingCode;
  bool get _canLogin =>
      _phoneValid && _codeCtrl.text.length == 6 && !_isLoading;

  // ── 生命周期 ─────────────────────────────────────────────────

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── 倒计时 ───────────────────────────────────────────────────

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _countdown--;
        if (_countdown <= 0) { _countdown = 0; t.cancel(); }
      });
    });
  }

  // ── 获取验证码 ───────────────────────────────────────────────

  Future<void> _getCode() async {
    if (!_phoneValid) { _toast('手机号格式不正确'); return; }
    if (!_hasAgreed) {
      setState(() => _pending = _PendingAction.getCode);
      _showAgreementModal();
      return;
    }
    setState(() => _isSendingCode = true);
    try {
      final encrypted = CryptoUtils.aesEncrypt(_phoneCtrl.text);
      await ref.read(dioProvider).post(
        AuthApi.phoneGetCode,
        data: {'phone': encrypted},
      );
      _startCountdown();
      _toast('验证码已发送至 ${_maskPhone(_phoneCtrl.text)}');
    } on DioException catch (e) {
      _toast(_parseError(e, '验证码发送失败，请重试'));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  // ── 手机号登录 ────────────────────────────────────────────────

  Future<void> _login() async {
    if (!_canLogin) return;
    if (!_hasAgreed) {
      setState(() => _pending = _PendingAction.login);
      _showAgreementModal();
      return;
    }
    setState(() => _isLoading = true);
    try {
      final encrypted = CryptoUtils.aesEncrypt(_phoneCtrl.text);
      // 业务失败已由 BusinessErrorInterceptor 转成 DioException
      await ref.read(dioProvider).post(
        AuthApi.phoneLogin,
        data: {'phone': encrypted, 'phoneCode': _codeCtrl.text},
      );
      // Token 已由 TokenInterceptor 从响应 Header 中提取并存储
      await _fetchAndSetUser();
    } on DioException catch (e) {
      _toast(_parseError(e, '登录失败，请重试'));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAndSetUser() async {
    try {
      final res = await ref.read(dioProvider).post(CustomerApi.getInfo);

      // 服务端返回格式：{ success: true, content: { ... } }
      final data    = res.data as Map<String, dynamic>?;
      final content = data?['content'] as Map<String, dynamic>? ?? data ?? {};

      final user = UserModel.fromJson(content, rawPhone: _phoneCtrl.text);

      // ── 打印便于调试 ─────────────────────────────────────────
      debugPrint('>>> [Login] UserModel: $user');

      await ref.read(userNotifierProvider.notifier).login(user);

      if (mounted) {
        context.go(
          user.role == UserRole.provider ? '/provider-home' : '/home',
        );
      }
    } catch (e) {
      debugPrint('>>> [Login] fetchUserInfo failed: $e');
      // 降级：token 已存，用最小模型进入首页，下次打开会读取 storage
      final fallback = UserModel(
        id: '',
        name: '',
        phone: _phoneCtrl.text,
        displayPhone: '',
        role: UserRole.petOwner,
      );
      await ref.read(userNotifierProvider.notifier).login(fallback);
      if (mounted) context.go('/home');
    }
  }

  // ── 微信登录 ─────────────────────────────────────────────────

  Future<void> _wechatLogin() async {
    if (_wechatLoading) return;
    if (!_hasAgreed) {
      setState(() => _pending = _PendingAction.wechat);
      _showAgreementModal();
      return;
    }
    setState(() => _wechatLoading = true);
    try {
      final result =
          await ref.read(wechatLoginServiceProvider).login();
      if (!mounted) return;
      switch (result) {
        case WeChatLoginSuccess(:final user):
          context.go(
            user.role == UserRole.provider ? '/provider-home' : '/home',
          );
          break;
        case WeChatLoginCancelled():
          _toast('已取消授权');
          break;
        case WeChatLoginNotInstalled():
          _toast('请先安装微信');
          break;
        case WeChatLoginUnsupported():
          _toast('当前环境暂不支持微信登录');
          break;
        case WeChatLoginFailed(:final message):
          _toast(message);
          break;
      }
    } finally {
      if (mounted) setState(() => _wechatLoading = false);
    }
  }

  // ── 协议弹窗 ─────────────────────────────────────────────────

  void _showAgreementModal() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _AgreementDialog(
        onCancel: () { setState(() => _pending = null); },
        onConfirm: () {
          setState(() => _hasAgreed = true);
          final action = _pending;
          setState(() => _pending = null);
          if (action == _PendingAction.getCode) _getCode();
          if (action == _PendingAction.login) _login();
          if (action == _PendingAction.wechat) _wechatLogin();
        },
        onShowTerms: () => _showDoc('服务条款'),
        onShowPrivacy: () => _showDoc('隐私协议'),
      ),
    );
  }

  void _showDoc(String title) {
    // TODO: 跳转至完整协议页
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('协议内容加载中...'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('我知道了'))],
      ),
    );
  }

  // ── 工具方法 ─────────────────────────────────────────────────

  String _maskPhone(String p) {
    if (p.length < 7) return p;
    return '${p.substring(0, 3)}****${p.substring(p.length - 4)}';
  }

  String _parseError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) return data['message']?.toString() ?? fallback;
    return fallback;
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // ── 顶部背景渐变 ──────────────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                height: MediaQuery.of(context).size.height * 0.42,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFF5E0), Colors.white],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),

              // ── 页面主体 ──────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Logo 区
                    _buildHeader(),
                    // 表单区（可滚动）
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(37, 0, 37, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            _buildPhoneInput(),
                            const SizedBox(height: 20),
                            _buildCodeInput(),
                            const SizedBox(height: 12),
                            _buildLoginButton(),
                            const SizedBox(height: 30),
                            _buildDivider(),
                            const SizedBox(height: 20),
                            _buildWeChatButton(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    // 底部协议
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo 区 ───────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          // Logo 圆形图标
          ClipOval(
            child: SvgPicture.asset(
              'assets/icons/logo.svg',
              width: 85,
              height: 85,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          // Logo 文字图片
          Image.asset(
            'assets/images/logo-text.png',
            width: 90,
            height: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 20),
          // 欢迎文字
          const Text(
            'Hello，欢迎来到宠信',
            style: TextStyle(
              fontSize: 18,
              color: _kGold,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── 手机号输入 ────────────────────────────────────────────────

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BottomBorderInput(
          controller: _phoneCtrl,
          hintText: '输入手机号',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        const Text(
          '我们将发送验证码至此手机号',
          style: TextStyle(fontSize: 12, color: Color(0x73000000)),
        ),
      ],
    );
  }

  // ── 验证码输入 ────────────────────────────────────────────────

  Widget _buildCodeInput() {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        _BottomBorderInput(
          controller: _codeCtrl,
          hintText: '输入验证码',
          keyboardType: TextInputType.number,
          contentPadding: const EdgeInsets.only(right: 110, bottom: 14, top: 14),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => setState(() {}),
        ),
        Positioned(
          right: 0,
          child: _CodeButton(
            countdown: _countdown,
            loading: _isSendingCode,
            enabled: _canGetCode,
            onTap: _getCode,
          ),
        ),
      ],
    );
  }

  // ── 登录按钮 ──────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _canLogin && !_isLoading ? _login : null,
      child: AnimatedOpacity(
        opacity: _canLogin ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFEA88), _kPrimary],
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '登录',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }

  // ── 分隔线 ────────────────────────────────────────────────────

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.1))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '其他登录方式',
            style: TextStyle(fontSize: 13, color: Color(0x73000000)),
          ),
        ),
        Expanded(child: Divider(color: Colors.black.withValues(alpha: 0.1))),
      ],
    );
  }

  // ── 微信登录按钮 ──────────────────────────────────────────────

  Widget _buildWeChatButton() {
    return Center(
      child: GestureDetector(
        onTap: _wechatLoading ? null : _wechatLogin,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _kWechat,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kWechat.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _wechatLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/images/login/wechat1.svg',
                    width: 32,
                    height: 32,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
          ),
        ),
      ),
    );
  }

  // ── 底部协议 ──────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => setState(() => _hasAgreed = !_hasAgreed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _hasAgreed ? _kWechat : Colors.white,
                border: Border.all(
                  color: _hasAgreed ? _kWechat : const Color(0xFFCCCCCC),
                ),
              ),
              child: _hasAgreed
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 11, color: Color(0xFF3D3D3D)),
                children: [
                  const TextSpan(text: '我已阅读并同意宠信用户'),
                  TextSpan(
                    text: '《服务条款》',
                    style: const TextStyle(color: _kLink),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showDoc('服务条款'),
                  ),
                  const TextSpan(text: '与'),
                  TextSpan(
                    text: '《隐私协议》',
                    style: const TextStyle(color: _kLink),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _showDoc('隐私协议'),
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

// ── 枚举 ──────────────────────────────────────────────────────

enum _PendingAction { getCode, login, wechat }

// ── 底部边框输入框 ─────────────────────────────────────────────

class _BottomBorderInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final EdgeInsetsGeometry? contentPadding;
  final ValueChanged<String>? onChanged;

  const _BottomBorderInput({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    this.inputFormatters,
    this.contentPadding,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 14, color: _kPlaceholder),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _kPrimary),
        ),
        border: const UnderlineInputBorder(),
      ),
    );
  }
}

// ── 获取验证码按钮 ────────────────────────────────────────────

class _CodeButton extends StatelessWidget {
  final int countdown;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _CodeButton({
    required this.countdown,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  String get _label {
    if (loading) return '发送中...';
    if (countdown > 0) return '${countdown}s后重发';
    return '获取验证码';
  }

  @override
  Widget build(BuildContext context) {
    final active = enabled && !loading;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFFFFB257), Color(0xFFFFA042)],
                )
              : null,
          color: active ? null : const Color(0xFFDDDDDD),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.white : const Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}

// ── 协议确认弹窗 ──────────────────────────────────────────────

class _AgreementDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final VoidCallback onShowTerms;
  final VoidCallback onShowPrivacy;

  const _AgreementDialog({
    required this.onCancel,
    required this.onConfirm,
    required this.onShowTerms,
    required this.onShowPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 12),
            child: Text(
              '温馨提示',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.6),
                children: [
                  const TextSpan(text: '请您阅读并同意'),
                  TextSpan(
                    text: '《服务条款》',
                    style: const TextStyle(color: _kLink),
                    recognizer: TapGestureRecognizer()..onTap = onShowTerms,
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私协议》',
                    style: const TextStyle(color: _kLink),
                    recognizer: TapGestureRecognizer()..onTap = onShowPrivacy,
                  ),
                  const TextSpan(text: '后继续使用我们的服务。'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); onCancel(); },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('取消', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.pop(context); onConfirm(); },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          '同意并继续',
                          style: TextStyle(fontSize: 16, color: _kWechat, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
