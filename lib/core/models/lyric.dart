enum LyricFormat { krc, lrc, plain }

class LyricWord {
  const LyricWord({
    required this.startMs,
    required this.durationMs,
    required this.text,
  });

  final int startMs;
  final int durationMs;
  final String text;
}

class LyricLine {
  const LyricLine({
    required this.startMs,
    required this.durationMs,
    required this.text,
    this.words = const [],
    this.translation,
    this.transliteration,
  });

  final int startMs;
  final int durationMs;
  final String text;
  final List<LyricWord> words;
  final String? translation;
  final String? transliteration;

  String? get secondaryText {
    final translated = translation?.trim();
    if (translated != null && translated.isNotEmpty) return translated;
    final transliterated = transliteration?.trim();
    return transliterated == null || transliterated.isEmpty
        ? null
        : transliterated;
  }
}

class LyricDocument {
  const LyricDocument({
    required this.format,
    required this.offsetMs,
    required this.lines,
  });

  final LyricFormat format;
  final int offsetMs;
  final List<LyricLine> lines;

  int effectiveStartMs(LyricLine line) => line.startMs + offsetMs;

  int seekPositionMs(int lineIndex) {
    if (lineIndex < 0 || lineIndex >= lines.length) return 0;
    return effectiveStartMs(lines[lineIndex]).clamp(0, 1 << 53).toInt();
  }

  int? lineIndexAt(int positionMs) {
    if (lines.isEmpty) return null;
    var low = 0;
    var high = lines.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      if (effectiveStartMs(lines[middle]) <= positionMs) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result < 0 ? null : result;
  }

  int playedWordCount(int lineIndex, int positionMs) {
    if (lineIndex < 0 || lineIndex >= lines.length) return 0;
    final line = lines[lineIndex];
    if (line.words.isEmpty) return 0;
    final relative = positionMs - effectiveStartMs(line);
    if (relative < 0) return 0;
    var low = 0;
    var high = line.words.length - 1;
    var result = -1;
    while (low <= high) {
      final middle = low + ((high - low) >> 1);
      if (line.words[middle].startMs <= relative) {
        result = middle;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return result + 1;
  }
}
