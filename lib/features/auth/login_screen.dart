import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';
import 'package:kgmusic/core/widgets/kg_status.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/features/auth/auth_input.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  String? _mobileError;
  String? _codeError;

  @override
  void dispose() {
    _mobile.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final error = validateMobile(_mobile.text);
    setState(() => _mobileError = error);
    if (error != null) return;
    FocusScope.of(context).unfocus();
    final auth = ref.read(authControllerProvider);
    await auth.sendCode(_mobile.text.trim());
    if (mounted && auth.status == AuthStatus.codeSent) {
      _codeFocus.requestFocus();
    }
  }

  Future<void> _submitLogin() async {
    final mobileError = validateMobile(_mobile.text);
    final codeError = validateSmsCode(_code.text);
    setState(() {
      _mobileError = mobileError;
      _codeError = codeError;
    });
    if (mobileError != null || codeError != null) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider)
        .login(_mobile.text.trim(), _code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.7, -0.8),
            radius: 1.15,
            colors: [Color(0xFF28284B), KgColors.background],
          ),
        ),
        child: SafeArea(
          child: KgContentWidth(
            maxWidth: 540,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                KgSpacing.xl,
                48,
                KgSpacing.xl,
                KgSpacing.xxl,
              ),
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KgColors.accentSoft,
                    borderRadius: BorderRadius.circular(KgRadii.large),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    size: 42,
                    color: KgColors.accent,
                  ),
                ),
                const SizedBox(height: KgSpacing.xl),
                Text('欢迎回来', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: KgSpacing.xs),
                const Text(
                  '使用短信验证码登录，继续你的音乐、收藏与歌单。',
                  style: TextStyle(color: KgColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: KgSpacing.xxl),
                KgSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _mobile,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _codeFocus.requestFocus(),
                        onChanged: (_) {
                          if (_mobileError != null) {
                            setState(() => _mobileError = null);
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        ],
                        decoration: InputDecoration(
                          labelText: '手机号',
                          hintText: '13800138000',
                          prefixIcon: const Icon(Icons.phone_android_rounded),
                          errorText: _mobileError,
                        ),
                      ),
                      const SizedBox(height: KgSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _code,
                              focusNode: _codeFocus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                if (!auth.busy) _submitLogin();
                              },
                              onChanged: (_) {
                                if (_codeError != null) {
                                  setState(() => _codeError = null);
                                }
                              },
                              maxLength: 8,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                labelText: '验证码',
                                prefixIcon: const Icon(Icons.password_rounded),
                                errorText: _codeError,
                              ),
                            ),
                          ),
                          const SizedBox(width: KgSpacing.sm),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: auth.busy || auth.resendSeconds > 0
                                  ? null
                                  : _requestCode,
                              child: auth.status == AuthStatus.sendingCode
                                  ? const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        KgBusyIndicator(size: 16),
                                        SizedBox(width: 8),
                                        Text('发送中…'),
                                      ],
                                    )
                                  : Text(
                                      auth.resendSeconds > 0
                                          ? '${auth.resendSeconds}s'
                                          : '获取验证码',
                                    ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: KgMotion.resolve(context, KgMotion.fast),
                        child: auth.message == null
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: KgSpacing.sm,
                                ),
                                child: Text(
                                  auth.message!,
                                  style: const TextStyle(
                                    color: KgColors.warning,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: KgSpacing.lg),
                      FilledButton(
                        onPressed: auth.busy ? null : _submitLogin,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: auth.status == AuthStatus.signingIn
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  KgBusyIndicator(
                                    size: 20,
                                    color: Color(0xFF15182A),
                                  ),
                                  SizedBox(width: 10),
                                  Text('正在登录…'),
                                ],
                              )
                            : const Text('登录'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KgSpacing.md),
                const Text(
                  '登录时会验证当前设备以保护账号安全，手机号不会写入应用日志。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: KgColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
