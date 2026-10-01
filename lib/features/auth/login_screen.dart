import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_animated_size.dart';
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
    final codeField = TextField(
      controller: _code,
      focusNode: _codeFocus,
      keyboardType: TextInputType.number,
      autofillHints: const [AutofillHints.oneTimeCode],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (!auth.busy) _submitLogin();
      },
      onChanged: (_) {
        if (_codeError != null) setState(() => _codeError = null);
      },
      maxLength: 8,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: '',
        labelText: '验证码',
        errorText: _codeError,
      ),
    );
    final sendCode = OutlinedButton(
      onPressed: auth.busy || auth.resendSeconds > 0 ? null : _requestCode,
      style: OutlinedButton.styleFrom(minimumSize: const Size(112, 56)),
      child: auth.status == AuthStatus.sendingCode
          ? const KgBusyIndicator(size: 20)
          : Text(
              auth.resendSeconds > 0 ? '${auth.resendSeconds} 秒后重试' : '获取验证码',
            ),
    );
    return Scaffold(
      body: SafeArea(
        child: KgContentWidth(
          maxWidth: 480,
          child: AutofillGroup(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.viewInsetsOf(context).bottom > 0 ? 24 : 56,
                24,
                32,
              ),
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    size: 40,
                    color: KgColors.accent,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '登录 KGMusic',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  '使用酷狗账号的手机号登录',
                  style: TextStyle(color: KgColors.textMuted),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
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
                    errorText: _mobileError,
                  ),
                ),
                const SizedBox(height: 16),
                if (MediaQuery.textScalerOf(context).scale(14) > 21)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [codeField, const SizedBox(height: 12), sendCode],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: codeField),
                      const SizedBox(width: 12),
                      sendCode,
                    ],
                  ),
                KgAnimatedSize(
                  duration: KgMotion.resolve(context, KgMotion.fast),
                  child: auth.message == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            auth.message!,
                            style: const TextStyle(color: KgColors.warning),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: auth.busy ? null : _submitLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: auth.status == AuthStatus.signingIn
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            KgBusyIndicator(size: 20, color: KgColors.onAccent),
                            SizedBox(width: 10),
                            Text('正在登录'),
                          ],
                        )
                      : const Text('登录'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
