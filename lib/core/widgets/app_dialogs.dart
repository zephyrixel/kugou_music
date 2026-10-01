import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? content,
  String cancelLabel = '取消',
  String confirmLabel = '确认',
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: content == null ? null : Text(content),
      actions: [
        TextButton(
          onPressed: () => context.pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => context.pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return accepted == true;
}

/// Simple name + optional private switch dialog.
Future<({String name, bool private})?> promptPlaylistName(
  BuildContext context, {
  required String title,
  String confirmLabel = '确认',
  String? initialName,
  bool initialPrivate = false,
  bool showPrivate = true,
}) async {
  final name = TextEditingController(text: initialName ?? '');
  var private = initialPrivate;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '歌单名称'),
            ),
            if (showPrivate)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('设为私密'),
                value: private,
                onChanged: (value) => setState(() => private = value),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
  final value = name.text.trim();
  name.dispose();
  if (accepted != true || value.isEmpty) return null;
  return (name: value, private: private);
}

/// Edit dialog for name / intro / tags / private.
Future<({String name, String intro, String tags, bool private})?>
promptPlaylistEdit(
  BuildContext context, {
  required String name,
  required String intro,
  required String tags,
  required bool private,
}) async {
  final nameController = TextEditingController(text: name);
  final introController = TextEditingController(text: intro);
  final tagsController = TextEditingController(text: tags);
  var nextPrivate = private;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        title: const Text('编辑歌单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: '名称'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: introController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '简介'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(labelText: '标签（逗号分隔）'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('私密歌单'),
              value: nextPrivate,
              onChanged: (value) => setState(() => nextPrivate = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
  final nextName = nameController.text.trim();
  final nextIntro = introController.text.trim();
  final nextTags = tagsController.text.trim();
  nameController.dispose();
  introController.dispose();
  tagsController.dispose();
  if (accepted != true || nextName.isEmpty) return null;
  return (
    name: nextName,
    intro: nextIntro,
    tags: nextTags,
    private: nextPrivate,
  );
}
