import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/services/trip_repository.dart';
import '../../l10n/app_localizations.dart';
import 'trip_posting_actions.dart';
import 'widgets/trip_form_fields.dart';

class CountryToCountryPostTripScreen extends StatefulWidget {
  const CountryToCountryPostTripScreen({super.key});

  @override
  State<CountryToCountryPostTripScreen> createState() =>
      _CountryToCountryPostTripScreenState();
}

class _CountryToCountryPostTripScreenState
    extends State<CountryToCountryPostTripScreen> {
  final _formKey = GlobalKey<TripFormFieldsState>();

  void _postTrip() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    TripPostingActions.tryPostTrip(
      context,
      form.buildPreviewTrip(),
      request: form.buildCreateRequest(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(title: l10n.postTrip),
      body: ScrollableFormScreen(
        pinActions: false,
        actions: [
          AppButton(
            label: l10n.postTripArrow,
            onPressed: _postTrip,
          ),
        ],
        child: TripFormFields(
          key: _formKey,
          tripType: TripType.countryToCountry,
          showCreateBadges: true,
        ),
      ),
    );
  }
}
