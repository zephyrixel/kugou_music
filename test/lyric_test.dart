import 'package:flutter_test/flutter_test.dart';
import 'package:kgmusic/core/models/lyric.dart';

void main() {
  const document = LyricDocument(
    format: LyricFormat.krc,
    offsetMs: -100,
    lines: [
      LyricLine(
        startMs: 1000,
        durationMs: 800,
        text: '你好',
        words: [
          LyricWord(startMs: 0, durationMs: 300, text: '你'),
          LyricWord(startMs: 300, durationMs: 300, text: '好'),
        ],
        translation: 'hello',
        transliteration: 'ni hao',
      ),
      LyricLine(startMs: 2000, durationMs: 500, text: '世界'),
    ],
  );

  test('timeline lookup applies offset and keeps the last active line', () {
    expect(document.lineIndexAt(899), isNull);
    expect(document.lineIndexAt(900), 0);
    expect(document.lineIndexAt(1899), 0);
    expect(document.lineIndexAt(1900), 1);
    expect(document.lineIndexAt(9999), 1);
    expect(document.seekPositionMs(0), 900);
  });

  test('word lookup advances on KRC word boundaries', () {
    expect(document.playedWordCount(0, 899), 0);
    expect(document.playedWordCount(0, 900), 1);
    expect(document.playedWordCount(0, 1199), 1);
    expect(document.playedWordCount(0, 1200), 2);
  });

  test('translation is preferred and transliteration is the fallback', () {
    expect(document.lines.first.secondaryText, 'hello');
    expect(
      const LyricLine(
        startMs: 0,
        durationMs: 0,
        text: 'test',
        transliteration: 'romanized',
      ).secondaryText,
      'romanized',
    );
  });
}
