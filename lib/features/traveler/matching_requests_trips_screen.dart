import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/back_header.dart';

/// Sender requests for traveler trips — requires matching API.
class MatchingRequestsTripsScreen extends StatelessWidget {
  const MatchingRequestsTripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final horizontal = context.horizontalPadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Sender Requests'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 12),
            child: Text(
              'Select a trip to view sender requests.',
              style: typo.sm.copyWith(height: 1.45),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontal),
                child: Text(
                  'No trips with sender requests yet.',
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
