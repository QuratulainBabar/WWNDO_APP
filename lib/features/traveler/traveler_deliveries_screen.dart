import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';

class TravelerDeliveriesScreen extends StatefulWidget {
  const TravelerDeliveriesScreen({super.key});

  @override
  State<TravelerDeliveriesScreen> createState() => _TravelerDeliveriesScreenState();
}

class _TravelerDeliveriesScreenState extends State<TravelerDeliveriesScreen> {
  bool _showActive = true;

  static const _activeStatuses = {
    ShipmentStatus.bidAccepted,
    ShipmentStatus.photosUploaded,
    ShipmentStatus.collected,
    ShipmentStatus.inTransit,
  };

  List<Shipment> _deliveriesForTab() {
    return StaticData.travelerShipments.where((s) {
      final status = StaticData.effectiveStatus(s);
      final isActive = _activeStatuses.contains(status);
      return _showActive ? isActive : status == ShipmentStatus.delivered;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
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
                  Text('My Deliveries', style: context.typo.h1),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  _tab(context, 'Active', _showActive, () => setState(() => _showActive = true)),
                  const SizedBox(width: 28),
                  _tab(context, 'Completed', !_showActive, () => setState(() => _showActive = false)),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: StaticData.nfcCheckpointVersion,
                builder: (context, _, __) {
                  return ValueListenableBuilder<int>(
                    valueListenable: StaticData.bidRequestsVersion,
                    builder: (context, _, __) {
                      final deliveries = _deliveriesForTab();
                      return ListView.builder(
                        physics: PlatformUi.scrollPhysics,
                        padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
                        itemCount: deliveries.length,
                        itemBuilder: (context, i) {
                          final s = deliveries[i];
                          final status = StaticData.effectiveStatus(s);
                          return GestureDetector(
                            onTap: () => context.push('/shipment/${s.id}?traveler=true'),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                              margin: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        s.id,
                                        style: context.typo.h3.copyWith(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      AppBadge.status(
                                        status,
                                        semiBold: true,
                                        wide: true,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(s.route, style: context.typo.sm.copyWith(color: AppColors.textPrimary)),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(s.role.label, style: context.typo.sm),
                                      Text(DateFormat('MMM d, yyyy').format(s.travelDate), style: context.typo.sm),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}
