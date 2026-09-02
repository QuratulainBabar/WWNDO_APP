import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/services/trip_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'widgets/trip_form_fields.dart';

class EditTripScreen extends StatefulWidget {
  const EditTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _formKey = GlobalKey<TripFormFieldsState>();

  TravelerTrip? _trip;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  TripRepository _repository() {
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
      _loadError = null;
    });

    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) {
      final trip = StaticData.travelerTripById(widget.tripId) ??
          (StaticData.travelerPostedTrips.isNotEmpty
              ? StaticData.travelerPostedTrips.first
              : null);
      if (!mounted) return;
      if (trip == null) {
        setState(() {
          _loading = false;
          _loadError = 'Trip not found.';
        });
        return;
      }
      setState(() {
        _trip = trip;
        _loading = false;
      });
      return;
    }

    try {
      final trip = await _repository().getMyTrip(widget.tripId);
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Unable to load this trip. Please try again.';
      });
    }
  }

  Future<void> _save() async {
    final trip = _trip;
    if (trip == null) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final request = form.buildUpdateRequest();
    final preview = form.buildPreviewTrip();

    final demoMode = context.read<DemoModeProvider>().enabled;
    if (demoMode) {
      StaticData.updateTravelerTrip(
        TravelerTrip(
          id: trip.id,
          publicId: trip.publicId,
          origin: preview.origin,
          destination: preview.destination,
          travelDate: preview.travelDate,
          luggageCapacityKg: preview.luggageCapacityKg,
          status: trip.status,
          tripType: trip.tripType,
          flightNumber: request.flightNumber,
          fromCode: request.fromCode,
          toCode: request.toCode,
          originCountry: request.originCountry,
          destinationCountry: request.destinationCountry,
          originCountryCode: request.originCountryCode,
          destinationCountryCode: request.destinationCountryCode,
        ),
      );
      if (!mounted) return;
      AppToast.success(context, '${trip.displayId} updated');
      context.pop(true);
      return;
    }

    setState(() => _saving = true);
    try {
      await _repository().updateTrip(trip.displayId, request);
      if (!mounted) return;
      AppToast.success(context, '${trip.displayId} updated');
      context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to save changes. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(
          title: 'Edit trip',
          fallbackRoute: '/traveler-trips',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null || _trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(
          title: 'Edit trip',
          fallbackRoute: '/traveler-trips',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? 'Trip not found.',
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final trip = _trip!;

    if (!trip.status.canEditOrCancel) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: BackHeader(
          title: 'Edit ${trip.displayId}',
          fallbackRoute: '/traveler-trips',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Completed trips cannot be edited.',
              textAlign: TextAlign.center,
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Edit ${trip.displayId}',
        fallbackRoute: '/traveler-trips',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: _saving ? 'Saving…' : 'Save changes',
            onPressed: _saving ? null : _save,
          ),
        ],
        child: TripFormFields(
          key: _formKey,
          tripType: trip.tripTypeEnum,
          initialTrip: trip,
        ),
      ),
    );
  }
}
