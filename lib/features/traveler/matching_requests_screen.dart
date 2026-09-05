import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/back_header.dart';
import '../../data/services/trip_repository.dart';
import '../../providers/auth_provider.dart';

/// Deep-link entry for `/matching-requests/:tripId`.
/// Skips the old intermediate list and opens the full request detail when
/// possible; otherwise falls back to the main Sender Requests screen.
class MatchingRequestsScreen extends StatefulWidget {
  const MatchingRequestsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<MatchingRequestsScreen> createState() => _MatchingRequestsScreenState();
}

class _MatchingRequestsScreenState extends State<MatchingRequestsScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _resolve() async {
    try {
      final requests = await _repo().listSenderRequestsForTrip(widget.tripId);
      if (!mounted) return;
      if (requests.isEmpty) {
        context.go('/matching-requests');
        return;
      }
      if (requests.length == 1) {
        context.go('/request/${requests.first.id}');
        return;
      }
      // Multiple requests for this trip — show them on the main list.
      context.go('/matching-requests');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to open sender request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Sender Requests'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(
                onPressed: () => context.go('/matching-requests'),
                child: const Text('Back to Sender Requests'),
              ),
            ],
          ),
        ),
      );
    }

    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: 'Sender Requests'),
      body: Center(
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
}
