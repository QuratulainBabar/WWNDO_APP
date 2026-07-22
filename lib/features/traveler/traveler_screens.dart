import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
// TEMPORARILY DISABLED - SUMSUB KYC
// import 'package:provider/provider.dart';
import '../../core/geo/world_cities.dart';
import '../../core/geo/world_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_chip.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/models/delivery_request.dart';
import '../../data/models/traveler_trip.dart';
import '../../data/static_data.dart';
import '../../data/trip_creation_wallet_validation.dart';
// TEMPORARILY DISABLED - SUMSUB KYC
// import '../../providers/auth_provider.dart';
import '../sender/widgets/route_country_dropdown.dart';
import '../sender/widgets/travel_date_field.dart';
import 'trip_posting_actions.dart';
import 'widgets/available_luggage_capacity_field.dart';
import 'widgets/route_city_dropdown.dart';

class PostTripScreen extends StatefulWidget {
  const PostTripScreen({super.key});

  @override
  State<PostTripScreen> createState() => _PostTripScreenState();
}

class _PostTripScreenState extends State<PostTripScreen> {
  late String _fromCity;
  late String _fromCode;
  late String _toCity;
  late String _toCode;
  late DateTime _travelDate;
  late int _luggageCapacityKg;
  late final TextEditingController _flightNumberController;

  @override
  void initState() {
    super.initState();
    final req = StaticData.deliveryRequests.first;
    _fromCity = req.fromCity;
    _toCity = req.toCity;
    _fromCode = _resolveCodeForCity(_fromCity, fallback: 'GB');
    _toCode = _resolveCodeForCity(_toCity, fallback: 'NG');
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final travelDate = DateTime(
      req.travelDate.year,
      req.travelDate.month,
      req.travelDate.day,
    );
    _travelDate = travelDate.isBefore(todayDate) ? todayDate : travelDate;
    _luggageCapacityKg =
        StaticData.travelerAvailableLuggageCapacityKg.round();
    _flightNumberController = TextEditingController(text: 'BA083');
  }

  @override
  void dispose() {
    _flightNumberController.dispose();
    super.dispose();
  }

  String _resolveCodeForCity(String cityName, {required String fallback}) {
    final city = WorldCities.byName(cityName);
    if (city != null) return city.countryIso;
    if (WorldCountries.containsIso(fallback)) return fallback;
    return 'GB';
  }

  void _onFromCodeChanged(String iso) {
    final firstCity = WorldCities.firstForCountry(iso);
    setState(() {
      _fromCode = iso;
      if (WorldCities.byName(_fromCity, countryIso: iso) == null) {
        _fromCity = firstCity?.name ?? '';
      }
    });
  }

  void _onToCodeChanged(String iso) {
    final firstCity = WorldCities.firstForCountry(iso);
    setState(() {
      _toCode = iso;
      if (WorldCities.byName(_toCity, countryIso: iso) == null) {
        _toCity = firstCity?.name ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sectionTitleStyle =
        context.typo.h3.copyWith(fontWeight: FontWeight.w600);
    // TEMPORARILY DISABLED - SUMSUB KYC
    // final authUser = context.watch<AuthProvider>().user;
    // final kycOk = authUser?.isKycApproved ?? false;
    final reserveOk = TripCreationWalletValidation.hasMinimumBalance;
    final cityCountries = WorldCities.countryIsosWithCities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Post a trip'),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: 'Post trip →',
            onPressed: () {
              TripPostingActions.tryPostTrip(
                context,
                TravelerTrip(
                  origin: _fromCity,
                  destination: _toCity,
                  travelDate: _travelDate,
                  luggageCapacityKg: _luggageCapacityKg.toDouble(),
                ),
              );
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell senders where you\'re going and how much you can carry.',
              style: context.typo.sm,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // TEMPORARILY DISABLED - SUMSUB KYC
                // AppBadge(
                //   label: kycOk ? 'KYC approved' : 'KYC required',
                //   color: kycOk ? AppColors.success : AppColors.danger,
                //   backgroundColor:
                //       (kycOk ? AppColors.success : AppColors.danger)
                //           .withValues(alpha: 0.12),
                //   semiBold: true,
                // ),
                AppBadge(
                  label: TripCreationWalletValidation.helperLabel,
                  color: reserveOk ? AppColors.success : AppColors.danger,
                  backgroundColor:
                      (reserveOk ? AppColors.success : AppColors.danger)
                          .withValues(alpha: 0.12),
                  semiBold: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Route', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RouteCityDropdown(
                          label: 'From city',
                          value: _fromCity.isEmpty ? null : _fromCity,
                          countryIso: _fromCode,
                          hintText: 'Select from city',
                          onChanged: (city) => setState(() {
                            _fromCity = city.name;
                            _fromCode = city.countryIso;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 96,
                        child: RouteCountryDropdown(
                          label: 'Code',
                          value: _fromCode,
                          hintText: 'Code',
                          compact: true,
                          allowedIsos: cityCountries,
                          onChanged: _onFromCodeChanged,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RouteCityDropdown(
                          label: 'To city',
                          value: _toCity.isEmpty ? null : _toCity,
                          countryIso: _toCode,
                          hintText: 'Select to city',
                          onChanged: (city) => setState(() {
                            _toCity = city.name;
                            _toCode = city.countryIso;
                          }),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 96,
                        child: RouteCountryDropdown(
                          label: 'Code',
                          value: _toCode,
                          hintText: 'Code',
                          compact: true,
                          allowedIsos: cityCountries,
                          onChanged: _onToCodeChanged,
                        ),
                      ),
                    ],
                  ),
                  TravelDateField(
                    value: _travelDate,
                    onChanged: (date) => setState(() => _travelDate = date),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Luggage Capacity', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  AvailableLuggageCapacityField(
                    initialValue: _luggageCapacityKg,
                    onChanged: (kg) => _luggageCapacityKg = kg,
                  ),
                  AppLabeledField(
                    label: 'Flight number (optional)',
                    labelStyle: context.typo.inputLabel
                        .copyWith(fontWeight: FontWeight.w600),
                    child: TextField(
                      controller: _flightNumberController,
                      style: context.typo.input,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. BA083',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  String _filter = 'All';

  List<DeliveryRequest> get _filtered {
    if (_filter == 'All') return StaticData.deliveryRequests;
    return StaticData.deliveryRequests
        .where((r) => r.categoryTypeLabel == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Requests'),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: PlatformUi.scrollPhysics,
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding, vertical: 10),
            child: Row(
              children: StaticData.requestFilters
                  .map(
                    (f) => AppChip(
                      label: f,
                      selected: f == _filter,
                      onTap: () => setState(() => _filter = f),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: PlatformUi.scrollPhysics,
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              itemCount: _filtered.length,
              itemBuilder: (context, i) => _RequestCard(
                request: _filtered[i],
                onViewDetails: () => context.push('/request/${_filtered[i].id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onViewDetails});

  final DeliveryRequest request;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return AppCard(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewDetails,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.route,
                            style: typo.h3.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            DateFormat('MMM d, yyyy').format(request.travelDate),
                            style: typo.sm,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('max budget', style: typo.sm),
                        Text(
                          '\$${request.maxBudget.toInt()}',
                          style: typo.priceSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    AppBadge(
                      label: request.categoryTypeLabel,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    AppBadge(
                      label: '${request.weightKg} kg',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    AppBadge(
                      label: request.size,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    AppAvatar(initial: request.senderInitial, size: AvatarSize.small),
                    const SizedBox(width: 8),
                    Text(
                      request.senderName,
                      style: typo.sm.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Text('★ ${request.senderRating}', style: typo.sm),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Message from sender',
                  style: typo.sm.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  request.displaySenderMessage,
                  style: typo.sm.copyWith(height: 1.4),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'View details',
                  small: true,
                  onPressed: onViewDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostTripSuccessScreen extends StatelessWidget {
  const PostTripSuccessScreen({super.key, required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackLink(fallbackRoute: '/traveler-home'),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check, size: 40, color: AppColors.success),
                    ),
                    const SizedBox(height: 20),
                    Text('Trip posted!', style: typo.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Your $route trip is now discoverable to senders and matched by route similarity.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'View sender requests',
                      onPressed: () => context.go('/matching-requests'),
                    ),
                    const SizedBox(height: AppButton.stackGap),
                    AppButton(
                      label: 'Back to home',
                      variant: AppButtonVariant.outline,
                      onPressed: () => context.go('/traveler-home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
