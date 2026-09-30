import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_language.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

/// Settings sub-screen: pick preferred app language.
class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key, this.fallbackRoute});

  final String? fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final localeProvider = context.watch<LocaleProvider>();
    final selected = localeProvider.language;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: l10n.language,
          fallbackRoute: fallbackRoute ?? '/settings',
        ),
        body: ScreenBody(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.preferredLanguage, style: typo.h3),
              const SizedBox(height: 8),
              Text(
                l10n.languageDescription,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < localeProvider.supported.length; i++) ...[
                      _LanguageTile(
                        language: localeProvider.supported[i],
                        selected: localeProvider.supported[i] == selected,
                        onTap: () async {
                          final next = localeProvider.supported[i];
                          // Pop first so awaiting parent pushes complete before
                          // MaterialApp rebuilds for the new locale.
                          if (context.mounted) context.pop();
                          await localeProvider.setLanguage(next);
                        },
                      ),
                      if (i < localeProvider.supported.length - 1)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                language.code.toUpperCase(),
                style: typo.sm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeName,
                    style: typo.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language.name,
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary)
            else
              Icon(
                Icons.circle_outlined,
                color: AppColors.textDisabled,
              ),
          ],
        ),
      ),
    );
  }
}
