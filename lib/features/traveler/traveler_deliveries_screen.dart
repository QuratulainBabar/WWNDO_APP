import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_link.dart';
import '../../data/models/shipment.dart';

/// Traveler deliveries — API-backed when available.
/// Backend currently has no traveler-scoped deliveries endpoint.
class TravelerDeliveriesScreen extends StatefulWidget {
  const TravelerDeliveriesScreen({super.key});

  @override
  State<TravelerDeliveriesScreen> createState() => _TravelerDeliveriesScreenState();
}

class _TravelerDeliveriesScreenState extends State<TravelerDeliveriesScreen> {
  bool _showActive = true;
  final List<Shipment> _deliveries = const [];

  List<Shipment> _deliveriesForTab() {
    // No mock data — list stays empty until GET /api/v1/deliveries?role=traveler exists.
    return _deliveries;
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = context.horizontalPadding;
    final typo = context.typo;
    final deliveries = _deliveriesForTab();

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
              child: deliveries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: Text(
                          _showActive
                              ? 'No active deliveries yet.'
                              : 'No completed deliveries yet.',
                          style: typo.sm.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: PlatformUi.scrollPhysics,
                      padding: EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
                      itemCount: deliveries.length,
                      itemBuilder: (context, i) {
                        final s = deliveries[i];
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
                                      style: typo.h3.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    AppBadge.status(s.status, semiBold: true, wide: true),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(s.route, style: typo.sm.copyWith(color: AppColors.textPrimary)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(s.role.label, style: typo.sm),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(s.travelDate),
                                      style: typo.sm,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
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
