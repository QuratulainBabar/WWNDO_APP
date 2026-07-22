import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../data/models/delivery_request.dart';

/// Bottom sheet for placing a traveler bid on a parcel request.
class PlaceBidSheet extends StatefulWidget {
  const PlaceBidSheet({
    super.key,
    required this.request,
    this.initialPrice = 28.00,
  });

  final DeliveryRequest request;
  final double initialPrice;

  @override
  State<PlaceBidSheet> createState() => _PlaceBidSheetState();
}

class _PlaceBidSheetState extends State<PlaceBidSheet> {
  late final TextEditingController _priceController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.initialPrice.toStringAsFixed(2),
    );
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid bid amount.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      PlaceBidResult(
        price: price,
        message: _messageController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final request = widget.request;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Place a bid',
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                request.route,
                style: typo.body.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Max budget: \$${request.maxBudget.toStringAsFixed(2)}',
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              AppLabeledField(
                label: 'Your price (USD)',
                labelStyle:
                    typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                child: TextField(
                  controller: _priceController,
                  style: typo.input,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(),
                ),
              ),
              AppLabeledField(
                label: 'Message to sender (optional)',
                labelStyle:
                    typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  style: typo.input,
                  decoration: InputDecoration(
                    hintText:
                        'I travel this route every month and have hand luggage available...',
                    hintStyle: typo.sm.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Cancel',
                      variant: AppButtonVariant.outline,
                      textStyle: typo.button.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      label: 'Submit bid',
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceBidResult {
  const PlaceBidResult({
    required this.price,
    required this.message,
  });

  final double price;
  final String message;
}
