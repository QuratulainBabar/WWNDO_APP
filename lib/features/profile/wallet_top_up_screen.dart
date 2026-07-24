import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/wallet_role.dart';
import '../../data/wallet_service.dart';
import '../../providers/wallet_provider.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountController = TextEditingController(text: '25.00');
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _parseAmountCents() {
    final dollars = double.tryParse(_amountController.text) ?? 0;
    return (dollars * 100).round();
  }

  Future<void> _pay(WalletRole role) async {
    final cents = _parseAmountCents();
    if (cents <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<WalletProvider>().topUp(
            role: role,
            amountCents: cents,
          );
      if (!mounted) return;
      context.pushReplacement(
        '/wallet/top-up/success?role=${role.queryParam}',
        extra: cents,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Top-up failed. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final role = WalletRole.fromQuery(
      GoRouterState.of(context).uri.queryParameters['role'],
    );
    final walletRoute = '/wallet?role=${role.queryParam}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: 'Top up wallet', fallbackRoute: walletRoute),
      body: ScreenBody(
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add funds securely with Stripe. Top-ups credit your available balance immediately.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            AppLabeledField(
              label: 'Amount (USD)',
              labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
              child: TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: typo.amountInput.copyWith(fontWeight: FontWeight.w700),
                onChanged: (_) => setState(() => _error = null),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: typo.sm.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Secured by Stripe · Card details are never stored by WWNGO',
                style: typo.sm,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _busy ? 'Processing…' : 'Pay with Stripe',
              onPressed: _busy ? null : () => _pay(role),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletTopUpSuccessScreen extends StatelessWidget {
  const WalletTopUpSuccessScreen({super.key, required this.amountCents});

  final int amountCents;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final role = WalletRole.fromQuery(
      GoRouterState.of(context).uri.queryParameters['role'],
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Icon(Icons.check, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text('Top-up successful', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '${WalletService.formatCents(amountCents)} added to your available balance via Stripe.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to wallet',
                onPressed: () => context.go('/wallet?role=${role.queryParam}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
