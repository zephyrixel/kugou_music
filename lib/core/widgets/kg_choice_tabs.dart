import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// Controlled tabs. A fractional position lets a pager drive the same indicator
/// directly during a gesture instead of starting another, lagging animation.
class KgChoiceTabs<T> extends StatelessWidget {
  const KgChoiceTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.pill = false,
    this.selectionPosition,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool pill;
  final double? selectionPosition;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    final entries = options.entries.toList(growable: false);
    final index = entries.indexWhere((entry) => entry.key == value);
    final position = (selectionPosition ?? index.toDouble()).clamp(
      0.0,
      entries.length - 1.0,
    );
    final alignment = AlignmentDirectional(
      entries.length == 1 ? 0 : -1 + 2 * position / (entries.length - 1),
      0,
    );
    final radius = BorderRadius.circular(pill ? KgRadii.pill : KgRadii.small);
    return IntrinsicWidth(
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedAlign(
                alignment: alignment,
                duration: selectionPosition == null
                    ? KgMotion.resolve(context, KgMotion.selection)
                    : Duration.zero,
                curve: KgMotion.emphasized,
                child: FractionallySizedBox(
                  widthFactor: 1 / entries.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pill ? KgColors.elevatedHigh : null,
                      gradient: pill ? KgGradients.warm : null,
                      borderRadius: pill ? radius : null,
                      border: pill
                          ? Border.all(color: KgColors.borderHighlight)
                          : const Border(
                              bottom: BorderSide(
                                color: KgColors.accent,
                                width: 2,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in entries)
                Expanded(
                  child: Semantics(
                    selected: entry.key == value,
                    button: true,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: radius,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        borderRadius: radius,
                        onTap: () {
                          if (entry.key != value) onChanged(entry.key);
                        },
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 48,
                            minWidth: 64,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          alignment: Alignment.center,
                          child: AnimatedDefaultTextStyle(
                            duration: KgMotion.resolve(context, KgMotion.fast),
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: entry.key == value
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: entry.key == value
                                      ? KgColors.textPrimary
                                      : KgColors.textMuted,
                                ),
                            child: Text(
                              entry.value,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
