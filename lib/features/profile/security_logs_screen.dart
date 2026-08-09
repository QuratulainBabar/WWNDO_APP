import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class SecurityLogsScreen extends StatefulWidget {
  const SecurityLogsScreen({super.key});

  @override
  State<SecurityLogsScreen> createState() => _SecurityLogsScreenState();
}

class _SecurityLogsScreenState extends State<SecurityLogsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _logs = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final demo = context.read<DemoModeProvider>().enabled;
    if (demo) {
      setState(() {
        _logs = StaticData.securityLogs
            .map(
              (l) => {
                'action': l.action,
                'device': l.device,
                'location': l.location,
                'timestamp': l.timestamp.toIso8601String(),
              },
            )
            .toList();
        _loading = false;
      });
      return;
    }
    try {
      final logs = await auth.repository.getSecurityLogs();
      if (mounted) {
        setState(() {
          _logs = logs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final settingsRoute = roleParam == 'receiver'
        ? '/settings?role=receiver'
        : roleParam == 'traveler'
            ? '/settings?role=traveler'
            : '/settings?role=sender';
    final typo = context.typo;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Security logs',
        fallbackRoute: settingsRoute,
      ),
      body: ScreenBody(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Recent account activity on WWNGO.',
                    style: typo.sm.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  if (_logs.isEmpty)
                    Text(
                      'No security events recorded yet.',
                      style: typo.sm.copyWith(color: AppColors.textSecondary),
                    ),
                  for (var i = 0; i < _logs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    AppCard(
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _logs[i]['action'] as String? ?? 'Activity',
                            style: typo.bodyBold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _logs[i]['device'] as String? ?? 'Unknown device',
                            style: typo.sm,
                          ),
                          Text(
                            '${_logs[i]['location'] ?? 'Unknown'} · ${dateFormat.format(DateTime.tryParse(_logs[i]['timestamp']?.toString() ?? '') ?? DateTime.now())}',
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
