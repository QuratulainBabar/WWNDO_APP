import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  DeliveryRequest get _request {
    final matching = StaticData.matchingRequestById(widget.requestId);
    return matching?.request ?? StaticData.matchingRequests.first.request;
  }

  String get _tripId =>
      StaticData.matchingRequestById(widget.requestId)?.tripId ?? '';

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: _request.maxBudget.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _sendFinalBudget() {
    final amount = double.tryParse(_budgetController.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.error(context, 'Enter a valid budget amount.');
      return;
    }

    final authUser = context.read<AuthProvider>().user;
    final error = StaticData.sendTravelerFinalBudget(
      request: _request,
      tripId: _tripId,
      amount: amount,
      authUser: authUser,
      allowAboveMaxBudget: true,
    );
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Send Counter Offer'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Send Final Budget',
            onPressed: _sendFinalBudget,
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
              AppLabeledField(
                label: 'Proposed Budget',
                labelStyle:
                    typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                child: TextField(
                  controller: _budgetController,
                  onTapOutside: dismissKeyboardOnTapOutside,
                  style: typo.input,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendFinalBudget(),
                  decoration: InputDecoration(
                    hintText: 'Enter your proposed budget (USD)',
                    hintStyle: typo.sm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    prefixText: '\$ ',
                    prefixStyle: typo.input,
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
