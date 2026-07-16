import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kgmusic/app/providers.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/features/auth/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth.authenticated) return child;
    if (auth.status == AuthStatus.booting ||
        auth.status == AuthStatus.syncingLibrary) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 18),
              Text(
                auth.status == AuthStatus.booting ? '正在恢复登录…' : '正在初始化音乐库…',
                style: const TextStyle(color: KgColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }
    if (auth.snapshot.authenticated) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 60,
                    color: KgColors.warning,
                  ),
                  const SizedBox(height: 18),
                  Text(auth.message ?? '音乐库初始化失败', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: auth.busy
                        ? null
                        : auth.retryLibraryInitialization,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('重试'),
                  ),
                  TextButton(
                    onPressed: auth.busy ? null : auth.logout,
                    child: const Text('退出登录'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const LoginScreen();
  }
}
