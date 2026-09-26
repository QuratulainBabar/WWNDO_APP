import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';

// TEMPORARILY DISABLED - SUMSUB KYC
// All KYC routes resolve to this local-only placeholder. It performs no SDK
// initialization, backend request, status synchronization, or navigation into
// the preserved KYC capture flow.
class KycDisabledScreen extends StatelessWidget {
  const KycDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(context.tr('Identity verification'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_outline,
                size: 72,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Identity verification is temporarily unavailable',
                textAlign: TextAlign.center,
                style: context.typo.h2,
              ),
              const SizedBox(height: 10),
              Text(
                'You can continue using the app. Verification will return in a future update.',
                textAlign: TextAlign.center,
                style: context.typo.body,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: context.tr('Continue'),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/role-selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
