import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Small ⓘ button that opens a short explanation dialog.
class FieldInfoTag extends StatelessWidget {
  const FieldInfoTag({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  Future<void> _show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _show(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: AppColors.primary.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Compact inline tip under a field (optional secondary hint).
class FieldInfoHint extends StatelessWidget {
  const FieldInfoHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: typo.sm.copyWith(color: AppColors.primary, height: 1.35),
          ),
        ),
      ],
    );
  }
}
