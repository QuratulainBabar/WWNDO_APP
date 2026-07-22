import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/parcel_creation_result.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'delivery_posting_actions.dart';
import 'parcel_creation_flow_data.dart';
import 'widgets/parcel_photos_section.dart';

class ParcelCreationWizardScreen extends StatefulWidget {
  const ParcelCreationWizardScreen({super.key, this.initialTrip});

  final TravelerTrip? initialTrip;

  @override
  State<ParcelCreationWizardScreen> createState() => _ParcelCreationWizardScreenState();
}

class _ParcelCreationWizardScreenState extends State<ParcelCreationWizardScreen> {
  static const _stepTitles = [
    'Select traveler',
    'Parcel type',
    'Weight',
    'Volume',
    'Recipient',
    'Payment',
    'Description & photos',
  ];

  late final ParcelCreationFlowData _flow;
  late final PageController _pageController;
  int _step = 0;
  String? _error;
  String? _photoError;
  late final TextEditingController _budgetController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _flow = ParcelCreationFlowData(selectedTrip: widget.initialTrip);
    _step = widget.initialTrip == null ? 0 : 1;
    _pageController = PageController(initialPage: _step);
    _budgetController = TextEditingController(
      text: _flow.proposedBudgetUsd.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    final validation = _flow.validateStep(_step);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    if (_step < _stepTitles.length - 1) {
      _goToStep(_step + 1);
    } else {
      _activate();
    }
  }

  void _back() {
    if (_step == 0) {
      context.pop();
      return;
    }
    _goToStep(_step - 1);
  }

  Future<void> _activate() async {
    if (!DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) return;

    final validation = _flow.validateStep(6);
    if (validation != null) {
      setState(() {
        _error = validation;
        _photoError = validation.toLowerCase().contains('photo') ? validation : null;
      });
      return;
    }

    final authUser = context.read<AuthProvider>().user;
    final sender = authUser?.toUserProfile() ?? StaticData.currentUser;

    try {
      final result = StaticData.submitParcelRequest(
        trip: _flow.selectedTrip!,
        category: _flow.category,
        weightKg: _flow.weightKg,
        volume: _flow.volume,
        recipientId: _flow.recipientId!,
        proposedBudgetUsd: _flow.proposedBudgetUsd,
        description: _flow.description,
        photoPaths: _flow.photoPaths,
        senderName: sender.name,
        senderInitial: sender.initial,
        senderRating: sender.rating,
      );
      if (!mounted) return;
      context.go('/post-delivery/success', extra: result);
    } on StateError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Create parcel',
        fallbackRoute: '/home',
        onBack: _back,
      ),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Step ${_step + 1} of ${_stepTitles.length}', style: typo.smPrimary),
            const SizedBox(height: 4),
            Text(_stepTitles[_step], style: typo.h2),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_step + 1) / _stepTitles.length,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _step = index),
                children: [
                  _buildTravelerStep(typo),
                  _buildCategoryStep(typo),
                  _buildWeightStep(typo),
                  _buildVolumeStep(typo),
                  _buildRecipientStep(typo),
                  _buildPaymentStep(typo),
                  _buildDescriptionStep(typo),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: typo.sm.copyWith(color: AppColors.danger)),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: _step == _stepTitles.length - 1 ? 'Activate parcel request' : 'Continue',
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelerStep(AppTypography typo) {
    final trips = StaticData.allDiscoverableTrips.map((e) => e.trip).toList();
    return ListView(
      children: [
        Text(
          'Select a traveler from published routes.',
          style: typo.sm.copyWith(height: 1.5),
        ),
        const SizedBox(height: 12),
        for (final trip in trips) ...[
          AppCard(
            highlighted: _flow.selectedTrip?.id == trip.id && trip.id.isNotEmpty,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(trip.route, style: typo.bodyBold),
              subtitle: Text(
                '${DateFormat('MMM d, yyyy').format(trip.travelDate)} · ${trip.luggageCapacityKg.toStringAsFixed(0)} kg capacity',
                style: typo.sm,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => setState(() {
                _flow.selectedTrip = trip;
                _error = null;
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryStep(AppTypography typo) {
    return ListView(
      children: [
        Text('Choose parcel category.', style: typo.sm),
        const SizedBox(height: 12),
        AppChipRow(
          options: ParcelCreationFlowData.categories,
          selected: _flow.category,
          onSelected: (value) => setState(() {
            _flow.category = value;
            _error = null;
          }),
        ),
      ],
    );
  }

  Widget _buildWeightStep(AppTypography typo) {
    return ListView(
      children: [
        Text('Set parcel weight (kg).', style: typo.sm),
        const SizedBox(height: 20),
        Text(
          '${_flow.weightKg.toStringAsFixed(1)} kg',
          style: typo.h1.copyWith(color: AppColors.primary),
          textAlign: TextAlign.center,
        ),
        Slider(
          value: _flow.weightKg.clamp(0.1, 30),
          min: 0.1,
          max: 30,
          divisions: 299,
          label: '${_flow.weightKg.toStringAsFixed(1)} kg',
          onChanged: (value) => setState(() => _flow.weightKg = value),
        ),
      ],
    );
  }

  Widget _buildVolumeStep(AppTypography typo) {
    return ListView(
      children: [
        Text('Select parcel volume.', style: typo.sm),
        const SizedBox(height: 12),
        AppChipRow(
          options: ParcelCreationFlowData.volumes,
          selected: _flow.volume,
          onSelected: (value) => setState(() {
            _flow.volume = value;
            _error = null;
          }),
        ),
      ],
    );
  }

  Widget _buildRecipientStep(AppTypography typo) {
    final verified =
        StaticData.verifiedRecipients.where((recipient) => recipient.verified).toList();

    return ListView(
      children: [
        Text('Recipient must be a verified contact.', style: typo.sm.copyWith(height: 1.5)),
        const SizedBox(height: 12),
        for (final recipient in verified) ...[
          AppCard(
            highlighted: _flow.recipientId == recipient.id,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(recipient.name.characters.first),
              ),
              title: Text(recipient.name, style: typo.bodyBold),
              subtitle: Text('${recipient.phone} · Verified', style: typo.sm),
              onTap: () => setState(() {
                _flow.recipientId = recipient.id;
                _error = null;
              }),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentStep(AppTypography typo) {
    return ListView(
      children: [
        Text('Proposed payment amount (USD).', style: typo.sm),
        const SizedBox(height: 16),
        AppLabeledField(
          label: 'Budget (USD)',
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            decoration: const InputDecoration(prefixText: '\$ '),
            controller: _budgetController,
            onChanged: (value) {
              _flow.proposedBudgetUsd = double.tryParse(value) ?? 0;
              _error = null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Maximum suggested: \$${StaticData.postDeliveryMaximumBudget.toStringAsFixed(0)}',
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDescriptionStep(AppTypography typo) {
    final trip = _flow.selectedTrip;
    final recipient = StaticData.recipientById(_flow.recipientId);

    return ListView(
      children: [
        AppLabeledField(
          label: 'Description',
          child: TextField(
            maxLines: 4,
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'What is inside the parcel?',
            ),
            onChanged: (value) {
              _flow.description = value;
              _error = null;
            },
          ),
        ),
        const SizedBox(height: 12),
        ParcelPhotosSection(
          photoPaths: _flow.photoPaths,
          errorText: _photoError,
          onChanged: (paths) => setState(() {
            _flow.photoPaths = paths;
            _photoError = null;
            _error = null;
          }),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review', style: typo.bodyBold),
              const SizedBox(height: 8),
              if (trip != null) Text('Route: ${trip.route}', style: typo.sm),
              Text('Category: ${_flow.category}', style: typo.sm),
              Text('Weight: ${_flow.weightKg.toStringAsFixed(1)} kg', style: typo.sm),
              Text('Volume: ${_flow.volume}', style: typo.sm),
              if (recipient != null) Text('Recipient: ${recipient.name}', style: typo.sm),
              Text('Budget: \$${_flow.proposedBudgetUsd.toStringAsFixed(2)}', style: typo.sm),
            ],
          ),
        ),
      ],
    );
  }
}
