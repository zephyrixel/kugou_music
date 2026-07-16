import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _mobile = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _mobile.dispose();
    _code.dispose();
    super.dispose();
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
                  '使用酷狗短信验证码登录 Lite 账号，继续你的音乐与歌单。',
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: '手机号',
                          hintText: '13800138000',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                      ),
                      const SizedBox(height: KgSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _code,
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                                labelText: '验证码',
                                prefixIcon: Icon(Icons.password_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: KgSpacing.sm),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              onPressed: auth.busy || auth.resendSeconds > 0
                                  ? null
                                  : () => auth.sendCode(_mobile.text.trim()),
                              child: Text(
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
                        onPressed: auth.busy
                            ? null
                            : () => auth.login(
                                _mobile.text.trim(),
                                _code.text.trim(),
                              ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: auth.busy
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF15182A),
                                ),
                              )
                            : const Text('登录'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: KgSpacing.md),
                const Text(
                  '登录成功后会自动登记设备指纹。手机号不会写入本地数据库或日志。',
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
