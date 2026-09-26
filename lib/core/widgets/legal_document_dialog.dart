import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../data/legal_documents.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

Future<void> showLegalDocumentDialog({
  required BuildContext context,
  required String title,
  required List<LegalSection> sections,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final typo = dialogContext.typo;
      final size = MediaQuery.sizeOf(dialogContext);
      final maxHeight = size.height * 0.78;
      final width = (size.width - 40).clamp(0.0, 520.0);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          height: maxHeight,
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: typo.h2.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated ${LegalDocuments.lastUpdated}',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final section in sections) ...[
                            Text(
                              section.heading,
                              style: typo.bodyBold.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (section.body != null)
                              Text(
                                section.body!,
                                style: typo.sm.copyWith(height: 1.55),
                              ),
                            if (section.bullets != null) ...[
                              if (section.body != null) const SizedBox(height: 6),
                              for (final bullet in section.bullets!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('•  ', style: typo.sm),
                                      Expanded(
                                        child: Text(
                                          bullet,
                                          style: typo.sm.copyWith(height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: context.tr('Close'),
                  small: true,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
