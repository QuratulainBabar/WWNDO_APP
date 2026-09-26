import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/api_config.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/external_links.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/legal_documents.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Legal & policies'),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review the policies that govern your use of WWNGO.',
              style: typo.subheading.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _LegalTile(
              title: 'Privacy Policy',
              subtitle: 'How we collect, use, and protect your data',
              onTap: () => context.push('/legal/privacy'),
            ),
            _LegalTile(
              title: 'Terms of Service',
              subtitle: 'Rules for using the marketplace',
              onTap: () => context.push('/legal/terms'),
            ),
            _LegalTile(
              title: 'Cookie Policy',
              subtitle: 'How cookies are used on our website',
              onTap: () => context.push('/legal/cookies'),
            ),
            const SizedBox(height: 8),
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full documents online', style: typo.h3),
                  const SizedBox(height: 8),
                  Text(
                    'The latest legal text is always available on our website.',
                    style: typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Open website',
                    variant: AppButtonVariant.outline,
                    small: true,
                    onPressed: () => ExternalLinks.openWebsitePath('/legal/privacy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.typo.bodyBold),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
    required this.websitePath,
  });

  final String title;
  final List<LegalSection> sections;
  final String websitePath;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: title),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last updated ${LegalDocuments.lastUpdated}',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < sections.length; i++) ...[
              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${i + 1}'.padLeft(2, '0'),
                        style: typo.sm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sections[i].heading, style: typo.h3),
                          if (sections[i].body != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              sections[i].body!,
                              style: typo.sm.copyWith(height: 1.6),
                            ),
                          ],
                          if (sections[i].bullets != null) ...[
                            const SizedBox(height: 8),
                            for (final bullet in sections[i].bullets!)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('•  '),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            AppButton(
              label: 'Read full $title online',
              variant: AppButtonVariant.outline,
              onPressed: () => ExternalLinks.openWebsitePath(websitePath),
            ),
            const SizedBox(height: 8),
            Text(
              ApiConfig.legalUrl(websitePath),
              style: typo.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: LegalDocuments.privacyTitle,
      websitePath: '/legal/privacy',
      sections: LegalDocuments.privacySections,
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: LegalDocuments.termsTitle,
      websitePath: '/legal/terms',
      sections: LegalDocuments.termsSections,
    );
  }
}

class CookiePolicyScreen extends StatelessWidget {
  const CookiePolicyScreen({super.key});

  static const _sections = [
    LegalSection(
      heading: 'What are cookies?',
      body:
          'Cookies are small text files stored on your device. They help remember preferences and understand how you use our site.',
    ),
    LegalSection(
      heading: 'Cookies we use',
      bullets: [
        'Essential — required for security and sessions',
        'Analytics — help us improve performance (optional)',
        'Preferences — remember your settings (optional)',
      ],
    ),
    LegalSection(
      heading: 'Managing cookies',
      body:
          'You can control cookies in your browser settings. Disabling essential cookies may affect site functionality.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      title: 'Cookie Policy',
      websitePath: '/legal/cookies',
      sections: _sections,
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Help & support'),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get answers or reach our team.',
              style: typo.subheading.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _HelpTile(
              icon: Icons.quiz_outlined,
              title: 'FAQ',
              subtitle: 'Common questions about WWNGO',
              onTap: () => ExternalLinks.openFaq(),
            ),
            _HelpTile(
              icon: Icons.shield_outlined,
              title: 'Safety & trust',
              subtitle: 'KYC, escrow, NFC, and dispute resolution',
              onTap: () => ExternalLinks.openSafety(),
            ),
            _HelpTile(
              icon: Icons.info_outline,
              title: 'About WWNGO',
              subtitle: 'Our mission and how the marketplace works',
              onTap: () => ExternalLinks.openAbout(),
            ),
            _HelpTile(
              icon: Icons.mail_outline,
              title: 'Contact support',
              subtitle: 'support@wwngo.com',
              onTap: () => context.push('/contact-support'),
            ),
            _HelpTile(
              icon: Icons.language,
              title: 'Visit website',
              subtitle: ApiConfig.websiteUrl,
              onTap: () => ExternalLinks.openWebsitePath('/'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        margin: EdgeInsets.zero,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.typo.bodyBold),
                  Text(
                    subtitle,
                    style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
