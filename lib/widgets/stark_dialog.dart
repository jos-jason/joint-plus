import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'stark_button.dart';

/// Black, square, hairline-bordered dialog frame.
class StarkDialog extends StatelessWidget {
  const StarkDialog({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: JColors.black,
      insetPadding: const EdgeInsets.all(JSpace.gutter),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: JColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(JSpace.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

/// Asks a yes/no question. [confirm] is the green action unless
/// [destructive], in which case [cancel] is the green one (the safe choice).
Future<bool> showStarkConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  required String cancel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) {
      final yes = destructive
          ? StarkButton.secondary(
              label: confirm,
              onPressed: () => Navigator.of(context).pop(true),
            )
          : StarkButton(
              label: confirm,
              onPressed: () => Navigator.of(context).pop(true),
            );
      final no = destructive
          ? StarkButton(
              label: cancel,
              onPressed: () => Navigator.of(context).pop(false),
            )
          : StarkButton.secondary(
              label: cancel,
              onPressed: () => Navigator.of(context).pop(false),
            );
      return StarkDialog(
        children: [
          Text(title, style: JType.heading),
          const SizedBox(height: JSpace.sm),
          Text(body, style: JType.secondary),
          const SizedBox(height: JSpace.lg),
          if (destructive) ...[
            no,
            const SizedBox(height: JSpace.sm),
            yes,
          ] else ...[
            yes,
            const SizedBox(height: JSpace.sm),
            no,
          ],
        ],
      );
    },
  );
  return result ?? false;
}

/// Asks for a whole number, e.g. seconds held. Null when cancelled.
Future<int?> showNumberInput(
  BuildContext context, {
  required String title,
  required String body,
  String? unit,
}) => showDialog<int>(
  context: context,
  barrierColor: Colors.black87,
  builder: (_) => _NumberDialog(title: title, body: body, unit: unit),
);

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({required this.title, required this.body, this.unit});

  final String title;
  final String body;
  final String? unit;

  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _value => int.tryParse(_controller.text);

  @override
  Widget build(BuildContext context) {
    return StarkDialog(
      children: [
        Text(widget.title, style: JType.heading),
        const SizedBox(height: JSpace.sm),
        Text(widget.body, style: JType.secondary),
        const SizedBox(height: JSpace.lg),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          style: JType.display.copyWith(fontSize: 48),
          cursorColor: JColors.green,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            suffixText: widget.unit,
            suffixStyle: JType.heading.copyWith(color: JColors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: JColors.line),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: JColors.green),
            ),
          ),
        ),
        const SizedBox(height: JSpace.lg),
        StarkButton(
          label: 'Save',
          onPressed: _value == null
              ? null
              : () => Navigator.of(context).pop(_value),
        ),
        const SizedBox(height: JSpace.sm),
        StarkButton.secondary(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
