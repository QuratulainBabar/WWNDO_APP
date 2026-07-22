import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/shipment.dart';
import '../../data/static_data.dart';
import 'widgets/description_field.dart';
import 'widgets/travel_date_field.dart';
import 'widgets/weight_kg_field.dart';

class EditPostedDeliveryScreen extends StatefulWidget {
  const EditPostedDeliveryScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<EditPostedDeliveryScreen> createState() =>
      _EditPostedDeliveryScreenState();
}

class _EditPostedDeliveryScreenState extends State<EditPostedDeliveryScreen> {
  late final Shipment _parcel;
  late DateTime _travelDate;
  late double _weightKg;
  late final TextEditingController _descriptionController;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _parcel = StaticData.shipmentById(widget.shipmentId) ??
        StaticData.senderShipments.firstWhere(
          (s) => s.id == widget.shipmentId,
          orElse: () => StaticData.activeShipment,
        );
    _travelDate = _parcel.travelDate;
    _weightKg = _parcel.parcelWeightKg;
    _descriptionController = TextEditingController(
      text: _parcel.description.isNotEmpty
          ? _parcel.description
          : '${_parcel.parcelCategory} · ${_parcel.parcelSize}',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_weightKg <= 0) {
      setState(() => _weightError = 'Enter a valid weight greater than 0.');
      return;
    }

    StaticData.updateSenderShipment(
      Shipment(
        id: _parcel.id,
        fromCity: _parcel.fromCity,
        toCity: _parcel.toCity,
        fromCode: _parcel.fromCode,
        toCode: _parcel.toCode,
        travelDate: _travelDate,
        status: _parcel.status,
        role: _parcel.role,
        parcelCategory: _parcel.parcelCategory,
        parcelWeightKg: _weightKg,
        parcelSize: _parcel.parcelSize,
        description: _descriptionController.text.trim(),
        travelerName: _parcel.travelerName,
        flightNumber: _parcel.flightNumber,
        parcelPhotoCount: _parcel.parcelPhotoCount,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_parcel.id} updated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Edit ${_parcel.id}',
        fallbackRoute: '/my-posted-parcels',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(label: 'Save changes', onPressed: _save),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_parcel.id, style: typo.h3.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_parcel.route, style: typo.smPrimary),
                  const SizedBox(height: 4),
                  Text(
                    '${_parcel.parcelCategory} · ${_parcel.parcelSize}',
                    style: typo.sm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TravelDateField(
              value: _travelDate,
              onChanged: (date) => setState(() => _travelDate = date),
            ),
            const SizedBox(height: 16),
            WeightKgField(
              initialValue: _weightKg,
              errorText: _weightError,
              onChanged: (value) => setState(() {
                _weightKg = value;
                _weightError = null;
              }),
            ),
            const SizedBox(height: 16),
            DescriptionField(controller: _descriptionController),
          ],
        ),
      ),
    );
  }
}
