import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
    this.length = 6,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;
  final int length;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final controller = widget.controller;
    final digits = controller.text.padRight(widget.length).split('');

    return Stack(
      children: [
        // Visual boxes only — taps must reach the TextField above.
        IgnorePointer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < widget.length; i++)
                _OtpBox(
                  digit: i < controller.text.length ? digits[i].trim() : '',
                  active: i == controller.text.length,
                  typo: typo,
                ),
            ],
          ),
        ),
        // Transparent input covering the boxes so the first tap focuses
        // and opens the keyboard (requestFocus alone is a no-op when already focused).
        Positioned.fill(
          child: TextField(
            controller: controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.number,
            maxLength: widget.length,
            autofocus: true,
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(color: Colors.transparent),
            cursorColor: Colors.transparent,
            decoration: const InputDecoration(
              // Override app OutlineInputBorder theme so no blue overlay shows.
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              isCollapsed: true,
            ),
            onChanged: widget.onChanged,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.digit,
    required this.active,
    required this.typo,
  });

  final String digit;
  final bool active;
  final AppTypography typo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
          width: active ? 2 : 1.5,
        ),
      ),
      child: Text(
        digit,
        style: typo.h2.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
