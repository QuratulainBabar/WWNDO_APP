import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';

import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/payments/stripe_connect_return.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/currency_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletTopUpScreen extends StatefulWidget {
  const WalletTopUpScreen({super.key});

  @override
  State<WalletTopUpScreen> createState() => _WalletTopUpScreenState();
}

class _WalletTopUpScreenState extends State<WalletTopUpScreen> {
  final _amountController = TextEditingController();
  String? _error;
  bool _busy = false;
  String? _fxPreview;
  int? _lastPreviewMinor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CurrencyProvider>().refreshFxRate();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _updateFxPreview() async {
    final currency = context.read<CurrencyProvider>();
    final minor = currency.parseMajorToMinor(_amountController.text);
    if (minor <= 0) {
      if (mounted) setState(() => _fxPreview = null);
      return;
    }
    if (currency.code == 'USD') {
      if (mounted) {
        setState(() {
          _fxPreview = 'Wallet will be credited \$${(minor / 100).toStringAsFixed(2)} USD';
        });
      }
      return;
    }
    if (_lastPreviewMinor == minor && _fxPreview != null) return;
    _lastPreviewMinor = minor;
    try {
      final quote = await currency.convert(
        fromCurrency: currency.code,
        toCurrency: 'USD',
        amountCents: minor,
      );
      if (!mounted) return;
      setState(() {
        _fxPreview =
            '≈ \$${(quote.convertedAmountCents / 100).toStringAsFixed(2)} USD charged & credited (Stripe FX)';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _fxPreview = 'FX preview unavailable: ${e.message}');
    } catch (_) {
      if (mounted) setState(() => _fxPreview = null);
    }
  }

  Future<void> _pay(WalletRole role) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final currency = context.read<CurrencyProvider>();
    final wallet = context.read<WalletProvider>();
    final cents = currency.parseMajorToMinor(_amountController.text);
    if (cents <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Backend converts display currency → USD via FX, then opens Stripe in USD.
      await wallet.topUp(
        role: role,
        amountCents: cents,
        currency: currency.code,
      );
      if (!mounted) return;
      context.pushReplacement(
        '/wallet/top-up/success?role=${role.queryParam}',
        extra: cents,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
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
    final currency = context.watch<CurrencyProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: context.tr('Top up wallet'), fallbackRoute: walletRoute),
      body: ScreenBody(
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter an amount in ${currency.code}. Stripe charges the USD equivalent (live FX) and credits your wallet in USD. Your balance is shown in ${currency.code}.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            if (currency.fxError != null) ...[
              const SizedBox(height: 8),
              Text(
                currency.fxError!,
                style: typo.sm.copyWith(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 20),
            AppLabeledField(
              label: currency.fieldLabel('Amount'),
              labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
              child: TextField(
                controller: _amountController,
                onTap: ensureSoftKeyboardVisible,
                onTapOutside: dismissKeyboardOnTapOutside,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: typo.amountInput.copyWith(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: typo.amountInput.copyWith(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  prefixText: currency.symbol,
                ),
                onChanged: (_) {
                  setState(() => _error = null);
                  _updateFxPreview();
                },
              ),
            ),
            if (_fxPreview != null) ...[
              const SizedBox(height: 8),
              Text(
                _fxPreview!,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            ],
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
                'Secured by Stripe · Live FX Quotes · Card details are never stored by WWNGO',
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
    final currency = context.watch<CurrencyProvider>().currency;

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
                '${currency.formatCents(amountCents)} topped up. Your wallet was credited the USD equivalent via Stripe FX.',
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

class WalletConnectSuccessScreen extends StatelessWidget {
  const WalletConnectSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final params = GoRouterState.of(context).uri.queryParameters;
    final role = WalletRole.fromQuery(
      params['role'] ?? StripeConnectReturn.role,
    );
    final isRefresh = params['status'] == 'refresh';
    final walletRoute = '/wallet?role=${role.queryParam}';
    final homeRoute = switch (role) {
      WalletRole.receiver => '/receiver-home',
      WalletRole.traveler => '/traveler-home',
      WalletRole.sender => '/home',
    };

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
                child: Icon(
                  isRefresh
                      ? Icons.account_balance_outlined
                      : Icons.check,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isRefresh
                    ? 'Continue payout setup'
                    : 'Payout account connected',
                style: typo.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isRefresh
                    ? 'Return to the wallet to finish linking your Stripe payout account.'
                    : 'Your Stripe payout account is linked. You can withdraw to your bank from the wallet.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to wallet',
                onPressed: () => context.go(walletRoute),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Go to home',
                variant: AppButtonVariant.outline,
                textStyle: typo.button.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.go(homeRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
