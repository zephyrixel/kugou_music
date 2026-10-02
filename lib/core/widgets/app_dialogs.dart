import 'package:flutter/material.dart';
import 'package:kgmusic/core/widgets/kg_overlays.dart';
import 'package:kgmusic/core/design_system/kg_tokens.dart';

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? content,
  String cancelLabel = '取消',
  String confirmLabel = '确认',
  bool destructive = false,
}) async {
  final accepted = await showKgDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(title),
      content: content == null ? null : Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(context, true),
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
  final result = await showKgDialog<_PlaylistDraft>(
    context: context,
    builder: (_) => _PlaylistFormDialog(
      title: title,
      confirmLabel: confirmLabel,
      name: initialName ?? '',
      private: initialPrivate,
      showPrivate: showPrivate,
    ),
  );
  return result == null ? null : (name: result.name, private: result.private);
}

/// Edit dialog for name / intro / tags / private.
Future<({String name, String intro, String tags, bool private})?>
promptPlaylistEdit(
  BuildContext context, {
  required String name,
  required String intro,
  required String tags,
  required bool private,
}) => showKgDialog<_PlaylistDraft>(
  context: context,
  builder: (_) => _PlaylistFormDialog(
    title: '编辑歌单',
    confirmLabel: '保存',
    name: name,
    intro: intro,
    tags: tags,
    private: private,
    editing: true,
  ),
);

typedef _PlaylistDraft = ({
  String name,
  String intro,
  String tags,
  bool private,
});

/// Controllers live for the complete route lifetime, including its exit
/// animation. Invalid input stays in the form instead of silently cancelling.
class _PlaylistFormDialog extends StatefulWidget {
  const _PlaylistFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.name,
    required this.private,
    this.intro = '',
    this.tags = '',
    this.editing = false,
    this.showPrivate = true,
  });

  final String title;
  final String confirmLabel;
  final String name;
  final String intro;
  final String tags;
  final bool private;
  final bool editing;
  final bool showPrivate;

  @override
  State<_PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<_PlaylistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _intro = TextEditingController(text: widget.intro);
  late final _tags = TextEditingController(text: widget.tags);
  late bool _private = widget.private;

  @override
  void dispose() {
    _name.dispose();
    _intro.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop<_PlaylistDraft>(context, (
      name: _name.text.trim(),
      intro: _intro.text.trim(),
      tags: _tags.text.trim(),
      private: _private,
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            autofocus: !widget.editing,
            textInputAction: widget.editing
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: widget.editing ? null : (_) => _submit(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) =>
                value == null || value.trim().isEmpty ? '请输入歌单名称' : null,
            decoration: const InputDecoration(labelText: '歌单名称'),
          ),
          if (widget.editing) ...[
            const SizedBox(height: KgSpacing.md),
            TextFormField(
              controller: _intro,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '简介'),
            ),
            const SizedBox(height: KgSpacing.md),
            TextFormField(
              controller: _tags,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '用逗号分隔',
              ),
            ),
          ],
          if (widget.showPrivate) ...[
            const SizedBox(height: KgSpacing.xs),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('设为私密'),
              value: _private,
              onChanged: (value) => setState(() => _private = value),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}
