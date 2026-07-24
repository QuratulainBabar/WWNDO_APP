import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';

/// Counter offers sent by the traveler — requires bids API.
class TravelerMyBidsScreen extends StatelessWidget {
  const TravelerMyBidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Counter Offers Sent'),
      body: ListView(
        physics: PlatformUi.scrollPhysics,
        padding: context.pagePadding,
        children: [
          Text(
            'These are the counter offers you have sent to senders.',
            style: typo.sm.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'No counter offers yet.',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
