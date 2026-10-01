import 'package:kgmusic/features/auth/auth_controller.dart';

String? authRedirect({
  required AuthStatus status,
  required bool authenticated,
  required String location,
}) {
  final isAuthRoute = location == '/login' || location == '/launch';
  if (status == AuthStatus.booting) {
    return location == '/launch' ? null : '/launch';
  }
  if (!authenticated) return location == '/login' ? null : '/login';
  return isAuthRoute ? '/' : null;
}
