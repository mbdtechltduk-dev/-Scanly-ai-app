import 'package:flutter/material.dart';

import '../core/errors.dart';

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// Shows a friendly error. Raw exception text is never displayed.
Future<void> showAppError(BuildContext context, Object error, {AppErrorKind fallback = AppErrorKind.unknown}) async {
  final e = toAppException(error, fallback: fallback);
  if (e.kind == AppErrorKind.cancelled) return;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(color: _danger.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: const Icon(Icons.priority_high_rounded, color: _danger, size: 32),
      ),
      title: Text(e.title, textAlign: TextAlign.center),
      content: Text(e.message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ),
      ],
    ),
  );
}

const Color _danger = Color(0xFFE11D48);

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<String?> showTextInput(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String confirmLabel = 'Save',
  bool obscure = false,
  int? maxLength,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String value)? validator,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _TextInputDialog(
      title: title,
      initial: initial,
      hint: hint,
      confirmLabel: confirmLabel,
      obscure: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      validator: validator,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.confirmLabel,
    required this.obscure,
    required this.maxLength,
    required this.keyboardType,
    required this.validator,
  });

  final String title;
  final String initial;
  final String hint;
  final String confirmLabel;
  final bool obscure;
  final int? maxLength;
  final TextInputType keyboardType;
  final String? Function(String value)? validator;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    final err = widget.validator?.call(value) ?? (value.isEmpty ? 'Please enter a value' : null);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        obscureText: widget.obscure,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(hintText: widget.hint, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Modal progress dialog. Update [progress] (0..1, null = indeterminate) and [label].
class BusyDialog {
  BusyDialog._(this._navigator);

  final NavigatorState _navigator;
  final ValueNotifier<double?> progress = ValueNotifier<double?>(null);
  final ValueNotifier<String> label = ValueNotifier<String>('Working…');
  bool _closed = false;

  static BusyDialog show(BuildContext context, {String label = 'Working…'}) {
    final d = BusyDialog._(Navigator.of(context, rootNavigator: true));
    d.label.value = label;
    showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: d.progress,
                  builder: (_, v, _) => SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(child: CircularProgressIndicator(value: v, strokeWidth: 5, strokeCap: StrokeCap.round)),
                        v == null
                            ? Icon(Icons.picture_as_pdf_rounded, color: Theme.of(ctx).colorScheme.primary, size: 28)
                            : Text('${(v * 100).round()}%', style: Theme.of(ctx).textTheme.labelLarge),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<String>(
                  valueListenable: d.label,
                  builder: (_, v, _) => Semantics(
                    liveRegion: true,
                    child: Text(v, textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleMedium),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait while we process your document.',
                  textAlign: TextAlign.center,
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return d;
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _navigator.pop();
  }
}
