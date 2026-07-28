import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/screen_body.dart';
import '../../core/widgets/wallet_card.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/receiver_delivery_status.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';

class ReceiverHomeScreen extends StatefulWidget {
  const ReceiverHomeScreen({super.key});

  @override
  State<ReceiverHomeScreen> createState() => _ReceiverHomeScreenState();
}

class _ReceiverHomeScreenState extends State<ReceiverHomeScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  String? _error;
  CreatedDelivery? _active;
  String? _lastMatchedLocation;
  VoidCallback? _realtimeListener;
  NotificationRealtimeProvider? _realtimeProvider;
  int _lastDeliveryUpdateTick = 0;
  Timer? _fallbackPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthProvider>().refreshUser();
      _attachRealtimeListener();
      _load(silent: false);
    });
    _fallbackPollTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted) return;
      if (!(_realtimeProvider?.isConnected ?? false)) {
        _load(silent: _active != null);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/receiver-home' && _lastMatchedLocation != '/receiver-home') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(silent: _active != null);
      });
    }
    _lastMatchedLocation = location;
  }

  @override
  void dispose() {
    _fallbackPollTimer?.cancel();
    if (_realtimeListener != null) {
      _realtimeProvider?.removeListener(_realtimeListener!);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _attachRealtimeListener() {
    final realtime = context.read<NotificationRealtimeProvider>();
    _realtimeProvider = realtime;
    _lastDeliveryUpdateTick = realtime.deliveryUpdateTick;

    _realtimeListener ??= () {
      if (!mounted) return;
      final tick = realtime.deliveryUpdateTick;
      if (tick != _lastDeliveryUpdateTick) {
        _lastDeliveryUpdateTick = tick;
        _load(silent: _active != null);
      }
    };
    realtime.addListener(_realtimeListener!);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  DeliveryRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final list = await _repo().listDeliveries(role: 'receiver');
      if (!mounted) return;

      // Prefer action-needed New Request, then other active, then latest Rejected.
      CreatedDelivery? active;
      for (final d in list) {
        if (ReceiverDeliveryStatus.fromDelivery(d).isPendingRequest) {
          active = d;
          break;
        }
      }
      if (active == null) {
        for (final d in list) {
          final status = ReceiverDeliveryStatus.fromDelivery(d);
          if (!status.isPast) {
            active = d;
            break;
          }
        }
      }
      if (active == null) {
        for (final d in list) {
          if (ReceiverDeliveryStatus.fromDelivery(d).label == 'Rejected') {
            active = d;
            break;
          }
        }
      }

      setState(() {
        _active = active;
        _loading = false;
        _error = null;
      });
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
        _error = 'Unable to load incoming parcels.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final authUser = context.watch<AuthProvider>().user;
    final firstName = authUser?.firstName ?? 'there';
    final shipment = _active;
    final status = shipment == null
        ? null
        : ReceiverDeliveryStatus.fromDelivery(shipment);
    final isDelivered = status?.label == 'Delivered';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BackLink(onTap: () => context.go('/role-selection')),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, $firstName 👋',
                        style: typo.h1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Receiver · Track incoming parcels', style: typo.sm),
                    ],
                  ),
                ),
                const WalletCard(role: WalletRole.receiver),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              isDelivered ? 'Latest parcel' : 'Incoming parcel',
              style: typo.h3.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _parcelSection(context, typo, shipment, status),
            const SizedBox(height: 24),
            Text('Quick actions', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Row(
              children: [
                _action(
                  context,
                  AppIcons.track,
                  'Track parcel',
                  () => context.go('/receiver-shipments'),
                ),
                const SizedBox(width: 10),
                _action(
                  context,
                  AppIcons.chat,
                  'Chat traveler',
                  () => context.go('/receiver-chats'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('What to expect', style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tip(context, '1', 'Track your parcel in real time as the traveler carries it.'),
                  const SizedBox(height: 10),
                  _tip(context, '2', 'Chat with the traveler to coordinate handover details.'),
                  const SizedBox(height: 10),
                  _tip(context, '3', 'Confirm delivery via NFC when you meet the traveler.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _parcelSection(
    BuildContext context,
    AppTypography typo,
    CreatedDelivery? shipment,
    ReceiverDeliveryStatus? status,
  ) {
    if (_loading && shipment == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_error != null && shipment == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: typo.sm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(onPressed: () => _load(), child: const Text('Retry')),
          ],
        ),
      );
    }

    if (shipment == null || status == null) {
      return AppCard(
        child: Text(
          'No active shipments.',
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final travelDate = shipment.travelDateParsed;
    return GestureDetector(
      onTap: () {
        if (status.isPendingRequest) {
          context.push('/receiver-incoming-request/${shipment.displayId}');
        } else {
          context.push('/receiver-tracking?shipmentId=${shipment.displayId}');
        }
      },
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shipment.displayId,
                  style: typo.h3.copyWith(fontWeight: FontWeight.w700),
                ),
                AppBadge(
                  label: status.label,
                  color: status.color,
                  backgroundColor: status.backgroundColor,
                  semiBold: true,
                  wide: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              shipment.route.isNotEmpty ? shipment.route : '—',
              style: typo.sm,
            ),
            const SizedBox(height: 8),
            Text(
              status.isPendingRequest
                  ? 'From ${shipment.senderName ?? 'Sender'}'
                  : 'Traveler: ${shipment.senderName ?? '—'}',
              style: typo.sm,
            ),
            if (travelDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Arriving ${DateFormat('MMM d, yyyy').format(travelDate)}',
                style: typo.sm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    String iconAsset,
    String label,
    VoidCallback onTap,
  ) {
    final typo = context.typo;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 98),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppSvgIcon(asset: iconAsset, size: 28),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: typo.actionLabel.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tip(BuildContext context, String step, String text) {
    final typo = context.typo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: typo.sm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: typo.sm)),
      ],
    );
  }
}
