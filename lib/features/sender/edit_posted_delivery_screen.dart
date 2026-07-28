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
import '../../data/models/created_delivery.dart';
import '../../data/services/delivery_repository.dart';
import '../../providers/auth_provider.dart';
import 'widgets/delivery_form_fields.dart';

class EditPostedDeliveryScreen extends StatefulWidget {
  const EditPostedDeliveryScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  State<EditPostedDeliveryScreen> createState() =>
      _EditPostedDeliveryScreenState();
}

class _EditPostedDeliveryScreenState extends State<EditPostedDeliveryScreen> {
  final _formKey = GlobalKey<DeliveryFormFieldsState>();

  CreatedDelivery? _delivery;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  DeliveryRepository _repository() {
    final auth = context.read<AuthProvider>();
    final demoMode = context.read<DemoModeProvider>();
    return DeliveryRepository(
      apiClient: auth.repository.apiClient,
      demoMode: demoMode,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final delivery = await _repository().getDelivery(widget.shipmentId);
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
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
        _loadError = 'Unable to load this delivery. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _save() async {
    final delivery = _delivery;
    if (delivery == null) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _saving = true);
    try {
      await _repository().updateDelivery(
        delivery.displayId,
        form.buildUpdateRequest(),
      );
      if (!mounted) return;
      AppToast.success(context, '${delivery.displayId} updated');
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
          title: 'Edit delivery',
          fallbackRoute: '/my-posted-parcels',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_loadError != null || _delivery == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const BackHeader(
          title: 'Edit delivery',
          fallbackRoute: '/my-posted-parcels',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError ?? 'Delivery not found.',
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

    final delivery = _delivery!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Edit ${delivery.displayId}',
        fallbackRoute: '/my-posted-parcels',
      ),
      body: ScrollableFormScreen(
        pinActions: false,
        actions: [
          AppButton(
            label: _saving ? 'Saving…' : 'Save changes',
            onPressed: _saving ? null : _save,
          ),
        ],
        child: DeliveryFormFields(
          key: _formKey,
          deliveryType: delivery.deliveryType,
          initialDelivery: delivery,
          isEditMode: true,
        ),
      ),
    );
  }
}
