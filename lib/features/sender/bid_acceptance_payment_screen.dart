import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/payments/stripe_payments.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/bid.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/wallet_role.dart';
import '../../data/platform_fees.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/services/trip_repository.dart';
import '../../data/services/wallet_repository.dart';
import '../../data/wallet_gate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

enum _BidPaymentMethod { wallet, stripe }

class BidAcceptanceContext {
  const BidAcceptanceContext({
    required this.bid,
    required this.shipmentId,
    this.offerId,
    this.parcelCategory = 'documents',
    this.paysReceiverFee = false,
  });

  final Bid bid;
  final String shipmentId;
  final String? offerId;
  final String parcelCategory;
  final bool paysReceiverFee;
}

class BidAcceptancePaymentScreen extends StatefulWidget {
  const BidAcceptancePaymentScreen({super.key, required this.acceptance});

  final BidAcceptanceContext acceptance;

  @override
  State<BidAcceptancePaymentScreen> createState() =>
      _BidAcceptancePaymentScreenState();
}

class _BidAcceptancePaymentScreenState extends State<BidAcceptancePaymentScreen> {
  bool _paying = false;
  bool _loading = true;
  bool _walletLoading = true;
  bool _stripeEnabled = false;
  CreatedDelivery? _delivery;
  String? _error;
  _BidPaymentMethod? _paymentMethod;
  int _walletAvailableCents = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDelivery();
      _loadWalletAndPayments();
    });
  }

  Future<void> _loadWalletAndPayments() async {
    if (context.read<DemoModeProvider>().enabled) {
      if (mounted) setState(() => _walletLoading = false);
      return;
    }
    try {
      final auth = context.read<AuthProvider>();
      final walletRepo = WalletRepository(
        apiClient: auth.repository.apiClient,
        demoMode: context.read<DemoModeProvider>(),
      );
      await StripePayments.ensureConfigured(walletRepo);
      final stripeEnabled = StripePayments.isEnabled;
      int availableCents = 0;
      try {
        final summary = await context.read<WalletProvider>().refresh(
              WalletRole.sender,
              silent: true,
            );
        availableCents = summary.availableCents;
      } catch (_) {
        availableCents = context.read<WalletProvider>().availableCents(
              WalletRole.sender,
            );
      }
      if (!mounted) return;
      setState(() {
        _walletAvailableCents = availableCents;
        _stripeEnabled = stripeEnabled;
        _walletLoading = false;
      });
      _applyDefaultPaymentMethod();
    } catch (_) {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  int _totalDueCents({
    required String category,
    required bool paysReceiver,
    required double bidAmount,
  }) {
    final platformFee = PlatformFees.senderPlatformFeeUsd(
      category: category,
      paysReceiverFee: paysReceiver,
    );
    return ((bidAmount + platformFee) * 100).round();
  }

  void _applyDefaultPaymentMethod() {
    if (_paymentMethod != null) return;
    final acceptance = widget.acceptance;
    final delivery = _delivery;
    final category = delivery?.parcelCategory ?? acceptance.parcelCategory;
    final paysReceiver = delivery != null
        ? PlatformFees.senderPaysReceiverFee(delivery)
        : acceptance.paysReceiverFee;
    final totalCents = _totalDueCents(
      category: category,
      paysReceiver: paysReceiver,
      bidAmount: acceptance.bid.price,
    );
    final canPayFromWallet = _walletAvailableCents >= totalCents;
    setState(() {
      _paymentMethod = canPayFromWallet || !_stripeEnabled
          ? _BidPaymentMethod.wallet
          : _BidPaymentMethod.stripe;
    });
  }

  DeliveryRepository _deliveryRepo() {
    final auth = context.read<AuthProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: context.read<DemoModeProvider>(),
    );
  }

  TripRepository _tripRepo() {
    final auth = context.read<AuthProvider>();
    final demo = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demo,
    );
  }

  Future<void> _loadDelivery() async {
    if (context.read<DemoModeProvider>().enabled) {
      setState(() {
        _loading = false;
        _error = 'Turn off Demo mode to complete live escrow payment.';
      });
      return;
    }
    try {
      final delivery = await _deliveryRepo().getDelivery(
        widget.acceptance.shipmentId,
        role: 'sender',
      );
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _loading = false;
      });
      _applyDefaultPaymentMethod();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load delivery details.';
      });
    }
  }

  Future<String?> _resolveOfferId() async {
    final acceptance = widget.acceptance;
    final existing = (acceptance.offerId ?? '').trim();
    if (existing.isNotEmpty) return existing;

    // Fallback: bid.id may already be the counter-offer UUID (from offer detail).
    final bidId = acceptance.bid.id.trim();
    if (bidId.isNotEmpty &&
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(bidId)) {
      return bidId;
    }

    final shipmentId = acceptance.shipmentId.trim();
    if (shipmentId.isEmpty) return null;

    try {
      final offer = await _tripRepo().getSenderCounterOfferByDelivery(shipmentId);
      return offer.id.trim().isEmpty ? null : offer.id.trim();
    } catch (_) {
      return null;
    }
  }

  Future<void> _payNow() async {
    if (_paying || _paymentMethod == null) return;
    final acceptance = widget.acceptance;
    final paymentMethod = _paymentMethod!;

    setState(() => _paying = true);
    try {
      final offerId = await _resolveOfferId();
      if (offerId == null || offerId.isEmpty) {
        if (!mounted) return;
        AppToast.error(
          context,
          'Counter offer is not ready yet. Wait for the traveler’s offer, then pay from Counter Offer Details.',
        );
        return;
      }

      final auth = context.read<AuthProvider>();
      final walletRepo = WalletRepository(
        apiClient: auth.repository.apiClient,
        demoMode: context.read<DemoModeProvider>(),
      );
      if (paymentMethod == _BidPaymentMethod.stripe) {
        await StripePayments.ensureConfigured(walletRepo);
        if (!StripePayments.isEnabled) {
          AppToast.error(
            context,
            'Card payments are not available. Pay from wallet or top up first.',
          );
          return;
        }
      }

      final methodParam =
          paymentMethod == _BidPaymentMethod.wallet ? 'wallet' : 'stripe';

      String? paymentIntentId;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await _tripRepo().acceptSenderCounterOffer(
            offerId,
            paymentIntentId: paymentIntentId,
            paymentMethod: methodParam,
          );
          paymentIntentId = null;
          break;
        } on ApiException catch (e) {
          if (paymentMethod == _BidPaymentMethod.wallet) {
            if (e.code == 'INSUFFICIENT_WALLET' || e.requiresPayment) {
              throw ApiException(
                message:
                    'Insufficient wallet balance. Choose Pay with card or top up your wallet.',
                code: e.code,
                statusCode: e.statusCode,
              );
            }
            rethrow;
          }
          if (!e.requiresPayment || e.clientSecret == null) rethrow;
          await StripePayments.presentPaymentSheet(clientSecret: e.clientSecret!);
          paymentIntentId = e.paymentIntentId;
          if (paymentIntentId == null || paymentIntentId.isEmpty) {
            throw const ApiException(
              message: 'Card payment succeeded but payment id is missing.',
              code: 'PAYMENT_INCOMPLETE',
            );
          }
          await walletRepo.confirmTopUp(
            paymentIntentId: paymentIntentId,
            role: WalletRole.sender,
          );
        }
      }

      if (!mounted) return;
      await WalletGate.refreshRoles(
        context,
        [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      );

      if (!mounted) return;
      context.push(
        '/bid-payment-success',
        extra: BidAcceptanceContext(
          bid: acceptance.bid,
          shipmentId: acceptance.shipmentId,
          offerId: offerId,
          parcelCategory: acceptance.parcelCategory,
          paysReceiverFee: acceptance.paysReceiverFee,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      final detail = e.toString().trim();
      AppToast.error(
        context,
        detail.isEmpty
            ? 'Payment failed. Booking was not created. Check wallet or card and try again.'
            : 'Payment failed. Booking was not created. $detail',
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Payment Summary'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Payment Summary'),
        body: Center(
          child: Padding(
            padding: context.pagePadding,
            child: Text(_error!, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final acceptance = widget.acceptance;
    final bid = acceptance.bid;
    final delivery = _delivery;
    final category = delivery?.parcelCategory ?? acceptance.parcelCategory;
    final paysReceiver = delivery != null
        ? PlatformFees.senderPaysReceiverFee(delivery)
        : acceptance.paysReceiverFee;
    final platformFee = PlatformFees.senderPlatformFeeUsd(
      category: category,
      paysReceiverFee: paysReceiver,
    );
    final total = bid.price + platformFee;
    final totalCents = (total * 100).round();
    final walletUsd = _walletAvailableCents / 100;
    final walletCoversTotal = _walletAvailableCents >= totalCents;
    final selectedMethod = _paymentMethod;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Payment Summary'),
      body: SingleChildScrollView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _detailRow(context, 'Accepted traveler', bid.travelerName),
                  _detailRow(context, 'Parcel ID', acceptance.shipmentId),
                  _detailRow(
                    context,
                    'Accepted bid amount',
                    '\$${bid.price.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _detailRow(
                    context,
                    'Your platform fee',
                    '\$${platformFee.toStringAsFixed(2)}',
                  ),
                  if (paysReceiver)
                    _detailRow(
                      context,
                      'Includes receiver fee',
                      'Yes',
                    ),
                  const Divider(height: 24),
                  _detailRow(
                    context,
                    'Total due now',
                    '\$${total.toStringAsFixed(2)}',
                    primary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Payment method',
              style: context.typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_walletLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _PaymentMethodTile(
                title: 'Pay from wallet',
                subtitle: walletCoversTotal
                    ? 'Available balance: \$${walletUsd.toStringAsFixed(2)}'
                    : 'Available \$${walletUsd.toStringAsFixed(2)} — need \$${total.toStringAsFixed(2)}',
                selected: selectedMethod == _BidPaymentMethod.wallet,
                enabled: !_paying,
                onTap: () => setState(
                  () => _paymentMethod = _BidPaymentMethod.wallet,
                ),
              ),
              const SizedBox(height: 8),
              _PaymentMethodTile(
                title: 'Pay with card (Stripe)',
                subtitle: walletCoversTotal
                    ? 'Charge your card instead of wallet'
                    : 'Pay \$${(total - walletUsd).clamp(0, total).toStringAsFixed(2)} shortfall by card',
                selected: selectedMethod == _BidPaymentMethod.stripe,
                enabled: !_paying && _stripeEnabled,
                onTap: _stripeEnabled
                    ? () => setState(
                          () => _paymentMethod = _BidPaymentMethod.stripe,
                        )
                    : null,
              ),
              if (!_stripeEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Card payments are not configured. Use wallet balance.',
                    style: context.typo.sm.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AppBadge.success('✓ Escrow protected'),
                AppBadge.success('✓ Secure payment'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              selectedMethod == _BidPaymentMethod.wallet
                  ? 'The total is deducted from your sender wallet. Booking is not created if balance is insufficient.'
                  : 'If wallet balance is short, Stripe collects the difference on your card, then escrow is funded from wallet. '
                      'Sender, traveler, and receiver platform fees are collected instantly.',
              style: context.typo.sm.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _paying ? 'Processing…' : 'Pay Now',
              onPressed: _paying || selectedMethod == null ? null : _payNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool primary = false,
  }) {
    final typo = context.typo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: typo.sm),
          Text(
            value,
            style: primary
                ? typo.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  )
                : typo.bodyBold.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final borderColor = selected ? AppColors.primary : AppColors.border;
    final background = selected
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.surface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: enabled
                    ? (selected ? AppColors.primary : AppColors.textSecondary)
                    : AppColors.border,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: typo.bodyBold.copyWith(
                        fontWeight: FontWeight.w700,
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
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
