import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/services/trip_repository.dart';
import 'trip_posting_actions.dart';
import 'widgets/trip_form_fields.dart';

class PostTripScreen extends StatefulWidget {
  const PostTripScreen({super.key});

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Post a trip'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Post trip →',
            onPressed: _postTrip,
          ),
        ],
        child: TripFormFields(
          key: _formKey,
          tripType: TripType.cityToCity,
          showCreateBadges: true,
        ),
      ),
    );
  }
}
