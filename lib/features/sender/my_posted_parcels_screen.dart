import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';

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

class _MyPostedParcelsScreenState extends State<MyPostedParcelsScreen> {
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    // Drop Matching Travelers cards that duplicate an in-progress corridor
    // (e.g. France→Senegal when Paris→Dakar is already Traveler Selected).
    StaticData.purgeOpenSenderDuplicatesOfInProgress();
  }

  List<Shipment> get _parcels => StaticData.senderShipments.where((s) {
        final status = StaticData.effectiveStatus(s);
        final isActive = status != ShipmentStatus.delivered;
        return _showActive ? isActive : !isActive;
      }).toList();

  void _onEdit(BuildContext context, Shipment parcel) {
    context.push('/edit-posted-delivery/${parcel.id}');
  }

  void _onCancel(BuildContext context, Shipment parcel) {
    context.push('/cancel-posted-delivery/${parcel.id}');
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

  bool _canEditOrCancel(SenderPostedPhase? phase) {
    return phase == SenderPostedPhase.waitingForReceiver ||
        phase == SenderPostedPhase.matchingTravelers ||
        phase == SenderPostedPhase.travelerReviewing;
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
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
                _tab(context, 'Active', _showActive, () => setState(() => _showActive = true)),
                const SizedBox(width: 28),
                _tab(context, 'Completed', !_showActive, () => setState(() => _showActive = false)),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: StaticData.bidRequestsVersion,
              builder: (context, _, __) {
                return ValueListenableBuilder<int>(
                  valueListenable: StaticData.nfcCheckpointVersion,
                  builder: (context, _, __) {
                    final parcels = _parcels;
                    return ListView.builder(
                      physics: PlatformUi.scrollPhysics,
                      padding: context.pagePadding,
                      itemCount: parcels.length,
                      itemBuilder: (context, i) {
                        final parcel = parcels[i];
                        final phase = StaticData.senderPostedPhase(parcel);
                        final showMenu = _showActive && _canEditOrCancel(phase);

                        final badge = phase != null
                            ? AppBadge(
                                label: StaticData.senderPostedBadgeLabel(
                                  phase,
                                  parcel.id,
                                ),
                                color: phase.color,
                                backgroundColor: phase.backgroundColor,
                                semiBold: true,
                                wide: true,
                              )
                            : AppBadge.status(
                                StaticData.effectiveStatus(parcel),
                                semiBold: true,
                                wide: true,
                              );

                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => context.push(
                                        StaticData.senderParcelOpenRoute(
                                          parcel.id,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            parcel.id,
                                            style: typo.h3.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          badge,
                                          const SizedBox(height: 8),
                                          Text(parcel.route, style: typo.sm),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Travel date: ${DateFormat('MMM d, yyyy').format(parcel.travelDate)}'
                                            ' · Weight: ${parcel.parcelWeightKg} kg',
                                            style: typo.sm.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _onEdit(context, parcel);
                                        } else if (value == 'cancel') {
                                          _onCancel(context, parcel);
                                        }
                                      },
                                      itemBuilder: _menuItems,
                                    ),
                                ],
                              ),
                              if (_showActive &&
                                  phase != null &&
                                  phase !=
                                      SenderPostedPhase.travelerSelected) ...[
                                const SizedBox(height: 10),
                                Text(
                                  phase.description,
                                  style: typo.sm.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
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
    );
  }
}
