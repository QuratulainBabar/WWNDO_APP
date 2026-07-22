import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_link.dart';

class BidSubmittedScreen extends StatelessWidget {
  const BidSubmittedScreen({
    super.key,
    required this.route,
    required this.price,
    this.tripId,
  });

  final String route;
  final double price;
  final String? tripId;

  void _goBack(BuildContext context) {
    if (tripId != null && tripId!.isNotEmpty) {
      context.go('/matching-requests/$tripId');
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/traveler-home');
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final fromMatchingFlow = tripId != null && tripId!.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackLink(onTap: () => _goBack(context)),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Request Accepted!',
                      style: typo.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You accepted the \$${price.toStringAsFixed(2)} offer on $route. '
                      'The sender can now see your acceptance.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: fromMatchingFlow
                          ? 'Back to requests'
                          : 'View my deliveries',
                      onPressed: () {
                        if (fromMatchingFlow) {
                          context.go('/matching-requests/$tripId');
                          return;
                        }
                        context.go('/traveler-deliveries');
                      },
                    ),
                    const SizedBox(height: AppButton.stackGap),
                    AppButton(
                      label: fromMatchingFlow
                          ? 'View my bids'
                          : 'Browse more requests',
                      variant: AppButtonVariant.outline,
                      onPressed: () {
                        if (fromMatchingFlow) {
                          context.go('/traveler-bids');
                          return;
                        }
                        context.go('/browse-requests');
                      },
                    ),
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
