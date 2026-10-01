import 'package:flutter/material.dart';
import 'package:kgmusic/core/design_system/kg_theme.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

class KgPageHeader extends StatelessWidget {
  const KgPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 14),
  }) : assert(subtitle == null || subtitleWidget == null);

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
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
              if (subtitle != null || subtitleWidget != null) ...[
                const SizedBox(height: 5),
                subtitleWidget ??
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
    this.color = KgColors.surface,
    this.radius = KgRadii.large,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Material(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: Padding(padding: padding, child: child),
  );
}

class KgContentWidth extends StatelessWidget {
  const KgContentWidth({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? KgBreakpoints.contentMaxWidth,
      ),
      child: child,
    ),
  );
}
