import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';

class KgPageHeader extends StatelessWidget {
  const KgPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 14),
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(
                  subtitle!,
                  style: const TextStyle(color: KgColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    ),
  );
}

class KgSectionHeader extends StatelessWidget {
  const KgSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: const TextStyle(color: KgColors.textMuted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

class KgSurface extends StatelessWidget {
  const KgSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = KgColors.elevated,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
    ),
    child: Padding(padding: padding, child: child),
  );
}
