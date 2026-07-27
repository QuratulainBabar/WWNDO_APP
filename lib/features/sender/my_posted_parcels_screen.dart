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
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';
import 'sender_delivery_status.dart';

class MyPostedParcelsScreen extends StatefulWidget {
  const MyPostedParcelsScreen({
    super.key,
    this.title = 'My Posted Deliveries',
    this.fallbackRoute,
  });

  final String title;
  final String? fallbackRoute;

  @override
  State<MyPostedParcelsScreen> createState() => _MyPostedParcelsScreenState();
}

class _MyPostedParcelsScreenState extends State<MyPostedParcelsScreen>
    with WidgetsBindingObserver {
  bool _showActive = true;
  bool _loading = true;
  String? _error;
  // Nullable so hot-reload on web cannot leave a non-null List field as JS undefined.
  List<CreatedDelivery>? _deliveries;
  Map<String, int> _matchingTravelerCounts = {};

  List<CreatedDelivery> get _items => _deliveries ?? const <CreatedDelivery>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deliveries = const [];
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
      final list = await _repository().listDeliveries();
      if (!mounted) return;
      final deliveries = List<CreatedDelivery>.from(list);
      final counts = await _repository().fetchMatchingTravelerCounts(deliveries);
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _matchingTravelerCounts = counts;
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
        _error = 'Unable to load your posted deliveries. Please try again.';
      });
    }
  }

  List<CreatedDelivery> get _visible {
    return _items.where((d) {
      final active =
          SenderDeliveryStatus.fromDelivery(d).isActive;
      return _showActive ? active : !active;
    }).toList();
  }

  Future<void> _onMenuSelected(String value, CreatedDelivery parcel) async {
    final id = parcel.publicId.isNotEmpty ? parcel.publicId : parcel.id;
    if (value == 'edit') {
      final updated = await context.push<bool>('/edit-posted-delivery/$id');
      if (updated == true && mounted) {
        await _load(silent: true);
      }
      return;
    }
    if (value == 'cancel') {
      await context.push('/cancel-posted-delivery/$id');
      if (mounted) {
        await _load(silent: true);
      }
    }
  }

  List<PopupMenuEntry<String>> _menuItems(BuildContext context) {
    final typo = context.typo;
    final itemStyle = typo.body.copyWith(fontWeight: FontWeight.w400);

    return [
      PopupMenuItem(
        value: 'edit',
        height: 42,
        child: Text('Edit', style: itemStyle),
      ),
      const PopupMenuItem<String>(
        enabled: false,
        height: 1,
        padding: EdgeInsets.zero,
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.border,
        ),
      ),
      PopupMenuItem(
        value: 'cancel',
        height: 42,
        child: Text('Cancel', style: itemStyle),
      ),
    ];
  }

  Widget _tab(BuildContext context, String label, bool active, VoidCallback onTap) {
    final typo = context.typo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
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
          style: typo.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _formatTravelDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.isEmpty ? '—' : raw;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  String _formatWeight(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
    var label = kg.toStringAsFixed(2);
    label = label.replaceFirst(RegExp(r'0+$'), '');
    label = label.replaceFirst(RegExp(r'\.$'), '');
    return '$label kg';
  }

  Widget _body(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: context.pagePadding,
          children: [
            const SizedBox(height: 80),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => _load(),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    final parcels = _visible;
    if (parcels.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: context.pagePadding,
          children: [
            const SizedBox(height: 80),
            Text(
              _showActive
                  ? 'No active deliveries yet.'
                  : 'No completed deliveries yet.',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(silent: true),
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(parent: PlatformUi.scrollPhysics),
        padding: context.pagePadding,
        itemCount: parcels.length,
        itemBuilder: (context, i) {
          final parcel = parcels[i];
          final statusUi = SenderDeliveryStatus.fromDelivery(
            parcel,
            matchingTravelerCount: SenderDeliveryStatus.countFromMap(
              parcel,
              _matchingTravelerCounts,
            ),
          );
          final showMenu = _showActive && statusUi.canEditOrCancel;

          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcel.publicId.isNotEmpty
                                ? parcel.publicId
                                : parcel.id,
                            style: typo.h3.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AppBadge(
                            label: statusUi.label,
                            color: statusUi.color,
                            backgroundColor: statusUi.backgroundColor,
                            semiBold: true,
                            wide: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            parcel.route.isNotEmpty ? parcel.route : '—',
                            style: typo.sm,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Travel date: ${_formatTravelDate(parcel.travelDate)}'
                            ' · Weight: ${_formatWeight(parcel.weightKg)}',
                            style: typo.sm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showMenu)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        tooltip: 'More options',
                        onSelected: (value) => _onMenuSelected(value, parcel),
                        itemBuilder: _menuItems,
                      ),
                  ],
                ),
                if (_showActive && statusUi.description != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    statusUi.description!,
                    style: typo.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: widget.title,
        fallbackRoute: widget.fallbackRoute,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: horizontal),
            child: Row(
              children: [
                _tab(
                  context,
                  'Active',
                  _showActive,
                  () => setState(() => _showActive = true),
                ),
                const SizedBox(width: 28),
                _tab(
                  context,
                  'Completed',
                  !_showActive,
                  () => setState(() => _showActive = false),
                ),
              ],
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }
}
