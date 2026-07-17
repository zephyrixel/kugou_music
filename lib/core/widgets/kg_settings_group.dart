import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_layout.dart';

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
          if (index > 0) const Divider(height: 1, indent: 56),
          children[index],
        ],
      ],
    ),
  );
}
