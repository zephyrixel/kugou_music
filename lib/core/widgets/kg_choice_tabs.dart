import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

/// Small, controlled tab strip shared by search and the player visual pages.
class KgChoiceTabs<T> extends StatelessWidget {
  const KgChoiceTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.pill = false,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool pill;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final entry in options.entries)
        Flexible(
          child: Semantics(
            selected: entry.key == value,
            button: true,
            child: Material(
              color: pill && entry.key == value
                  ? KgColors.elevatedHigh
                  : Colors.transparent,
              animationDuration: KgMotion.resolve(context, KgMotion.fast),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  pill ? KgRadii.pill : KgRadii.small,
                ),
                side: BorderSide(
                  color: pill && entry.key == value
                      ? KgColors.borderHighlight
                      : Colors.transparent,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  pill ? KgRadii.pill : KgRadii.small,
                ),
                onTap: () {
                  if (entry.key != value) onChanged(entry.key);
                },
                child: Ink(
                  // Decoration is painted on the same Material as the ink,
                  // so selection never hides pressed or keyboard focus states.
                  decoration: pill
                      ? null
                      : BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: entry.key == value
                                  ? KgColors.accent
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 64,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: entry.key == value
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: entry.key == value
                            ? KgColors.textPrimary
                            : KgColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
