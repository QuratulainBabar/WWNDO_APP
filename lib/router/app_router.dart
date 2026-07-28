import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/auth_screens.dart';
import '../features/onboarding/biometric_screens.dart';
import '../features/onboarding/forgot_password_screens.dart';
import '../features/onboarding/kyc_screens.dart';
import '../features/onboarding/kyc_id_capture_screens.dart';
import '../features/onboarding/kyc_selfie_screens.dart';
import '../features/onboarding/kyc_flow_data.dart';
import '../features/onboarding/otp_login_screens.dart';
import '../features/onboarding/login_otp_verification_screen.dart';
import '../features/onboarding/account_verification_screens.dart';
import '../features/onboarding/role_selection_screen.dart';
import '../features/onboarding/splash_welcome_screens.dart';
import '../features/profile/profile_screens.dart';
import '../features/profile/security_logs_screen.dart';
import '../features/profile/settings_flow_screens.dart';
import '../features/profile/wallet_top_up_screen.dart';
import '../features/receiver/receiver_home_screen.dart';
import '../features/receiver/receiver_shell.dart';
import '../features/receiver/receiver_screens.dart';
import '../features/receiver/incoming_parcel_request_screen.dart';
import '../features/receiver/receiver_payment_screen.dart';
import '../features/receiver/receiver_payment_success_screen.dart';
import '../features/sender/bid_acceptance_payment_screen.dart';
import '../features/sender/bid_payment_success_screen.dart';
import '../features/sender/bid_accepted_screen.dart';
import '../features/sender/bid_requests_screen.dart';
import '../features/sender/bid_traveler_profile_screen.dart';
import '../features/sender/counter_offer_detail_screen.dart';
import '../features/sender/traveler_selected_confirmation_screen.dart';
import '../features/sender/negotiate_meetup_screen.dart';
import '../features/sender/discover_travelers_screen.dart';
import '../features/sender/discover_trip_detail_screen.dart';
import '../features/sender/sender_chat_screen.dart';
import '../features/sender/country_to_country_post_delivery_screen.dart';
import '../features/sender/add_meetup_locations_screen.dart';
import '../data/models/meetup_location.dart';
import '../features/sender/post_delivery_screen.dart';
import '../features/sender/delivery_type_selection_screen.dart';
import '../features/sender/edit_posted_delivery_screen.dart';
import '../features/sender/cancel_posted_delivery_screen.dart';
import '../features/sender/my_posted_parcels_screen.dart';
import '../features/sender/sender_notifications_screen.dart';
import '../features/sender/sender_parcel_waiting_screen.dart';
import '../features/sender/sender_screens.dart';
import '../data/models/bid.dart';
import '../data/models/parcel_creation_result.dart';
import '../data/static_data.dart';
import '../data/models/shipment.dart';
import '../data/models/traveler_bid.dart';
import '../data/models/traveler_trip.dart';
import '../data/models/wallet_role.dart';
import '../features/tracking/tracking_screens.dart';
import '../features/traveler/traveler_home_screen.dart';
import '../features/traveler/traveler_my_trips_screen.dart';
import '../features/traveler/edit_trip_screen.dart';
import '../features/traveler/cancel_trip_screen.dart';
import '../features/traveler/traveler_profile_screen.dart';
import '../features/traveler/traveler_shell.dart';
import '../features/traveler/country_to_country_post_trip_screen.dart';
import '../features/traveler/post_trip_screen.dart';
import '../features/traveler/traveler_deliveries_screen.dart';
import '../features/traveler/traveler_screens.dart';
import '../features/traveler/trip_type_selection_screen.dart';
import '../features/traveler/bid_submitted_screen.dart';
import '../features/traveler/traveler_bid_detail_screen.dart';
import '../features/traveler/traveler_chat_screen.dart';
import '../features/traveler/traveler_my_bids_screen.dart';
import '../features/traveler/matching_requests_screen.dart';
import '../features/traveler/matching_requests_trips_screen.dart';
import '../features/traveler/parcel_request_detail_screen.dart';
import '../features/traveler/send_counter_offer_screen.dart';
import '../data/models/otp_channel.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorTrackKey = GlobalKey<NavigatorState>(debugLabel: 'track');
final _shellNavigatorChatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');
final _receiverShellHomeKey = GlobalKey<NavigatorState>(debugLabel: 'receiverHome');
final _receiverShellShipmentsKey = GlobalKey<NavigatorState>(debugLabel: 'receiverShipments');
final _receiverShellChatKey = GlobalKey<NavigatorState>(debugLabel: 'receiverChat');
final _receiverShellNotificationsKey = GlobalKey<NavigatorState>(debugLabel: 'receiverNotifications');
final _receiverShellProfileKey = GlobalKey<NavigatorState>(debugLabel: 'receiverProfile');
final _travelerShellHomeKey = GlobalKey<NavigatorState>(debugLabel: 'travelerHome');
final _travelerShellTripsKey = GlobalKey<NavigatorState>(debugLabel: 'travelerTrips');
final _travelerShellAlertsKey = GlobalKey<NavigatorState>(debugLabel: 'travelerAlerts');
final _travelerShellChatKey = GlobalKey<NavigatorState>(debugLabel: 'travelerChat');
final _travelerShellProfileKey = GlobalKey<NavigatorState>(debugLabel: 'travelerProfile');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(
      path: '/login/verify-otp',
      builder: (_, state) => LoginOtpVerificationScreen(
        flow: state.extra! as PasswordLoginOtpFlowData,
      ),
    ),
    GoRoute(path: '/login/otp-contact', builder: (_, __) => const OtpLoginContactScreen()),
    GoRoute(
      path: '/login/otp',
      builder: (_, state) => OtpLoginVerifyScreen(flow: state.extra! as OtpLoginFlowData),
    ),
    GoRoute(path: '/verify-account', builder: (_, __) => const AccountVerificationScreen()),
    GoRoute(
      path: '/verify-account/otp',
      builder: (_, state) {
        final extra = state.extra;
        final flow = extra is CrossVerificationOtpFlow
            ? extra
            : CrossVerificationOtpFlow(channel: extra! as OtpChannel);
        return CrossVerificationOtpScreen(flow: flow);
      },
    ),
    GoRoute(path: '/biometric/setup', builder: (_, __) => const BiometricSetupScreen()),
    GoRoute(path: '/biometric/login', builder: (_, __) => const BiometricLoginScreen()),
    GoRoute(
      path: '/biometric/success',
      builder: (_, state) => BiometricSuccessScreen(
        fromSetup: state.extra == true,
      ),
    ),
    GoRoute(
      path: '/biometric/unavailable',
      builder: (_, state) => BiometricUnavailableScreen(
        message: state.extra as String?,
      ),
    ),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(
      path: '/forgot-password/otp',
      builder: (_, state) => OtpVerificationScreen(
        flow: state.extra! as ForgotPasswordFlowData,
      ),
    ),
    GoRoute(
      path: '/forgot-password/reset',
      builder: (_, state) => ResetPasswordScreen(
        flow: state.extra! as ForgotPasswordFlowData,
      ),
    ),
    GoRoute(
      path: '/forgot-password/success',
      builder: (_, state) => PasswordResetSuccessScreen(
        flow: state.extra! as ForgotPasswordFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc',
      builder: (_, state) => KycVerificationScreen(
        initialFlow: state.extra as KycFlowData?,
      ),
    ),
    GoRoute(
      path: '/kyc/id-document',
      builder: (_, state) => KycDocumentTypeScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/id-capture',
      builder: (_, state) {
        final args = state.extra! as KycCaptureRouteArgs;
        return KycDocumentCaptureScreen(flow: args.flow, side: args.side);
      },
    ),
    GoRoute(
      path: '/kyc/id-preview',
      builder: (_, state) {
        final args = state.extra! as KycPreviewRouteArgs;
        return KycDocumentPreviewScreen(
          flow: args.flow,
          side: args.side,
          imagePath: args.imagePath,
        );
      },
    ),
    GoRoute(
      path: '/kyc/id-complete',
      builder: (_, state) => KycIdCompleteScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/selfie',
      builder: (_, state) => KycSelfieIntroScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/selfie/liveness',
      builder: (_, state) => KycLivenessCheckScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/selfie/capture',
      builder: (_, state) => KycSelfieCaptureScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/selfie/preview',
      builder: (_, state) {
        final args = state.extra! as KycSelfiePreviewRouteArgs;
        return KycSelfiePreviewScreen(
          flow: args.flow,
          imagePath: args.imagePath,
        );
      },
    ),
    GoRoute(
      path: '/kyc/selfie/processing',
      builder: (_, state) => KycSelfieProcessingScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(
      path: '/kyc/selfie/complete',
      builder: (_, state) => KycSelfieCompleteScreen(
        flow: state.extra! as KycFlowData,
      ),
    ),
    GoRoute(path: '/kyc-approved', builder: (_, __) => const KycApprovedScreen()),
    GoRoute(path: '/kyc-pending-review', builder: (_, __) => const KycPendingReviewScreen()),
    GoRoute(path: '/kyc-rejected', builder: (_, __) => const KycRejectedScreen()),
    GoRoute(path: '/account-suspended', builder: (_, __) => const AccountSuspendedScreen()),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ReceiverShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _receiverShellHomeKey,
          routes: [
            GoRoute(
              path: '/receiver-home',
              builder: (_, __) => const ReceiverHomeScreen(),
              routes: [
                GoRoute(
                  path: 'payment-approval',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (_, state) => ReceiverPaymentScreen(
                    shipment: state.extra as Shipment?,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _receiverShellShipmentsKey,
          routes: [
            GoRoute(path: '/receiver-shipments', builder: (_, __) => const ReceiverShipmentsScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _receiverShellChatKey,
          routes: [
            GoRoute(
              path: '/receiver-chats',
              builder: (_, __) => const ChatListScreen(
                role: WalletRole.receiver,
                chatBasePath: '/receiver-chats',
              ),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  builder: (context, state) => _inboxChatScreen(
                    role: WalletRole.receiver,
                    conversationId: state.pathParameters['conversationId']!,
                    backFallback: '/receiver-chats',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _receiverShellNotificationsKey,
          routes: [
            GoRoute(path: '/receiver-notifications', builder: (_, __) => const ReceiverNotificationsScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _receiverShellProfileKey,
          routes: [
            GoRoute(path: '/receiver-profile', builder: (_, __) => const ReceiverProfileScreen()),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/receiver-chat',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (_, __) => '/receiver-chats',
    ),
    GoRoute(
      path: '/receiver-incoming-request/:requestId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => IncomingParcelRequestScreen(
        requestId: state.pathParameters['requestId']!,
      ),
    ),
    GoRoute(
      path: '/receiver-tracking',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ReceiverTrackingScreen(
        shipmentId: state.uri.queryParameters['shipmentId'],
      ),
    ),
    GoRoute(
      path: '/receiver-nfc-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map) {
          return ReceiverNfcDeliverySuccessScreen(
            shipmentId: extra['shipmentId'] as String? ??
                StaticData.receiverActiveShipment.id,
            waitingForPeer: extra['waitingForPeer'] == true,
          );
        }
        return ReceiverNfcDeliverySuccessScreen(
          shipmentId: extra as String? ?? StaticData.receiverActiveShipment.id,
        );
      },
    ),
    GoRoute(
      path: '/receiver-payment-approval',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (_, __) => '/receiver-home/payment-approval',
    ),
    GoRoute(
      path: '/receiver-payment-confirmed',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is ReceiverPaymentResult) {
          return ReceiverPaymentSuccessScreen(result: extra);
        }
        return ReceiverPaymentSuccessScreen(
          result: ReceiverPaymentResult(
            shipmentId: StaticData.receiverActiveShipment.id,
            feeAmount: extra as double? ?? StaticData.platformFeeShare,
          ),
        );
      },
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => TravelerShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _travelerShellHomeKey,
          routes: [
            GoRoute(path: '/traveler-home', builder: (_, __) => const TravelerHomeScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _travelerShellTripsKey,
          routes: [
            GoRoute(path: '/traveler-trips', builder: (_, __) => const TravelerMyTripsScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _travelerShellAlertsKey,
          routes: [
            GoRoute(
              path: '/traveler-notifications',
              builder: (_, __) => const TravelerNotificationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _travelerShellChatKey,
          routes: [
            GoRoute(
              path: '/traveler-chats',
              builder: (_, __) => const ChatListScreen(
                role: WalletRole.traveler,
                chatBasePath: '/traveler-chats',
              ),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  builder: (context, state) => _inboxChatScreen(
                    role: WalletRole.traveler,
                    conversationId: state.pathParameters['conversationId']!,
                    backFallback: '/traveler-chats',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _travelerShellProfileKey,
          routes: [
            GoRoute(path: '/traveler-profile', builder: (_, __) => const TravelerProfileScreen()),
          ],
        ),
      ],
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorTrackKey,
          routes: [
            GoRoute(path: '/track', builder: (_, __) => const MyShipmentsScreen()),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorChatKey,
          routes: [
            GoRoute(
              path: '/sender-chats',
              builder: (_, __) => const ChatListScreen(
                role: WalletRole.sender,
                chatBasePath: '/sender-chats',
              ),
              routes: [
                GoRoute(
                  path: ':conversationId',
                  builder: (context, state) => _inboxChatScreen(
                    role: WalletRole.sender,
                    conversationId: state.pathParameters['conversationId']!,
                    backFallback: '/sender-chats',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProfileKey,
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    ),

    GoRoute(
      path: '/delivery-type',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const DeliveryTypeSelectionScreen(),
    ),
    GoRoute(
      path: '/parcel/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final trip = state.extra is TravelerTrip
            ? state.extra as TravelerTrip
            : null;
        if (trip?.isCountryToCountry == true) {
          return CountryToCountryPostDeliveryScreen(initialTrip: trip);
        }
        return PostDeliveryScreen(initialTrip: trip);
      },
    ),
    GoRoute(
      path: '/post-delivery',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => PostDeliveryScreen(
        initialTrip: state.extra is TravelerTrip
            ? state.extra as TravelerTrip
            : null,
      ),
    ),
    GoRoute(
      path: '/post-delivery/country-to-country',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => CountryToCountryPostDeliveryScreen(
        initialTrip: state.extra is TravelerTrip
            ? state.extra as TravelerTrip
            : null,
      ),
    ),
    GoRoute(
      path: '/add-meetup-locations',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map) {
          final locations = extra['locations'];
          final max = extra['maxLocations'];
          final title = extra['title'];
          final searchHint = extra['searchHint'];
          return AddMeetupLocationsScreen(
            initialLocations: locations is List<MeetupLocation>
                ? locations
                : const <MeetupLocation>[],
            maxLocations: max is int ? max : 3,
            title: title is String && title.trim().isNotEmpty
                ? title.trim()
                : 'Meetup locations',
            searchHint: searchHint is String && searchHint.trim().isNotEmpty
                ? searchHint.trim()
                : 'Search meetup location',
            citySearch: extra['citySearch'] == true,
            airportSearch: extra['airportSearch'] == true,
          );
        }
        final initial =
            extra is List<MeetupLocation> ? extra : const <MeetupLocation>[];
        return AddMeetupLocationsScreen(initialLocations: initial);
      },
    ),
    GoRoute(
      path: '/post-delivery/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is ParcelCreationResult) {
          return PostDeliveryPostedSuccessScreen(result: extra);
        }
        return PostDeliveryPostedSuccessScreen(
          route: extra is String ? extra : StaticData.activeShipment.route,
        );
      },
    ),
    GoRoute(path: '/bids', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const BrowseBidsScreen()),
    GoRoute(
      path: '/bid-requests',
      redirect: (_, __) => '/bid-requests/${StaticData.defaultBidRequestsShipmentId}',
    ),
    GoRoute(
      path: '/bid-requests/:shipmentId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => BidRequestsScreen(
        shipmentId: state.pathParameters['shipmentId']!,
      ),
    ),
    GoRoute(
      path: '/my-posted-parcels',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MyPostedParcelsScreen(),
    ),
    GoRoute(
      path: '/sender-parcel-waiting/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => SenderParcelWaitingScreen(
        shipmentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/edit-posted-delivery/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => EditPostedDeliveryScreen(
        shipmentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/cancel-posted-delivery/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => CancelPostedDeliveryScreen(
        shipmentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/discover-travelers',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const DiscoverTravelersScreen(),
    ),
    GoRoute(
      path: '/discover-travelers/:shipmentId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => DiscoverTravelersScreen(
        shipmentId: state.pathParameters['shipmentId'],
      ),
    ),
    GoRoute(
      path: '/discover-trips/:tripId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => DiscoverTripDetailScreen(
        tripId: state.pathParameters['tripId']!,
      ),
    ),
    GoRoute(
      path: '/sender-notifications',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const SenderNotificationsScreen(),
    ),
    GoRoute(
      path: '/sender-counter-offer/:offerId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => CounterOfferDetailScreen(
        offerId: state.pathParameters['offerId'],
        deliveryPublicId: state.uri.queryParameters['delivery'],
      ),
    ),
    GoRoute(
      path: '/sender-counter-offer',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => CounterOfferDetailScreen(
        deliveryPublicId: state.uri.queryParameters['delivery'],
      ),
    ),
    GoRoute(
      path: '/bid-traveler-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is BidAcceptanceContext) {
          return BidTravelerProfileScreen(
            bid: extra.bid,
            shipmentId: extra.shipmentId,
          );
        }
        return BidTravelerProfileScreen(bid: extra! as Bid);
      },
    ),
    GoRoute(
      path: '/traveler-selected-confirmation',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => TravelerSelectedConfirmationScreen(
        acceptance: state.extra! as BidAcceptanceContext,
      ),
    ),
    GoRoute(
      path: '/negotiate-meetup',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => NegotiateMeetupScreen(bid: state.extra! as Bid),
    ),
    GoRoute(
      path: '/bid-acceptance-payment',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => BidAcceptancePaymentScreen(
        acceptance: state.extra! as BidAcceptanceContext,
      ),
    ),
    GoRoute(
      path: '/bid-payment-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => BidPaymentSuccessScreen(
        acceptance: state.extra! as BidAcceptanceContext,
      ),
    ),
    GoRoute(
      path: '/bid-accepted',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => BidAcceptedScreen(bid: state.extra! as Bid),
    ),
    GoRoute(
      path: '/sender-chat',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (_, state) => state.uri.queryParameters['role'] == 'receiver'
          ? '/receiver-chats'
          : '/sender-chats',
    ),
    GoRoute(path: '/payment', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const EscrowPaymentScreen()),
    GoRoute(path: '/payment-confirmed', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const PaymentConfirmedScreen()),
    GoRoute(
      path: '/trip-type',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TripTypeSelectionScreen(),
    ),
    GoRoute(path: '/post-trip', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const PostTripScreen()),
    GoRoute(
      path: '/post-trip/country-to-country',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const CountryToCountryPostTripScreen(),
    ),
    GoRoute(
      path: '/post-trip/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => PostTripSuccessScreen(
        route: state.extra as String? ?? StaticData.deliveryRequests.first.route,
      ),
    ),
    GoRoute(
      path: '/edit-trip/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => EditTripScreen(
        tripId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/cancel-trip/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => CancelTripScreen(
        tripId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(path: '/browse-requests', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const BrowseRequestsScreen()),
    GoRoute(
      path: '/matching-requests',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const MatchingRequestsTripsScreen(),
    ),
    GoRoute(
      path: '/matching-requests/:tripId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => MatchingRequestsScreen(
        tripId: state.pathParameters['tripId']!,
      ),
    ),
    GoRoute(
      path: '/request/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ParcelRequestDetailScreen(
        requestId: state.pathParameters['id']!,
      ),
      routes: [
        GoRoute(
          path: 'counter-offer',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, state) => SendCounterOfferScreen(
            requestId: state.pathParameters['id']!,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/shipment/:id',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final isTravelerView =
            state.uri.queryParameters['traveler'] == 'true';
        if (isTravelerView) return null;

        final shipmentId = state.pathParameters['id'];
        if (shipmentId == null) return null;

        final shipment = StaticData.shipmentById(shipmentId);
        if (shipment == null) return null;
        if (StaticData.canAccessSenderParcelTracking(shipment)) return null;

        return StaticData.senderParcelOpenRoute(shipmentId);
      },
      builder: (_, state) => ShipmentDetailScreen(
        shipmentId: state.pathParameters['id']!,
        isTravelerView: state.uri.queryParameters['traveler'] == 'true',
      ),
    ),
    GoRoute(
      path: '/traveler-deliveries',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TravelerDeliveriesScreen(),
    ),
    GoRoute(
      path: '/traveler-bids',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const TravelerMyBidsScreen(),
    ),
    GoRoute(
      path: '/traveler-bid-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => TravelerBidDetailScreen(
        offerId: state.pathParameters['id'],
        bid: state.extra is TravelerBid ? state.extra as TravelerBid : null,
      ),
    ),
    GoRoute(
      path: '/traveler-bid-detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => TravelerBidDetailScreen(
        bid: state.extra is TravelerBid ? state.extra as TravelerBid : null,
      ),
    ),
    GoRoute(
      path: '/traveler-chat',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (_, state) =>
          state.uri.queryParameters['role'] == 'receiver'
              ? '/receiver-chats'
              : '/traveler-chats',
    ),
    GoRoute(
      path: '/traveler-nfc-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map) {
          return TravelerNfcDeliverySuccessScreen(
            shipmentId: extra['shipmentId'] as String? ??
                StaticData.travelerActiveDelivery.id,
            waitingForPeer: extra['waitingForPeer'] == true,
          );
        }
        return TravelerNfcDeliverySuccessScreen(
          shipmentId: extra as String? ?? StaticData.travelerActiveDelivery.id,
        );
      },
    ),
    GoRoute(
      path: '/nfc-confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map) {
          return NfcConfirmScreen(
            shipmentId: extra['shipmentId'] as String?,
            checkpoint: (extra['checkpoint'] as num?)?.toInt() ?? 1,
            isTraveler: extra['isTraveler'] == true,
          );
        }
        return NfcConfirmScreen(shipmentId: extra as String?);
      },
    ),
    GoRoute(
      path: '/nfc-confirm/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final extra = state.extra;
        if (extra is Map) {
          return NfcConfirmSuccessScreen(
            shipmentId: extra['shipmentId'] as String? ?? StaticData.activeShipment.id,
            isTraveler: extra['isTraveler'] == true,
            waitingForPeer: extra['waitingForPeer'] == true,
          );
        }
        return NfcConfirmSuccessScreen(
          shipmentId: extra as String? ?? StaticData.activeShipment.id,
        );
      },
    ),
    GoRoute(
      path: '/dispute-form/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => DisputeFormScreen(shipmentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/dispute/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => DisputeScreen(
        shipmentId: state.pathParameters['id']!,
        reason: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/contact-support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ContactSupportScreen(
        shipmentId: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/contact-support/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ContactSupportSuccessScreen(
        shipmentId: state.extra as String?,
      ),
    ),
    GoRoute(path: '/delivery-review', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const DeliveryReviewScreen()),
    GoRoute(
      path: '/delivery-review/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final data = state.extra! as ReviewSubmittedRouteData;
        return ReviewSubmittedSuccessScreen(
          shipmentId: data.shipmentId,
          rating: data.rating,
        );
      },
    ),
    GoRoute(
      path: '/chat',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (_, __) => '/sender-chats',
    ),
    GoRoute(path: '/settings', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/wallet', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const WalletScreen()),
    GoRoute(
      path: '/wallet/top-up',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const WalletTopUpScreen(),
    ),
    GoRoute(
      path: '/wallet/top-up/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => WalletTopUpSuccessScreen(
        amountCents: (state.extra as int?) ?? 2500,
      ),
    ),
    GoRoute(path: '/shipment-history', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const ShipmentHistoryScreen()),
    GoRoute(path: '/transaction-history', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const TransactionHistoryScreen()),
    GoRoute(
      path: '/wallet/withdrawal-success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => WalletWithdrawalSuccessScreen(
        amount: (state.extra as num?)?.toDouble() ?? 50,
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => EditProfileScreen(
        role: editProfileRoleFromRoute(state),
      ),
    ),
    GoRoute(
      path: '/edit-profile/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) => ProfileUpdatedSuccessScreen(
        role: state.extra is EditProfileRole
            ? state.extra as EditProfileRole
            : state.extra == true
                ? EditProfileRole.receiver
                : EditProfileRole.sender,
      ),
    ),
    GoRoute(path: '/change-password', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const ChangePasswordScreen()),
    GoRoute(
      path: '/change-password/success',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __) => const ChangePasswordSuccessScreen(),
    ),
    GoRoute(path: '/legal/terms', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const TermsPrivacyScreen()),
    GoRoute(path: '/kyc-status', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const KycStatusScreen()),
    GoRoute(path: '/security-logs', parentNavigatorKey: _rootNavigatorKey, builder: (_, __) => const SecurityLogsScreen()),
    GoRoute(
      path: '/bid-submitted',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, state) {
        final data = state.extra! as Map<String, dynamic>;
        return BidSubmittedScreen(
          route: data['route'] as String,
          price: (data['price'] as num).toDouble(),
          tripId: data['tripId'] as String? ??
              state.uri.queryParameters['tripId'],
        );
      },
    ),
  ],
);

Widget _inboxChatScreen({
  required WalletRole role,
  required String conversationId,
  required String backFallback,
}) {
  switch (role) {
    case WalletRole.sender:
      return SenderChatScreen(
        backFallback: backFallback,
        conversationId: conversationId,
      );
    case WalletRole.traveler:
      final conversation =
          StaticData.chatConversationById(role, conversationId);
      final name = conversation?.name ?? 'Contact';
      final initial = conversation?.initial ?? 'C';
      final shipmentId =
          conversation?.shipmentId ?? StaticData.activeShipment.id;
      return TravelerChatScreen(
        bid: TravelerBid(
          id: 'inbox-$conversationId',
          requestId: shipmentId,
          tripId: 'trip-inbox',
          senderName: name,
          senderInitial: initial,
          fromCity: 'Paris',
          toCity: 'Dakar',
          deliveryDate: DateTime.now(),
          amount: 28,
          status: TravelerBidStatus.accepted,
        ),
        backFallback: backFallback,
      );
    case WalletRole.receiver:
      return ReceiverChatScreen(
        backFallback: backFallback,
        conversationId: conversationId,
      );
  }
}
