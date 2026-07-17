import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/logging/app_log.dart';
import 'package:kgmusic/core/logging/app_log_entry.dart';
import 'package:kgmusic/core/logging/app_log_level.dart';
import 'package:kgmusic/core/logging/app_log_store.dart';

void main() {
  late Directory directory;
  late AppLogStore store;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('kgmusic-log-test-');
    store = AppLogStore(directory);
    await store.initialize();
    AppLog.initialize(store, AppLogLevel.trace);
  });

  tearDown(() async {
    await store.flush();
    await directory.delete(recursive: true);
    AppLog.setLevel(AppLogLevel.info);
  });

  test('JSONL entry round-trip preserves diagnostics', () {
    final entry = AppLogEntry(
      timestamp: DateTime.fromMillisecondsSinceEpoch(1234),
      level: AppLogLevel.warn,
      source: 'native',
      target: 'kugou_sdk::protocol',
      message: 'line one\nline two',
      error: 'failure',
      stackTrace: 'stack',
    );
    final decoded = AppLogEntry.tryParse(entry.toJsonLine());
    expect(decoded, isNotNull);
    expect(decoded!.message, entry.message);
    expect(decoded.level, AppLogLevel.warn);
    expect(decoded.details, contains('stack'));
  });

  test('Flutter logging redacts credentials and phone numbers', () async {
    AppLog.info(
      'token=secret signature:abc mobile=13800138000 sms_code=123456',
      target: 'test',
    );
    await store.flush();
    final entries = await store.readEntries();
    expect(entries, hasLength(1));
    expect(entries.single.message, contains('token=***'));
    expect(entries.single.message, contains('signature:***'));
    expect(entries.single.message, contains('138****8000'));
    expect(entries.single.message, contains('sms_code=***'));
    expect(entries.single.message, isNot(contains('secret')));
    expect(entries.single.message, isNot(contains('123456')));
  });

  test('configured level filters verbose records', () async {
    AppLog.setLevel(AppLogLevel.warn);
    AppLog.info('hidden', target: 'test');
    AppLog.warn('visible', target: 'test');
    await store.flush();
    final entries = await store.readEntries();
    expect(entries.map((entry) => entry.message), ['visible']);
  });

  test('reader merges Flutter and native records by newest first', () async {
    await store.append(
      AppLogEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
        level: AppLogLevel.info,
        source: 'flutter',
        target: 'test',
        message: 'older',
      ),
    );
    await File('${directory.path}/native-current.jsonl').writeAsString(
      '${AppLogEntry(timestamp: DateTime.fromMillisecondsSinceEpoch(2000), level: AppLogLevel.debug, source: 'native', target: 'kugou_sdk::client', message: 'newer').toJsonLine()}\n',
    );
    final entries = await store.readEntries();
    expect(entries.map((entry) => entry.message), ['newer', 'older']);
  });

  test(
    'serialized writer keeps concurrent records and can reopen after clear',
    () async {
      await Future.wait([
        for (var index = 0; index < 50; index++)
          store.append(
            AppLogEntry(
              timestamp: DateTime.fromMillisecondsSinceEpoch(index),
              level: AppLogLevel.debug,
              source: 'flutter',
              target: 'test',
              message: 'entry-$index',
            ),
          ),
      ]);
      expect(await store.readEntries(), hasLength(50));

      await store.clearFlutterLogs();
      expect(await store.readEntries(), isEmpty);
      await store.append(
        AppLogEntry(
          timestamp: DateTime.fromMillisecondsSinceEpoch(100),
          level: AppLogLevel.info,
          source: 'flutter',
          target: 'test',
          message: 'after-clear',
        ),
      );
      expect((await store.readEntries()).single.message, 'after-clear');
    },
  );
}
