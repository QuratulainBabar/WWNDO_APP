import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/static_data.dart';

class SecurityLogsScreen extends StatelessWidget {
  const SecurityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final settingsRoute = roleParam == 'receiver'
        ? '/settings?role=receiver'
        : roleParam == 'traveler'
            ? '/settings?role=traveler'
            : '/settings?role=sender';
    final typo = context.typo;
    final logs = StaticData.securityLogs;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Security logs',
        fallbackRoute: settingsRoute,
      ),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent account activity on WWNGO.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < logs.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              AppCard(
                margin: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(logs[i].action, style: typo.bodyBold),
                    const SizedBox(height: 4),
                    Text(logs[i].device, style: typo.sm),
                    Text(
                      '${logs[i].location} · ${dateFormat.format(logs[i].timestamp)}',
                      style: typo.sm,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
