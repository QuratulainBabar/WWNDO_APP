import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/delivery_request.dart';
import '../../data/models/matching_request.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';

class SendCounterOfferScreen extends StatefulWidget {
  const SendCounterOfferScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<SendCounterOfferScreen> createState() => _SendCounterOfferScreenState();
}

class _SendCounterOfferScreenState extends State<SendCounterOfferScreen> {
  late final TextEditingController _budgetController;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  DeliveryRequest? _request;
  String _tripId = '';

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  TripRepository _repo() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return TripRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = await _repo().getSenderRequest(widget.requestId);
      if (!mounted) return;
      final request = api.toDeliveryRequest();
      final tripKey =
          api.tripPublicId.isNotEmpty ? api.tripPublicId : api.tripId;
      StaticData.matchingRequests.removeWhere((m) => m.request.id == api.id);
      StaticData.matchingRequests.add(
        MatchingRequest(
          request: request,
          matchScore: api.matchScore,
          tripId: tripKey,
        ),
      );
      _budgetController.text = request.maxBudget.toStringAsFixed(2);
      setState(() {
        _request = request;
        _tripId = tripKey;
        _loading = false;
      });
      return;
    } catch (_) {
      // Fall through to static.
    }

    final matching = StaticData.matchingRequestById(widget.requestId);
    if (matching != null) {
      if (!mounted) return;
      _budgetController.text = matching.request.maxBudget.toStringAsFixed(2);
      setState(() {
        _request = matching.request;
        _tripId = matching.tripId;
        _loading = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Unable to load this request.';
    });
  }

  Future<void> _sendFinalBudget() async {
    final request = _request;
    if (request == null || _submitting) return;

    final amount = double.tryParse(_budgetController.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.error(context, 'Enter a valid budget amount.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final offer = await _repo().sendCounterOffer(
        requestId: widget.requestId,
        amount: amount,
      );
      if (!mounted) return;
      StaticData.upsertTravelerBid(offer);
      FocusScope.of(context).unfocus();
      AppToast.success(
        context,
        offer.status.label == 'Updated'
            ? 'Counter offer updated.'
            : 'Final budget sent to the sender.',
      );
      context.pop(true);
      return;
    } on ApiException catch (e) {
      if (!mounted) return;
      // Fall through to static demo path for offline / demo.
      if (e.code != 'DEMO_MODE') {
        AppToast.error(context, e.message);
        setState(() => _submitting = false);
        return;
      }
    } catch (_) {
      // Fall through to static.
    }

    final authUser = context.read<AuthProvider>().user;
    final error = StaticData.sendTravelerFinalBudget(
      request: request,
      tripId: _tripId,
      amount: amount,
      authUser: authUser,
      allowAboveMaxBudget: true,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    FocusScope.of(context).unfocus();
    AppToast.success(context, 'Final budget sent to the sender.');
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(title: 'Send Counter Offer'),
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

    if (_error != null || _request == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(title: 'Send Counter Offer'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error ?? 'Request not found.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Send Counter Offer'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: _submitting ? 'Sending…' : 'Send Final Budget',
            onPressed: _submitting ? null : _sendFinalBudget,
          ),
        ],
        child: AppCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter a new budget amount to send to the sender.',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Sender maximum budget: \$${_request!.maxBudget.toStringAsFixed(2)} USD',
                style: typo.sm.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              AppLabeledField(
                label: 'Your counter offer (USD)',
                child: TextField(
                  controller: _budgetController,
                  onTap: ensureSoftKeyboardVisible,
                  onTapOutside: dismissKeyboardOnTapOutside,
                  enabled: !_submitting,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: typo.input,
                  decoration: const InputDecoration(
                    hintText: '0.00',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
