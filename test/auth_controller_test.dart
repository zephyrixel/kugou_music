import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/auth/account_session.dart';
import 'package:kgmusic/core/database/app_database.dart';
import 'package:kgmusic/core/library/library_remote.dart';
import 'package:kgmusic/core/library/library_repository.dart';
import 'package:kgmusic/core/library/library_store.dart';
import 'package:kgmusic/core/models/account.dart';
import 'package:kgmusic/core/models/history_entry.dart';
import 'package:kgmusic/core/models/playlist.dart';
import 'package:kgmusic/core/native/auth_storage_keys.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/features/auth/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late AccountSession session;
  late _AuthSdk sdk;
  late _Storage storage;
  late _Remote remote;
  late LibraryRepository library;
  late AuthController auth;
  var cleared = 0;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    session = AccountSession();
    sdk = _AuthSdk();
    storage = _Storage()
      ..values[AuthStorageKeys.lastRefreshAt] = DateTime.now()
          .toUtc()
          .toIso8601String();
    remote = _Remote();
    library = LibraryRepository(
      LibraryStore(database),
      remote,
      accountSession: session,
    );
    cleared = 0;
    auth = AuthController(
      sdk,
      storage,
      database,
      library,
      accountSession: session,
      onSessionCleared: () async {
        cleared++;
      },
    );
  });
  tearDown(() async {
    auth.dispose();
    await library.dispose();
    await session.dispose();
    await database.close();
  });

  test(
    'login succeeds before the library finishes and stays authenticated on sync failure',
    () async {
      await auth.initialize();
      remote.gate = Completer();
      expect(await auth.login('13800138000', '123456'), isTrue);
      expect(auth.authenticated, isTrue);
      expect(library.ready, isFalse);
      final failed = expectLater(library.syncNow(), throwsStateError);
      await remote.started.future;
      remote.gate!.completeError(StateError('offline'));
      await failed;
      expect(auth.status, AuthStatus.authenticated);
      expect(library.status.failed, isTrue);
      remote.gate = null;
      await library.syncNow();
      expect(library.ready, isTrue);
    },
  );

  test(
    'expiration from any SDK request clears the account only once',
    () async {
      sdk.current = account;
      await auth.initialize();
      await library.syncNow();
      session.expire();
      session.expire();
      await auth.logout();
      expect(auth.authenticated, isFalse);
      expect(auth.status, AuthStatus.expired);
      expect(sdk.logouts, 1);
      expect(cleared, 1);
    },
  );

  test('a late token refresh cannot restore an account after logout', () async {
    sdk.current = account;
    await auth.initialize();
    await library.syncNow();
    sdk.refreshGate = Completer<AuthSnapshot>();
    final refresh = auth.refreshIfDue(force: true);
    await sdk.refreshStarted.future;
    await auth.logout();
    sdk.refreshGate!.complete(account);
    await refresh;
    expect(auth.authenticated, isFalse);
    expect(auth.status, AuthStatus.guest);
  });

  test('cleanup continues when SDK logout fails', () async {
    sdk.current = account;
    await auth.initialize();
    await library.syncNow();
    storage.values[AuthStorageKeys.sessionV2] = 'test-envelope';
    await database.writeCachedResponse(
      cacheKey: 'private',
      accountUserId: 7,
      codecVersion: 1,
      payload: '{}',
    );
    sdk.failLogout = true;
    await auth.logout();
    expect(auth.authenticated, isFalse);
    expect(storage.values[AuthStorageKeys.sessionV2], isNull);
    expect(await database.readCachedResponse('private'), isNull);
    expect(cleared, 1);
  });

  test('the same account after logout has a different generation', () {
    session.update(account);
    final previous = session.generation;
    session.invalidate();
    session.update(account);
    expect(session.isCurrent(previous), isFalse);
  });
}

const account = AuthSnapshot(
  authenticated: true,
  fingerprintRegistered: true,
  userId: 7,
);

class _AuthSdk implements AuthSdk {
  AuthSnapshot current = AccountSession.guest;
  Completer<AuthSnapshot>? refreshGate;
  final refreshStarted = Completer<void>();
  var logouts = 0;
  var failLogout = false;
  @override
  Future<void> initialize() async {}
  @override
  Future<AuthSnapshot> authState() async => current;
  @override
  Future<void> sendSmsCode(String mobile) async {}
  @override
  Future<AuthSnapshot> loginBySms(String mobile, String code) async =>
      current = account;
  @override
  Future<AuthSnapshot> refreshLogin() {
    if (!refreshStarted.isCompleted) refreshStarted.complete();
    return refreshGate?.future ?? Future.value(current);
  }

  @override
  Future<AuthSnapshot> registerDevice() async => current;
  @override
  Future<AuthSnapshot> ensureDeviceRegistered() async => current;
  @override
  Future<void> logout() async {
    logouts++;
    if (failLogout) throw StateError('SDK unavailable');
    current = AccountSession.guest;
  }
}

class _Remote implements LibraryRemote {
  Completer<List<Playlist>>? gate;
  final started = Completer<void>();
  @override
  Future<List<Playlist>> fetchAllPlaylists() {
    if (!started.isCompleted) started.complete();
    return gate?.future ?? Future.value(const []);
  }

  @override
  Future<List<HistoryEntry>> fetchHistory() async => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Storage extends FlutterSecureStorage {
  final values = <String, String>{};
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}
