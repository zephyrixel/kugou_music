import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

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
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 40),
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              size: 64,
              color: KgColors.accent,
            ),
            const SizedBox(height: 24),
            Text(
              '登录 KGMusic',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              '使用酷狗短信验证码登录 Lite 账号。登录后会自动登记设备指纹，以减少播放安全验证。',
              style: TextStyle(color: KgColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 32),
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
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      labelText: '验证码',
                      prefixIcon: Icon(Icons.password_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
            if (auth.message != null) ...[
              const SizedBox(height: 14),
              Text(
                auth.message!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.busy
                  ? null
                  : () async {
                      await auth.login(_mobile.text.trim(), _code.text.trim());
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: KgColors.accent,
                foregroundColor: Colors.black,
              ),
              child: auth.busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('登录'),
            ),
            const SizedBox(height: 16),
            const Text(
              '手机号仅用于本次酷狗登录请求，不会保存到本地数据库或日志。',
              textAlign: TextAlign.center,
              style: TextStyle(color: KgColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
