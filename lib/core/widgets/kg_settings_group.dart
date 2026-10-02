import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';

class KgSettingsTile extends StatelessWidget {
  const KgSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.destructive = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? KgColors.disabled
        : destructive
        ? KgColors.error
        : null;
    return ListTile(
      enabled: enabled,
      minLeadingWidth: 24,
      horizontalTitleGap: KgSpacing.md,
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: color == null ? null : TextStyle(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: enabled ? KgColors.textMuted : KgColors.disabled,
              ),
            ),
      trailing:
          trailing ??
          (onTap == null
              ? null
              : Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: enabled ? KgColors.textMuted : KgColors.disabled,
                )),
      onTap: enabled ? onTap : null,
    );
  }
}

/// Shared visual container for compact settings made from [ListTile] rows.
class KgSettingsGroup extends StatelessWidget {
  const KgSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => KgSurface(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const Divider(height: 1, indent: 56, endIndent: 16),
          children[index],
        ],
      ],
    ),
  );
}
