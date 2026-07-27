import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/config/demo_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import 'delivery_posting_actions.dart';
import 'widgets/delivery_form_fields.dart';

class PostDeliveryScreen extends StatefulWidget {
  const PostDeliveryScreen({super.key});

  @override
  State<PostDeliveryScreen> createState() => _PostDeliveryScreenState();
}

class _PostDeliveryScreenState extends State<PostDeliveryScreen> {
  final _formKey = GlobalKey<DeliveryFormFieldsState>();
  bool _submitting = false;

  Future<void> _submit() async {
    if (!DeliveryPostingActions.ensureWalletAllowsParcelCreation(context)) {
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final request = form.buildCreateRequest();
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    final repository = DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );

    setState(() => _submitting = true);
    try {
      final created = await repository.createDelivery(request);
      final fromCity = request.fromCity ?? '';
      final toCity = request.toCity ?? '';
      StaticData.registerPostedDelivery(
        shipmentId: created.publicId,
        fromCity: fromCity,
        toCity: toCity,
        fromCode: request.fromCode?.isNotEmpty == true ? request.fromCode! : 'WW',
        toCode: request.toCode?.isNotEmpty == true ? request.toCode! : 'WW',
        travelDate: request.travelDate,
        parcelCategory: request.parcelCategory,
        parcelWeightKg: request.weightKg,
        parcelSize: request.parcelSize,
        description: request.description,
        parcelPhotoCount: request.photoPaths.length,
        paysReceiverFee: request.paysReceiverFee,
        seedDemoMatches: demoMode.enabled,
      );

      if (!mounted) return;
      context.pushReplacement(
        '/post-delivery/success',
        extra: created.route.isNotEmpty ? created.route : request.routeLabel,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(
        title: 'Post delivery',
        fallbackRoute: '/delivery-type',
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: _submitting ? 'Posting…' : 'Post delivery →',
            onPressed: _submitting ? null : _submit,
          ),
        ],
        child: DeliveryFormFields(
          key: _formKey,
          deliveryType: DeliveryType.cityToCity,
        ),
      ),
    );
  }
}
