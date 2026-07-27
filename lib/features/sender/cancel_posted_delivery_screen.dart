import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/cancel_request_confirmation_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class CancelPostedDeliveryScreen extends StatefulWidget {
  const CancelPostedDeliveryScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<CancelPostedDeliveryScreen> createState() =>
      _CancelPostedDeliveryScreenState();
}

class _CancelPostedDeliveryScreenState extends State<CancelPostedDeliveryScreen> {
  CreatedDelivery? _delivery;
  bool _loading = true;
  String? _loadError;
  bool _cancelling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final delivery = await _repository().getDelivery(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Unable to load this delivery. Please try again.';
      });
    }
  }

  Future<void> _confirmCancel() async {
    final delivery = _delivery;
    if (delivery == null) return;

    final travelDate = delivery.travelDateParsed;
    if (travelDate == null ||
        !StaticData.canSenderCancelBeforeTravel(travelDate)) {
      AppToast.error(context, StaticData.senderCancelBlockedMessage);
      return;
    }

    final confirmed = await showCancelRequestConfirmation(context);
    if (!confirmed || !context.mounted) return;

    setState(() => _cancelling = true);

    try {
      await _repository().cancelDelivery(delivery.displayId);
      if (!context.mounted) return;

      AppToast.success(context, '${delivery.displayId} cancelled');
      context.go('/my-posted-parcels');
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, 'Unable to cancel this delivery. Please try again.');
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: 'Cancel delivery',
          fallbackRoute: '/my-posted-parcels',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null || _delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: 'Cancel delivery',
          fallbackRoute: '/my-posted-parcels',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? 'Delivery not found.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final delivery = _delivery!;
    final travelDate = delivery.travelDateParsed ?? DateTime.now();
    final canCancel = StaticData.canSenderCancelBeforeTravel(travelDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Cancel ${delivery.displayId}',
        fallbackRoute: '/my-posted-parcels',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: _cancelling ? 'Cancelling…' : 'Cancel delivery',
            variant: AppButtonVariant.danger,
            onPressed: _cancelling ? null : _confirmCancel,
          ),
          AppButton(
            label: 'Keep delivery',
            variant: AppButtonVariant.ghost,
            onPressed: _cancelling ? null : () => context.pop(),
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this delivery?',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'This will remove your parcel request. Matching travelers will no longer see this delivery.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canCancel
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                canCancel
                    ? 'You can cancel this request because it is still more than '
                        '${StaticData.senderCancelMinHoursBeforeTravel} hours before the flight.'
                    : StaticData.senderCancelBlockedMessage,
                style: typo.sm.copyWith(
                  height: 1.45,
                  color: canCancel ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.route,
                      style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM d, yyyy').format(travelDate),
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${delivery.parcelCategory} · ${delivery.weightKg} kg',
                      style: typo.sm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
