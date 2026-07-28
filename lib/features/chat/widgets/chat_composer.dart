import 'package:flutter/material.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    required this.onAttach,
    this.borderRadius = 20,
    this.circularSendButton = true,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final double borderRadius;
  final bool circularSendButton;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? onAttach : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.attach_file_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: controller,
                onTap: ensureSoftKeyboardVisible,
                onTapOutside: dismissKeyboardOnTapOutside,
                enabled: enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? onSend() : null,
                style: typo.chatInput.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: typo.chatInput,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = enabled && value.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: canSend ? onSend : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: canSend ? 1 : 0.45,
                    child: circularSendButton
                        ? Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: canSend ? 1 : 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.send_rounded,
                              color: canSend ? Colors.white : AppColors.primary,
                              size: 20,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
