import 'package:flutter/material.dart';

/// Read-only value styled like a text field — no keyboard, spell-check, or focus.
class AppValueField extends StatelessWidget {
  const AppValueField({
    super.key,
    required this.value,
    this.maxLines = 1,
    this.style,
  });

  final String value;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(),
      child: Text(
        value,
        style: style,
        maxLines: maxLines,
        overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
      ),
    );
  }
}
