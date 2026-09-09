import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/delivery_status_badge.dart';
import '../../core/widgets/stacked_route_endpoints.dart';
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';

enum _DeliveriesTab { active, completed, cancelled }

/// Traveler assigned bookings — GET /deliveries?role=traveler.
class TravelerDeliveriesScreen extends StatefulWidget {
  const TravelerDeliveriesScreen({super.key});

  @override
  State<TravelerDeliveriesScreen> createState() =>
      _TravelerDeliveriesScreenState();
}

class _TravelerDeliveriesScreenState extends State<TravelerDeliveriesScreen>
    with WidgetsBindingObserver {
  _DeliveriesTab _tabFilter = _DeliveriesTab.active;
  bool _loading = true;
  String? _error;
  List<CreatedDelivery> _deliveries = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
    }
  }

  DeliveryRepository _repository() {
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
      final list = await _repository().listDeliveries(role: 'traveler');
      if (!mounted) return;
      setState(() {
        _deliveries = list;
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
        _error = 'Unable to load deliveries. Please try again.';
      });
    }
  }

  List<CreatedDelivery> get _visible {
    return _deliveries.where((d) {
      final status = (d.status ?? '').toLowerCase();
      return switch (_tabFilter) {
        _DeliveriesTab.active =>
          status != 'delivered' && status != 'cancelled',
        _DeliveriesTab.completed => status == 'delivered',
        _DeliveriesTab.cancelled => status == 'cancelled',
      };
    }).toList();
  }

  Future<void> _openDelivery(CreatedDelivery delivery) async {
    final id = delivery.publicId.isNotEmpty ? delivery.publicId : delivery.id;
    await context.push('/shipment/$id?traveler=true');
    if (mounted) await _load(silent: true);
  }

  String _formatTravelDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '—' : raw;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final typo = context.typo;
    final deliveries = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackLink(onTap: () => context.go('/traveler-home')),
                  const SizedBox(height: 16),
                  Text('My Deliveries', style: typo.h1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _tab(
                      context,
                      'Active',
                      _tabFilter == _DeliveriesTab.active,
                      () => setState(() => _tabFilter = _DeliveriesTab.active),
                    ),
                  ),
                  Expanded(
                    child: _tab(
                      context,
                      'Completed',
                      _tabFilter == _DeliveriesTab.completed,
                      () =>
                          setState(() => _tabFilter = _DeliveriesTab.completed),
                    ),
                  ),
                  Expanded(
                    child: _tab(
                      context,
                      'Cancelled',
                      _tabFilter == _DeliveriesTab.cancelled,
                      () =>
                          setState(() => _tabFilter = _DeliveriesTab.cancelled),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, typo, horizontal, deliveries)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppTypography typo,
    double horizontal,
    List<CreatedDelivery> deliveries,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Text(
            switch (_tabFilter) {
              _DeliveriesTab.active => 'No active deliveries yet.',
              _DeliveriesTab.completed => 'No completed deliveries yet.',
              _DeliveriesTab.cancelled => 'No cancelled deliveries yet.',
            },
            style: typo.sm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(parent: PlatformUi.scrollPhysics),
        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
        itemCount: deliveries.length,
        itemBuilder: (context, i) {
          final d = deliveries[i];
          final id = d.publicId.isNotEmpty ? d.publicId : d.id;
          return AppCard(
            onTap: () => _openDelivery(d),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        id,
                        style: typo.h3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DeliveryStatusBadge(d.status, semiBold: true),
                  ],
                ),
                const SizedBox(height: 10),
                StackedRouteEndpoints(
                  from: d.exactDisplayFrom,
                  to: d.exactDisplayTo,
                  fallbackRoute: d.exactDisplayRoute,
                ),
                const SizedBox(height: 8),
                Text(
                  'Travel date: ${_formatTravelDate(d.travelDate)}'
                  '${d.senderName != null && d.senderName!.isNotEmpty ? ' · ${d.senderName}' : ''}',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    final typo = context.typo;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: typo.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
