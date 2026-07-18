import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/cache/audio_cache.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/native/music_sdk.dart';
import 'package:kgmusic/core/preferences/app_settings.dart';
import 'package:kgmusic/features/settings/settings_sections.dart';

void main() {
  testWidgets('quality picker exposes every supported playback quality', (
    tester,
  ) async {
    AudioQuality? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showQualityPicker(
                  context,
                  selected: AudioQuality.standard,
                );
              },
              child: const Text('选择音质'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('选择音质'));
    await tester.pumpAndSettle();
    expect(find.text(AudioQuality.standard.label), findsOneWidget);
    expect(find.text(AudioQuality.high.label), findsOneWidget);
    expect(find.text(AudioQuality.flac.label), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AudioQuality.superQuality.label),
      120,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text(AudioQuality.superQuality.label));
    await tester.pumpAndSettle();
    expect(selected, AudioQuality.superQuality);
  });

  testWidgets('cache slider previews changes and commits only on release', (
    tester,
  ) async {
    final changes = <double>[];
    final commits = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildKgTheme(),
        home: Scaffold(
          body: StorageSettingsPanel(
            usage: const AudioCacheUsage(
              totalBytes: 128 * AudioCacheLimits.mebibyte,
              maxBytes: AudioCacheLimits.defaultBytes,
            ),
            loadingUsage: false,
            limitBytes: AudioCacheLimits.defaultBytes,
            busy: false,
            onChanged: changes.add,
            onChangeEnd: commits.add,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pump();

    expect(changes, isNotEmpty);
    expect(commits, hasLength(1));
    expect(find.textContaining('已使用 128.0 MB'), findsOneWidget);
  });
}
