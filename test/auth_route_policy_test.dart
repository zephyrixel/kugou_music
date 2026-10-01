import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';
import 'package:kgmusic/features/auth/auth_route_policy.dart';

void main() {
  test('启动期间停留在启动页', () {
    expect(
      authRedirect(
        status: AuthStatus.booting,
        authenticated: false,
        location: '/',
      ),
      '/launch',
    );
  });

  test('未认证访问业务页时进入登录页', () {
    expect(
      authRedirect(
        status: AuthStatus.guest,
        authenticated: false,
        location: '/player',
      ),
      '/login',
    );
    expect(
      authRedirect(
        status: AuthStatus.expired,
        authenticated: false,
        location: '/login',
      ),
      isNull,
    );
  });

  test('认证完成后离开认证页且保留业务路由', () {
    expect(
      authRedirect(
        status: AuthStatus.authenticated,
        authenticated: true,
        location: '/login',
      ),
      '/',
    );
    expect(
      authRedirect(
        status: AuthStatus.authenticated,
        authenticated: true,
        location: '/library',
      ),
      isNull,
    );
  });
}
