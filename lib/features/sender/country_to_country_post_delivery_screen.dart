import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/geo/world_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/created_delivery.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/models/wallet_role.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../data/wallet_gate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_realtime_provider.dart';
import '../../providers/sender_deliveries_provider.dart';
import 'delivery_posting_actions.dart';
import 'widgets/delivery_form_fields.dart';

class CountryToCountryPostDeliveryScreen extends StatefulWidget {
  const CountryToCountryPostDeliveryScreen({super.key, this.initialTrip});

  final TravelerTrip? initialTrip;

  @override
  State<CountryToCountryPostDeliveryScreen> createState() =>
      _CountryToCountryPostDeliveryScreenState();
}

class _CountryToCountryPostDeliveryScreenState
    extends State<CountryToCountryPostDeliveryScreen> {
  final _formKey = GlobalKey<DeliveryFormFieldsState>();
  bool _submitting = false;

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final request = form.buildCreateRequest();
    if (!await DeliveryPostingActions.ensureWalletAllowsParcelCreation(
      context,
      category: request.parcelCategory,
      paysReceiverFee: request.paysReceiverFee,
    )) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    final repository = DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );

    setState(() => _submitting = true);
    try {
      final created = await repository.createDelivery(request);
      final fromIso = request.originCountry != null
          ? WorldCountries.all
              .where((c) => c.name == request.originCountry)
              .map((c) => c.iso)
              .firstOrNull
          : null;
      final toIso = request.destinationCountry != null
          ? WorldCountries.all
              .where((c) => c.name == request.destinationCountry)
              .map((c) => c.iso)
              .firstOrNull
          : null;

      if (demoMode.enabled) {
        StaticData.registerPostedDelivery(
          shipmentId: created.publicId,
          fromCity: request.originCountry ?? '',
          toCity: request.destinationCountry ?? '',
          fromCode: fromIso ?? 'WW',
          toCode: toIso ?? 'WW',
          travelDate: request.travelDate,
          parcelCategory: request.parcelCategory,
          parcelWeightKg: request.weightKg,
          parcelSize: request.parcelSize,
          description: request.description,
          parcelPhotoCount: request.photoPaths.length,
          paysReceiverFee: request.paysReceiverFee,
          seedDemoMatches: true,
        );
      }

      if (!mounted) return;
      // Optimistic + realtime invalidation so Home Active Deliveries updates
      // even when the shell route does not remount.
      context.read<SenderDeliveriesProvider>().upsert(created);
      context.read<NotificationRealtimeProvider>().notifyDeliveryUpdated();
      await WalletGate.refreshRoles(context, [WalletRole.sender]);
      if (!mounted) return;
      context.pushReplacement(
        '/post-delivery/success',
        extra: created,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final form = _formKey.currentState;
      if (form != null && form.applyServerValidationMessage(e.message)) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromTrip = widget.initialTrip != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Post delivery',
        fallbackRoute: fromTrip
            ? '/discover-trips/${widget.initialTrip!.displayId}'
            : '/delivery-type',
      ),
      body: ScrollableFormScreen(
        pinActions: false,
        actions: [
          AppButton(
            label: _submitting ? 'Posting…' : 'Post delivery →',
            onPressed: _submitting ? null : _submit,
          ),
        ],
        child: DeliveryFormFields(
          key: _formKey,
          deliveryType: DeliveryType.countryToCountry,
          initialTrip: widget.initialTrip,
        ),
      ),
    );
  }
}
