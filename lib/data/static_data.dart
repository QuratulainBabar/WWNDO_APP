import 'package:flutter/foundation.dart';

import 'models/auth_user.dart';
import 'models/bid.dart';
import 'models/chat_conversation_preview.dart';
import 'models/chat_message.dart';
import 'models/delivery_request.dart';
import 'models/matching_request.dart';
import 'models/hot_route.dart';
import 'models/incoming_parcel_request.dart';
import 'models/receiver_notification.dart';
import 'notification_service.dart';
import 'models/app_notification.dart';
import 'models/final_budget_proposal.dart';
import 'models/review.dart';
import 'models/shipment.dart';
import 'models/user.dart';
import 'models/traveler_bid.dart';
import 'models/traveler_trip.dart';
import 'models/wallet_transaction.dart';
import 'models/wallet_role.dart';
import 'route_similarity.dart';
import 'trip_creation_wallet_validation.dart';
import 'wallet_service.dart';
import 'models/verified_recipient.dart';
import 'models/parcel_creation_result.dart';
import 'models/profile_trust_metrics.dart';
import 'models/security_log_entry.dart';

/// Static data repository — replace with API layer later.
abstract final class StaticData {
  static const demoPassword = 'password123';

  static const currentUser = UserProfile(
    name: 'Marc Leblanc',
    email: 'marc@email.com',
    phone: '+33 612 345 678',
    countryCode: 'FR',
    rating: 4.9,
    reviewCount: 18,
    walletBalance: 0,
    memberSince: 'May 2026',
    bio: 'Sending parcels between Europe and West Africa 🌍',
    isVerified: true,
  );

  static AuthUser get demoAuthUser {
    const profile = currentUser;
    return AuthUser(
      id: 'demo-user-1',
      name: profile.name,
      email: profile.email,
      phone: profile.phone,
      countryCode: profile.countryCode,
      bio: profile.bio,
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      walletBalance: profile.walletBalance,
      memberSince: profile.memberSince,
      isVerified: false,
      kycStatus: 'approved',
      accountStatus: 'active',
      emailVerified: false,
      phoneVerified: false,
    );
  }

  static const countryCodes = ['FR', 'US', 'GB', 'NG', 'AE', 'CA', 'SN'];

  static const parcelCategories = ['documents', 'objects'];
  static const parcelSizes = ['envelope', 'small box', 'medium box', 'large bag'];
  static const requestFilters = ['All', 'Document', 'Object'];

  static const hotRoutes = [
    HotRoute(fromCity: 'Paris', toCity: 'Dakar', travelerCount: 12, fromPrice: 18),
    HotRoute(fromCity: 'London', toCity: 'Lagos', travelerCount: 9, fromPrice: 22),
    HotRoute(fromCity: 'Dubai', toCity: 'Casablanca', travelerCount: 6, fromPrice: 30),
  ];

  static const countryToCountryOriginCountry = 'France';
  static const countryToCountryOriginAirport = 'Paris Charles de Gaulle (CDG)';
  static const countryToCountryDestinationCountry = 'Senegal';
  static const countryToCountryDestinationAirport = 'Blaise Diagne (DSS)';

  static final activeShipment = Shipment(
    id: 'WW-48291',
    fromCity: 'Paris',
    toCity: 'Dakar',
    fromCode: 'FR',
    toCode: 'SN',
    travelDate: DateTime(2026, 7, 26), // ≥24h from demo "today" → fee refund on cancel
    status: ShipmentStatus.bidAccepted,
    role: ShipmentRole.sender,
    parcelCategory: 'Documents',
    parcelWeightKg: 0.8,
    parcelSize: 'small box',
    description: 'Legal documents for notary office',
    travelerName: 'Aissatou D.',
    flightNumber: 'AF718',
  );

  /// Pending bid counts for sender parcels awaiting bid acceptance (static demo data).
  static final senderPendingBidCounts = <String, int>{
    'WW-27490': 3,
    'WW-35102': 2,
    'WW-56230': 1,
  };

  /// Frontend-only: parcels whose receiver has accepted the request.
  /// Shipments not listed (and still [ShipmentStatus.open]) show as waiting for receiver.
  static final receiverAcceptedShipmentIds = <String>{
    'WW-27490',
    'WW-35102',
  };

  /// Frontend-only: travelers the sender sent requests to while awaiting acceptance.
  /// Multiple travelers may be selected per shipment (1 or more).
  static final selectedMatchingTravelerByShipmentId = <String, List<Bid>>{};

  static bool _matchingFlowSeeded = false;

  static void _ensureMatchingFlowSeeds() {
    if (_matchingFlowSeeded) return;
    _matchingFlowSeeded = true;
    final bids = bidRequestsForShipment('WW-35102');
    if (bids.isNotEmpty) {
      selectedMatchingTravelerByShipmentId.putIfAbsent(
        'WW-35102',
        () => [bids.first],
      );
      // Demo: traveler already accepted → open details → Payment Summary → Pay Now.
      _bidReviewStatusById.putIfAbsent(
        bids.first.id,
        () => BidReviewStatus.approved,
      );
    }
  }

  /// Travelers the sender has already sent a request to for [shipmentId].
  static List<Bid> selectedMatchingTravelersFor(String shipmentId) =>
      List<Bid>.unmodifiable(
        selectedMatchingTravelerByShipmentId[shipmentId] ?? const <Bid>[],
      );

  /// Preferred selected traveler for pay/waiting UI (accepted first, else first request).
  static Bid? selectedMatchingTravelerFor(String shipmentId) {
    final selected = selectedMatchingTravelerByShipmentId[shipmentId];
    if (selected == null || selected.isEmpty) return null;
    for (final bid in selected) {
      final review = bidReviewStatus(bid.id);
      if (review == BidReviewStatus.approved ||
          review == BidReviewStatus.accepted) {
        return bid;
      }
    }
    return selected.first;
  }

  /// Sender list phase for My Posted Deliveries badges (frontend-only).
  static SenderPostedPhase? senderPostedPhase(Shipment parcel) {
    _ensureMatchingFlowSeeds();
    final status = effectiveStatus(parcel);

    // Active / confirmed shipments: map old status labels to new flow wording.
    if (status != ShipmentStatus.open) {
      return switch (status) {
        ShipmentStatus.receiverAccepted => null,
        ShipmentStatus.bidAccepted ||
        ShipmentStatus.photosUploaded =>
          SenderPostedPhase.travelerSelected,
        ShipmentStatus.collected ||
        ShipmentStatus.inTransit =>
          SenderPostedPhase.travelerSelected,
        ShipmentStatus.delivered ||
        ShipmentStatus.disputed ||
        ShipmentStatus.open =>
          null,
      };
    }

    final selected = selectedMatchingTravelerByShipmentId[parcel.id];
    if (selected != null && selected.isNotEmpty) {
      final anyAccepted = selected.any((bid) {
        final review = bidReviewStatus(bid.id);
        return review == BidReviewStatus.approved ||
            review == BidReviewStatus.accepted;
      });
      if (anyAccepted) return SenderPostedPhase.travelerAccepted;
      return SenderPostedPhase.travelerReviewing;
    }
    if (receiverAcceptedShipmentIds.contains(parcel.id)) {
      return SenderPostedPhase.matchingTravelers;
    }
    return SenderPostedPhase.waitingForReceiver;
  }

  /// Count of matching travelers available for a posted delivery (frontend demo).
  static int matchingTravelerCountForShipment(String shipmentId) =>
      openBidRequestsForShipment(shipmentId).length;

  static String senderPostedBadgeLabel(SenderPostedPhase phase, String shipmentId) {
    if (phase == SenderPostedPhase.matchingTravelers) {
      final count = matchingTravelerCountForShipment(shipmentId);
      return count > 0 ? 'Matching Travelers ($count)' : 'Matching Travelers';
    }
    return phase.badgeLabel;
  }

  /// Parcel Tracking is only for confirmed/active sender shipments.
  /// Blocked until receiver accepts, sender selects a traveler, and the traveler
  /// accepts (or the shipment leaves [ShipmentStatus.open]).
  static bool canAccessSenderParcelTracking(Shipment shipment) {
    final status = effectiveStatus(shipment);
    if (status != ShipmentStatus.open) return true;

    final phase = senderPostedPhase(shipment);
    return phase == SenderPostedPhase.travelerAccepted;
  }

  /// Sender open route: tracking when allowed, otherwise the matching intermediate screen.
  static String senderParcelOpenRoute(String shipmentId) {
    final shipment = shipmentById(shipmentId);
    if (shipment == null) return '/my-posted-parcels';
    if (canAccessSenderParcelTracking(shipment)) {
      return '/shipment/$shipmentId';
    }

    final phase = senderPostedPhase(shipment);
    return switch (phase) {
      // Stay on Matching Travelers while requests are pending so more
      // travelers can still be requested.
      SenderPostedPhase.matchingTravelers ||
      SenderPostedPhase.travelerReviewing =>
        '/bid-requests/$shipmentId',
      SenderPostedPhase.waitingForReceiver =>
        '/sender-parcel-waiting/$shipmentId',
      SenderPostedPhase.travelerAccepted ||
      SenderPostedPhase.travelerSelected ||
      null =>
        '/my-posted-parcels',
    };
  }

  /// Sender sends a parcel request to a matching traveler.
  /// Multiple travelers may be requested; others stay available (not locked).
  /// Demo mode: traveler auto-accepts so the sender can pay and continue the flow.
  static void selectMatchingTraveler({
    required String shipmentId,
    required Bid bid,
  }) {
    final selected =
        selectedMatchingTravelerByShipmentId.putIfAbsent(shipmentId, () => []);
    if (!selected.any((b) => b.id == bid.id)) {
      selected.add(bid);
    }
    receiverAcceptedShipmentIds.add(shipmentId);
    _bidReviewStatusById[bid.id] = BidReviewStatus.approved;
    bidRequestsVersion.value++;
  }

  /// Frontend-only: traveler final budget proposals awaiting sender review.
  static final finalBudgetProposalsByShipmentId = <String, FinalBudgetProposal>{
    'WW-35102': const FinalBudgetProposal(
      shipmentId: 'WW-35102',
      bidId: 'bid-req-35102-1',
      travelerName: 'Ama Serwaa',
      originalBudgetUsd: 30,
      proposedBudgetUsd: 34,
    ),
  };

  static FinalBudgetProposal? finalBudgetProposalFor(String shipmentId) =>
      finalBudgetProposalsByShipmentId[shipmentId];

  static Bid? bidById(String bidId) {
    for (final bids in bidRequestsByShipmentId.values) {
      for (final bid in bids) {
        if (bid.id == bidId) return bid;
      }
    }
    return null;
  }

  /// Resolves the sender parcel id for a traveler matching request.
  static String resolveShipmentIdForRequest(DeliveryRequest request) {
    final fromMatchWw = RegExp(r'^match-(WW-[\w-]+)-').firstMatch(request.id);
    if (fromMatchWw != null) return fromMatchWw.group(1)!;
    if (request.id.startsWith('WW-')) return request.id;

    for (final shipment in senderShipments) {
      if (shipment.status != ShipmentStatus.open) continue;
      if (shipment.fromCity == request.fromCity &&
          shipment.toCity == request.toCity) {
        return shipment.id;
      }
    }

    return _ensureShipmentForMatchingRequest(request);
  }

  static String _ensureShipmentForMatchingRequest(DeliveryRequest request) {
    final id =
        'WW-${request.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase()}';
    if (shipmentById(id) == null) {
      senderShipments.insert(
        0,
        Shipment(
          id: id,
          fromCity: request.fromCity,
          toCity: request.toCity,
          fromCode: request.fromCity.length >= 2
              ? request.fromCity.substring(0, 2).toUpperCase()
              : 'XX',
          toCode: request.toCity.length >= 2
              ? request.toCity.substring(0, 2).toUpperCase()
              : 'XX',
          travelDate: request.travelDate,
          status: ShipmentStatus.open,
          role: ShipmentRole.sender,
          parcelCategory: request.category,
          parcelWeightKg: request.weightKg,
          parcelSize: request.size,
          description: request.description,
        ),
      );
      receiverAcceptedShipmentIds.add(id);
    }
    return id;
  }

  /// Traveler sends a final budget (same as sender budget or a counter-offer).
  /// Persists the proposal, upserts a sender-side [Bid], and notifies the sender.
  /// Returns an error message, or null on success.
  static String? sendTravelerFinalBudget({
    required DeliveryRequest request,
    required String tripId,
    required double amount,
    AuthUser? authUser,
    bool allowAboveMaxBudget = false,
  }) {
    if (amount <= 0) return 'Enter a valid budget amount.';
    if (!allowAboveMaxBudget && amount > request.maxBudget) {
      return 'Bid cannot exceed sender max budget (\$${request.maxBudget.toStringAsFixed(2)}).';
    }

    final balance = WalletService.availableUsd(WalletRole.traveler);
    if (balance < travelerBidMinBalanceUsd) {
      return 'Wallet must have at least \$${travelerBidMinBalanceUsd.toStringAsFixed(0)} to send a final budget.';
    }

    if (tripId.isNotEmpty) {
      final trip = travelerTripById(tripId);
      if (trip == null) return 'Trip route is required for this bid.';
      final score = RouteSimilarity.scoreTripToRequest(trip, request);
      if (score < 50) {
        return 'Bid route is not compatible with this parcel request.';
      }
    } else {
      final compatibleTrip = compatibleTripForRequest(request);
      if (compatibleTrip == null) {
        return 'No compatible posted trip found for this route.';
      }
    }

    final shipmentId = resolveShipmentIdForRequest(request);
    final travelerName = (authUser?.name.trim().isNotEmpty == true)
        ? authUser!.name.trim()
        : currentUser.name;
    final initial = travelerName.isNotEmpty ? travelerName[0].toUpperCase() : 'T';
    final matchScore = matchingRequestById(request.id)?.matchScore ?? 90;

    // Record / revise traveler-side counter offer (My Bids).
    final existingTravelerBid = travelerBidForRequest(request.id);
    if (existingTravelerBid == null) {
      travelerBids.add(
        TravelerBid(
          id: 'tb-$_nextTravelerBidId',
          requestId: request.id,
          tripId: tripId,
          senderName: request.senderName,
          senderInitial: request.senderInitial,
          fromCity: request.fromCity,
          toCity: request.toCity,
          deliveryDate: request.travelDate,
          amount: amount,
          status: TravelerBidStatus.pending,
          sentAt: DateTime.now(),
          parcelPhotoCount: request.photoCount,
        ),
      );
      _nextTravelerBidId++;
      travelerBidsVersion.value++;
    } else if (existingTravelerBid.status == TravelerBidStatus.pending ||
        existingTravelerBid.status == TravelerBidStatus.updated) {
      final index = travelerBids.indexWhere((b) => b.id == existingTravelerBid.id);
      if (index >= 0) {
        travelerBids[index] = TravelerBid(
          id: existingTravelerBid.id,
          requestId: existingTravelerBid.requestId,
          tripId: existingTravelerBid.tripId,
          senderName: existingTravelerBid.senderName,
          senderInitial: existingTravelerBid.senderInitial,
          fromCity: existingTravelerBid.fromCity,
          toCity: existingTravelerBid.toCity,
          deliveryDate: existingTravelerBid.deliveryDate,
          amount: amount,
          status: TravelerBidStatus.updated,
          sentAt: DateTime.now(),
          parcelPhotoCount: existingTravelerBid.parcelPhotoCount,
          deliveryPublicId: existingTravelerBid.deliveryPublicId,
        );
        travelerBidsVersion.value++;
      }
    }

    final existingProposal = finalBudgetProposalsByShipmentId[shipmentId];
    final bidId = existingProposal?.bidId ??
        'bid-final-$shipmentId-${DateTime.now().millisecondsSinceEpoch}';

    final bid = Bid(
      id: bidId,
      travelerName: travelerName,
      initial: initial,
      rating: authUser?.rating ?? currentUser.rating,
      reviewCount: authUser?.reviewCount ?? currentUser.reviewCount,
      price: amount,
      travelDate: request.travelDate,
      routeMatchConfidence: matchScore,
      message: allowAboveMaxBudget
          ? 'Final budget proposal (counter-offer).'
          : 'Accepted sender budget as final.',
      featured: true,
    );

    final list =
        bidRequestsByShipmentId.putIfAbsent(shipmentId, () => <Bid>[]);
    final existingIndex = list.indexWhere((b) => b.id == bidId);
    if (existingIndex >= 0) {
      list[existingIndex] = bid;
    } else {
      list.insert(0, bid);
    }
    _bidReviewStatusById[bidId] = BidReviewStatus.deliveryRequested;

    finalBudgetProposalsByShipmentId[shipmentId] = FinalBudgetProposal(
      shipmentId: shipmentId,
      bidId: bidId,
      travelerName: travelerName,
      originalBudgetUsd: request.maxBudget,
      proposedBudgetUsd: amount,
    );

    NotificationService.push(
      AppNotification(
        id: 'snd-final-budget-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.sender,
        type: AppNotificationType.counterOffer,
        title: 'Counter offer sent by traveler',
        body:
            '$travelerName sent a counter offer of \$${amount.toStringAsFixed(2)} for $shipmentId. Review parcel details to accept.',
        time: 'Just now',
        route: '/shipment/$shipmentId',
      ),
    );

    bidRequestsVersion.value++;
    return null;
  }

  /// Sender accepts the traveler's final proposed budget (frontend demo).
  static FinalBudgetProposal? acceptFinalBudgetProposal(String shipmentId) {
    final current = finalBudgetProposalsByShipmentId[shipmentId];
    if (current == null) return null;
    final updated = current.copyWith(accepted: true);
    finalBudgetProposalsByShipmentId[shipmentId] = updated;

    var bid = bidById(current.bidId);
    if (bid != null) {
      if (bid.price != current.proposedBudgetUsd) {
        bid = bid.copyWith(price: current.proposedBudgetUsd);
        final list = bidRequestsByShipmentId[shipmentId];
        if (list != null) {
          final index = list.indexWhere((b) => b.id == bid!.id);
          if (index >= 0) list[index] = bid;
        }
      }
      selectMatchingTraveler(shipmentId: shipmentId, bid: bid);
      _bidReviewStatusById[bid.id] = BidReviewStatus.approved;
    }
    bidRequestsVersion.value++;
    return updated;
  }

  /// Removes an open-bid posted delivery from demo/static sender lists.
  /// Returns `false` if the shipment is missing or within the 24h cancel window.
  static bool cancelOpenBidDelivery(String shipmentId) {
    final shipment = shipmentById(shipmentId);
    if (shipment == null) return false;
    if (!canSenderCancelBeforeTravel(shipment.travelDate)) return false;

    senderShipments.removeWhere((s) => s.id == shipmentId);
    senderPendingBidCounts.remove(shipmentId);
    receiverAcceptedShipmentIds.remove(shipmentId);
    selectedMatchingTravelerByShipmentId.remove(shipmentId);
    bidRequestsVersion.value++;
    return true;
  }

  /// Replaces a sender shipment in demo/static data (e.g. after edit).
  static void updateSenderShipment(Shipment updated) {
    final index = senderShipments.indexWhere((s) => s.id == updated.id);
    if (index < 0) return;
    senderShipments[index] = updated;
    bidRequestsVersion.value++;
  }

  /// Sender-only shipments (city-to-city and country-to-country) for profile stats.
  static final senderShipments = [
    activeShipment,
    Shipment(
      id: 'WW-27490',
      fromCity: 'Dubai',
      toCity: 'Casablanca',
      fromCode: 'AE',
      toCode: 'MA',
      travelDate: DateTime(2026, 6, 22),
      status: ShipmentStatus.open,
      role: ShipmentRole.sender,
      parcelCategory: 'Electronics',
      parcelWeightKg: 1.5,
      parcelSize: 'medium box',
    ),
    Shipment(
      id: 'WW-56230',
      fromCity: 'Madrid',
      toCity: 'Abidjan',
      fromCode: 'ES',
      toCode: 'CI',
      travelDate: DateTime(2026, 7, 20), // within 24h of demo "today" → sender cancel blocked
      status: ShipmentStatus.open,
      role: ShipmentRole.sender,
      parcelCategory: 'Electronics',
      parcelWeightKg: 1.1,
      parcelSize: 'small box',
    ),
    Shipment(
      id: 'WW-19847',
      fromCity: 'London',
      toCity: 'Lagos',
      fromCode: 'GB',
      toCode: 'NG',
      travelDate: DateTime(2026, 5, 20),
      status: ShipmentStatus.delivered,
      role: ShipmentRole.sender,
      parcelCategory: 'Clothing',
      parcelWeightKg: 2,
      parcelSize: 'small box',
      travelerName: 'Kofi M.',
      flightNumber: 'BA075',
    ),
  ];

  static int get senderActiveShipmentCount =>
      senderShipments.where((s) => s.status != ShipmentStatus.delivered).length;

  static int get senderCompletedShipmentCount =>
      senderShipments.where((s) => s.status == ShipmentStatus.delivered).length;

  static List<Shipment> get senderCompletedShipments =>
      senderShipments.where((s) => s.status == ShipmentStatus.delivered).toList();

  static const senderTransactions = [
    WalletTransaction(
      amount: 23.50,
      description: 'WW-48291 · Escrow payment',
      date: 'Jun 10',
      type: TransactionType.debit,
    ),
    WalletTransaction(
      amount: 35.00,
      description: 'WW-61023 · Escrow payment',
      date: 'Jun 5',
      type: TransactionType.debit,
    ),
    WalletTransaction(
      amount: 28.00,
      description: 'WW-19847 · Escrow payment',
      date: 'May 18',
      type: TransactionType.debit,
    ),
    WalletTransaction(
      amount: 42.00,
      description: 'WW-15902 · Escrow payment',
      date: 'Apr 2',
      type: TransactionType.debit,
    ),
    WalletTransaction(
      amount: 2.50,
      description: 'WW-15902 · Platform fee',
      date: 'Apr 2',
      type: TransactionType.debit,
    ),
  ];

  /// Traveler My Deliveries — Traveler Selected; full demo flow with [activeShipment].
  /// Same ID as sender [activeShipment] so both sides share NFC CP1/CP2 state.
  static final travelerActiveDelivery = Shipment(
    id: 'WW-48291',
    fromCity: 'Paris',
    toCity: 'Dakar',
    fromCode: 'FR',
    toCode: 'SN',
    travelDate: DateTime(2026, 6, 15),
    status: ShipmentStatus.bidAccepted,
    role: ShipmentRole.traveler,
    parcelCategory: 'Documents',
    parcelWeightKg: 0.8,
    parcelSize: 'small box',
    description: 'Legal documents for notary office',
    travelerName: 'Aissatou D.',
    flightNumber: 'AF718',
  );

  /// Traveler cancel demo — collected, <24h before flight (escrow refunded, fees kept).
  static final travelerCancelDemoNear = Shipment(
    id: 'WW-74012',
    fromCity: 'London',
    toCity: 'Dakar',
    fromCode: 'GB',
    toCode: 'SN',
    travelDate: DateTime.now().add(const Duration(hours: 12)),
    status: ShipmentStatus.collected,
    role: ShipmentRole.traveler,
    parcelCategory: 'Documents',
    parcelWeightKg: 0.9,
    parcelSize: 'small box',
    description: 'Cancel demo · collected <24h before flight',
    travelerName: 'Ibrahim K.',
    flightNumber: 'BA078',
  );

  static final shipments = [
    activeShipment,
    travelerActiveDelivery,
    travelerCancelDemoNear,
    Shipment(
      id: 'WW-27490',
      fromCity: 'Dubai',
      toCity: 'Casablanca',
      fromCode: 'AE',
      toCode: 'MA',
      travelDate: DateTime(2026, 6, 22),
      status: ShipmentStatus.open,
      role: ShipmentRole.sender,
      parcelCategory: 'Electronics',
      parcelWeightKg: 1.5,
      parcelSize: 'medium box',
    ),
    Shipment(
      id: 'WW-21883',
      fromCity: 'Paris',
      toCity: 'Abidjan',
      fromCode: 'FR',
      toCode: 'CI',
      travelDate: DateTime(2026, 5, 10),
      status: ShipmentStatus.delivered,
      role: ShipmentRole.traveler,
      parcelCategory: 'Documents',
      parcelWeightKg: 0.5,
      parcelSize: 'envelope',
    ),
  ];

  static final bids = [
    Bid(
      id: 'bid-1',
      travelerName: 'Aissatou D.',
      initial: 'A',
      rating: 4.9,
      reviewCount: 24,
      price: 18,
      travelDate: DateTime(2026, 6, 15),
      routeMatchConfidence: 95,
      flightNumber: 'AF718',
      message: 'I travel this route monthly and always have spare luggage.',
      featured: true,
      bio: 'I travel this route monthly and always have spare luggage space.',
      completedDeliveries: 24,
    ),
    Bid(
      id: 'bid-2',
      travelerName: 'Kofi M.',
      initial: 'K',
      rating: 4.7,
      reviewCount: 11,
      price: 22,
      travelDate: DateTime(2026, 6, 15),
      routeMatchConfidence: 88,
      bio: 'Happy to meet at the airport and hand-deliver carefully packed items.',
      completedDeliveries: 11,
    ),
    Bid(
      id: 'bid-3',
      travelerName: 'Sophie R.',
      initial: 'S',
      rating: 4.8,
      reviewCount: 7,
      price: 25,
      travelDate: DateTime(2026, 6, 16),
      routeMatchConfidence: 82,
      bio: 'Careful with electronics and documents. Experienced traveler.',
      completedDeliveries: 7,
    ),
  ];

  /// Static bid requests keyed by sender parcel ID.
  static final bidRequestsByShipmentId = <String, List<Bid>>{
    'WW-27490': [
      Bid(
        id: 'bid-req-1',
        travelerName: 'John Smith',
        initial: 'J',
        rating: 4.9,
        reviewCount: 31,
        price: 35,
        travelDate: DateTime(2026, 7, 25),
        routeMatchConfidence: 96,
        message: 'I am already travelling on this route and can safely deliver your parcel.',
        featured: true,
        bio: 'Frequent flyer between Europe and West Africa. Reliable hand-carry deliveries.',
        completedDeliveries: 47,
      ),
      Bid(
        id: 'bid-req-2',
        travelerName: 'Aissatou D.',
        initial: 'A',
        rating: 4.8,
        reviewCount: 24,
        price: 32,
        travelDate: DateTime(2026, 7, 24),
        routeMatchConfidence: 91,
        message: 'I travel this route monthly and always have spare luggage.',
        bio: 'I travel this route monthly and always have spare luggage space.',
        completedDeliveries: 24,
      ),
      Bid(
        id: 'bid-req-3',
        travelerName: 'Kofi M.',
        initial: 'K',
        rating: 4.7,
        reviewCount: 11,
        price: 38,
        travelDate: DateTime(2026, 7, 26),
        routeMatchConfidence: 84,
        message: 'Happy to hand-deliver at the airport meetup point.',
        bio: 'Happy to meet at the airport and hand-deliver carefully packed items.',
        completedDeliveries: 11,
      ),
    ],
    'WW-48291': [
      Bid(
        id: 'bid-req-48291-1',
        travelerName: 'Aissatou D.',
        initial: 'A',
        rating: 4.8,
        reviewCount: 24,
        price: 28,
        travelDate: DateTime(2026, 6, 14),
        routeMatchConfidence: 94,
        message: 'I can meet at CDG and deliver your documents safely to Dakar.',
        featured: true,
        bio: 'Frequent traveler Paris–Dakar with careful hand-carry handling.',
        completedDeliveries: 24,
      ),
      Bid(
        id: 'bid-req-48291-2',
        travelerName: 'Fatou B.',
        initial: 'F',
        rating: 4.6,
        reviewCount: 18,
        price: 30,
        travelDate: DateTime(2026, 6, 15),
        routeMatchConfidence: 88,
        message: 'Flying the same day — happy to carry sealed documents.',
        bio: 'Reliable Senegal route traveler.',
        completedDeliveries: 18,
      ),
    ],
    'WW-61023': [
      Bid(
        id: 'bid-req-61023-1',
        travelerName: 'Moussa T.',
        initial: 'M',
        rating: 4.8,
        reviewCount: 15,
        price: 35,
        travelDate: DateTime(2026, 6, 18),
        routeMatchConfidence: 93,
        message: 'I can deliver your notarized documents safely to Senegal.',
        featured: true,
        bio: 'Regular France–Senegal flyer.',
        completedDeliveries: 15,
      ),
      Bid(
        id: 'bid-req-61023-2',
        travelerName: 'Amadou K.',
        initial: 'A',
        rating: 4.5,
        reviewCount: 9,
        price: 33,
        travelDate: DateTime(2026, 6, 17),
        routeMatchConfidence: 86,
        message: 'Airport handoff works best for me — flexible on timing.',
        bio: 'Careful document carrier on West Africa routes.',
        completedDeliveries: 9,
      ),
      Bid(
        id: 'bid-req-61023-3',
        travelerName: 'Ibrahim S.',
        initial: 'I',
        rating: 4.9,
        reviewCount: 27,
        price: 40,
        travelDate: DateTime(2026, 6, 19),
        routeMatchConfidence: 90,
        message: 'Premium careful handling for legal papers.',
        bio: 'Experienced with notarized parcel handovers.',
        completedDeliveries: 27,
      ),
      Bid(
        id: 'bid-req-61023-4',
        travelerName: 'Nadia Ba',
        initial: 'N',
        rating: 4.4,
        reviewCount: 7,
        price: 29,
        travelDate: DateTime(2026, 6, 18),
        routeMatchConfidence: 81,
        message: 'I have spare luggage space on this flight.',
        bio: 'Occasional traveler offering spare capacity.',
        completedDeliveries: 7,
      ),
    ],
    'WW-19847': [
      Bid(
        id: 'bid-req-19847-1',
        travelerName: 'Kofi M.',
        initial: 'K',
        rating: 4.7,
        reviewCount: 11,
        price: 28,
        travelDate: DateTime(2026, 5, 20),
        routeMatchConfidence: 87,
        message: 'London to Lagos is my usual route — safe delivery.',
        featured: true,
        bio: 'UK–Nigeria corridor specialist.',
        completedDeliveries: 11,
      ),
      Bid(
        id: 'bid-req-19847-2',
        travelerName: 'Omar Fall',
        initial: 'O',
        rating: 4.5,
        reviewCount: 14,
        price: 31,
        travelDate: DateTime(2026, 5, 21),
        routeMatchConfidence: 82,
        message: 'Can collect near Heathrow and hand over in Lagos.',
        bio: 'Flexible meetup times across terminals.',
        completedDeliveries: 14,
      ),
    ],
    'WW-15902': [
      Bid(
        id: 'bid-req-15902-1',
        travelerName: 'Sophie R.',
        initial: 'S',
        rating: 4.9,
        reviewCount: 22,
        price: 26,
        travelDate: DateTime(2026, 4, 8),
        routeMatchConfidence: 92,
        message: 'Happy to carry phone accessories carefully packed.',
        featured: true,
        bio: 'France–Nigeria traveler; careful with electronics.',
        completedDeliveries: 22,
      ),
      Bid(
        id: 'bid-req-15902-2',
        travelerName: 'Jean-Paul M.',
        initial: 'J',
        rating: 4.6,
        reviewCount: 16,
        price: 27,
        travelDate: DateTime(2026, 4, 9),
        routeMatchConfidence: 85,
        message: 'Same flight path — easy airport meetup.',
        bio: 'Frequent flyer with spare bag capacity.',
        completedDeliveries: 16,
      ),
      Bid(
        id: 'bid-req-15902-3',
        travelerName: 'Lamine Gueye',
        initial: 'L',
        rating: 4.3,
        reviewCount: 8,
        price: 24,
        travelDate: DateTime(2026, 4, 7),
        routeMatchConfidence: 79,
        message: 'Budget-friendly option if timing works for you.',
        bio: 'Reliable budget hand-carry option.',
        completedDeliveries: 8,
      ),
    ],
    'WW-35102': [
      Bid(
        id: 'bid-req-35102-1',
        travelerName: 'Ama Serwaa',
        initial: 'A',
        rating: 4.8,
        reviewCount: 19,
        price: 34,
        travelDate: DateTime(2026, 7, 4),
        routeMatchConfidence: 95,
        message: 'I fly London–Accra often and can hand-deliver your documents.',
        featured: true,
        bio: 'Regular UK–Ghana traveler with careful document handling.',
        completedDeliveries: 19,
      ),
      Bid(
        id: 'bid-req-35102-2',
        travelerName: 'Kwame Boateng',
        initial: 'K',
        rating: 4.5,
        reviewCount: 12,
        price: 29,
        travelDate: DateTime(2026, 7, 5),
        routeMatchConfidence: 88,
        message: 'Same-day flight — happy to meet at Heathrow T3.',
        bio: 'Flexible airport meetup on Accra routes.',
        completedDeliveries: 12,
      ),
    ],
    'WW-56230': [
      Bid(
        id: 'bid-req-56230-1',
        travelerName: 'Carlos Mendez',
        initial: 'C',
        rating: 4.7,
        reviewCount: 14,
        price: 37,
        travelDate: DateTime(2026, 7, 17),
        routeMatchConfidence: 90,
        message: 'Madrid to Abidjan — I can safely carry your electronics.',
        featured: true,
        bio: 'Spain–Ivory Coast traveler; careful with devices.',
        completedDeliveries: 14,
      ),
    ],
  };

  static List<Bid> bidRequestsForShipment(String shipmentId) =>
      bidRequestsByShipmentId[shipmentId] ?? const [];

  /// Bumps when sender rejects / updates bid review status.
  static final bidRequestsVersion = ValueNotifier(0);

  static final _bidReviewStatusById = <String, BidReviewStatus>{};

  static BidReviewStatus bidReviewStatus(String bidId) =>
      _bidReviewStatusById[bidId] ?? BidReviewStatus.open;

  /// Open (non-rejected) bids for a parcel, for the Bid Requests feed.
  static List<Bid> openBidRequestsForShipment(String shipmentId) {
    return bidRequestsForShipment(shipmentId)
        .where((b) => bidReviewStatus(b.id) != BidReviewStatus.rejected)
        .toList();
  }

  /// Replaces matching-traveler list with backend-filtered results.
  static void replaceMatchingTravelersFromApi({
    required String shipmentId,
    required List<Bid> bids,
  }) {
    bidRequestsByShipmentId[shipmentId] = List<Bid>.from(bids);
    bidRequestsVersion.value++;
  }

  static void rejectBid(String shipmentId, String bidId) {
    _bidReviewStatusById[bidId] = BidReviewStatus.rejected;
    if (shipmentId.isNotEmpty) {
      final list = bidRequestsByShipmentId[shipmentId];
      list?.removeWhere((b) => b.id == bidId);
    }
    bids.removeWhere((b) => b.id == bidId);
    bidRequestsVersion.value++;
  }

  static void sendDeliveryRequest(String bidId) {
    _bidReviewStatusById[bidId] = BidReviewStatus.deliveryRequested;
    bidRequestsVersion.value++;
  }

  static void approveRequest(String bidId) {
    _bidReviewStatusById[bidId] = BidReviewStatus.approved;
    bidRequestsVersion.value++;
  }

  static final negotiatedMeetupByBidId = <String, String>{};
  static String? thread1ProposedMeetupLocation;
  static bool senderLocationAgreementAccepted = false;
  static bool travelerLocationAgreementAccepted = false;

  static void setNegotiatedMeetup(String bidId, String location) {
    negotiatedMeetupByBidId[bidId] = location;
    thread1ProposedMeetupLocation = location;
    // Sender proposal counts as sender acceptance.
    senderLocationAgreementAccepted = true;
    travelerLocationAgreementAccepted = false;
    locationAgreementConfirmed = false;
    bidRequestsVersion.value++;
  }

  static void acceptThread1LocationAgreement({required bool bySender}) {
    if (bySender) {
      senderLocationAgreementAccepted = true;
    } else {
      travelerLocationAgreementAccepted = true;
    }
    locationAgreementConfirmed =
        senderLocationAgreementAccepted && travelerLocationAgreementAccepted;
    chatThreadsVersion.value++;
  }

  static bool get canRevealThread1Contacts => locationAgreementConfirmed;

  /// Shipments whose bid selection is locked after acceptance.
  static final lockedShipmentIds = <String>{
    'WW-48291',
    'WW-61023',
    'WW-74011',
    'WW-74012',
    'WW-74021',
    'WW-74022',
  };

  static bool isShipmentBidLocked(String shipmentId) =>
      lockedShipmentIds.contains(shipmentId);

  /// Accept a bid: funds escrow + Doc/Object platform fees (wallet, then card fallback).
  /// Returns false when any required payment fails — booking is not created.
  static bool acceptBid({
    required String shipmentId,
    required Bid bid,
  }) {
    if (lockedShipmentIds.contains(shipmentId)) return false;

    final shipment = shipmentById(shipmentId);
    final category = shipment?.parcelCategory ?? 'Documents';
    final paysReceiver = paysReceiverFeeFor(shipmentId);

    final payoutCents = (bid.price * 100).round();
    final senderFeeCents =
        (senderPlatformFeeUsd(category: category, paysReceiverFee: paysReceiver) *
                100)
            .round();
    final travelerFeeCents =
        (travelerPlatformFeeUsd(category) * 100).round();
    final receiverFeeCents =
        (receiverPlatformFeeUsd(category: category, paysReceiverFee: paysReceiver) *
                100)
            .round();
    final senderNeedCents = payoutCents + senderFeeCents;

    // Wallet first; shortfall is charged from card (mock Stripe top-up).
    if (!WalletService.ensureAvailableWithCardFallback(
      role: WalletRole.sender,
      amountCents: senderNeedCents,
    )) {
      return false;
    }
    if (receiverFeeCents > 0 &&
        !WalletService.ensureAvailableWithCardFallback(
          role: WalletRole.receiver,
          amountCents: receiverFeeCents,
        )) {
      return false;
    }
    if (!WalletService.ensureAvailableWithCardFallback(
      role: WalletRole.traveler,
      amountCents: travelerFeeCents,
    )) {
      return false;
    }

    // Charge all parties before locking the booking.
    final escrowAlreadyHeld =
        WalletService.escrowCentsForShipment(shipmentId) > 0;
    if (!escrowAlreadyHeld &&
        !WalletService.holdEscrow(
          role: WalletRole.sender,
          shipmentId: shipmentId,
          amountCents: payoutCents,
          description: '$shipmentId · Escrow hold',
        )) {
      return false;
    }
    if (!WalletService.chargePlatformFee(
      role: WalletRole.sender,
      shipmentId: shipmentId,
      amountCents: senderFeeCents,
      description: '$shipmentId · Platform fee',
    )) {
      return false;
    }
    if (receiverFeeCents > 0 &&
        !WalletService.chargePlatformFee(
          role: WalletRole.receiver,
          shipmentId: shipmentId,
          amountCents: receiverFeeCents,
          description: '$shipmentId · Platform fee',
        )) {
      return false;
    }
    if (!WalletService.chargePlatformFee(
      role: WalletRole.traveler,
      shipmentId: shipmentId,
      amountCents: travelerFeeCents,
      description: '$shipmentId · Platform fee',
    )) {
      return false;
    }

    lockedShipmentIds.add(shipmentId);
    _bidReviewStatusById[bid.id] = BidReviewStatus.accepted;
    acceptedBidsByShipmentId[shipmentId] = bid;
    setShipmentStatus(shipmentId, ShipmentStatus.bidAccepted, skipNotification: true);

    // Receiver share already collected at accept time (or covered by sender).
    receiverApprovedFeeShare = receiverFeeCents / 100;
    receiverPaymentAutoCancelled = false;
    receiverPaidShipmentIds.add(shipmentId);

    final baseShipment = shipmentById(shipmentId);
    if (baseShipment != null) {
      if (!receiverShipments.any((s) => s.id == shipmentId)) {
        receiverShipments.insert(
          0,
          Shipment(
            id: baseShipment.id,
            fromCity: baseShipment.fromCity,
            toCity: baseShipment.toCity,
            fromCode: baseShipment.fromCode,
            toCode: baseShipment.toCode,
            travelDate: baseShipment.travelDate,
            status: ShipmentStatus.bidAccepted,
            role: ShipmentRole.receiver,
            parcelCategory: baseShipment.parcelCategory,
            parcelWeightKg: baseShipment.parcelWeightKg,
            parcelSize: baseShipment.parcelSize,
            description: baseShipment.description,
            travelerName: bid.travelerName,
            flightNumber: bid.flightNumber,
          ),
        );
        purgeExtraReceiverTravelerSelected();
      }
      if (!shipments.any(
        (s) => s.id == shipmentId && s.role == ShipmentRole.traveler,
      )) {
        shipments.insert(
          0,
          Shipment(
            id: baseShipment.id,
            fromCity: baseShipment.fromCity,
            toCity: baseShipment.toCity,
            fromCode: baseShipment.fromCode,
            toCode: baseShipment.toCode,
            travelDate: baseShipment.travelDate,
            status: ShipmentStatus.bidAccepted,
            role: ShipmentRole.traveler,
            parcelCategory: baseShipment.parcelCategory,
            parcelWeightKg: baseShipment.parcelWeightKg,
            parcelSize: baseShipment.parcelSize,
            description: baseShipment.description,
            travelerName: bid.travelerName,
            flightNumber: bid.flightNumber,
          ),
        );
      }
    }

    final others = bidRequestsForShipment(shipmentId)
        .where((b) => b.id != bid.id)
        .toList();
    for (final other in others) {
      _bidReviewStatusById[other.id] = BidReviewStatus.locked;
    }

    // Browse-bids demo list: accept selected, lock the rest.
    for (final other in List<Bid>.from(bids)) {
      if (other.id == bid.id) {
        _bidReviewStatusById[other.id] = BidReviewStatus.accepted;
      } else if (bidReviewStatus(other.id) != BidReviewStatus.rejected) {
        _bidReviewStatusById[other.id] = BidReviewStatus.locked;
      }
    }

    _notifyBidAccepted(shipmentId: shipmentId, bid: bid);
    bidRequestsVersion.value++;
    return true;
  }

  static void _notifyBidAccepted({
    required String shipmentId,
    required Bid bid,
  }) {
    NotificationService.push(
      AppNotification(
        id: 'snd-bid-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.sender,
        type: AppNotificationType.bid,
        title: 'Bid accepted & escrow funded',
        body:
            'You accepted ${bid.travelerName} for $shipmentId. Escrow is locked.',
        time: 'Just now',
        route: '/shipment/$shipmentId',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-bid-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.traveler,
        type: AppNotificationType.bidAccepted,
        title: 'Your bid was accepted',
        body: 'Sender accepted your bid on $shipmentId. Prepare for handoff.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-added-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.receiver,
        type: AppNotificationType.bid,
        title: 'Added to parcel',
        body:
            'You were added to parcel $shipmentId. Traveler ${bid.travelerName} will coordinate delivery.',
        time: 'Just now',
        route: '/receiver-tracking',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-bid-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.receiver,
        type: AppNotificationType.bid,
        title: 'Bid accepted',
        body:
            'Sender accepted ${bid.travelerName} for parcel $shipmentId. Escrow is funded.',
        time: 'Just now',
        route: '/receiver-tracking',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-pay-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.receiver,
        type: AppNotificationType.receiverPayment,
        title: 'Platform fee paid',
        body:
            'Your \$${platformFeeShare.toStringAsFixed(2)} platform fee share for $shipmentId was collected.',
        time: 'Just now',
        route: '/receiver-tracking',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-fee-$shipmentId-${DateTime.now().microsecondsSinceEpoch}',
        role: WalletRole.traveler,
        type: AppNotificationType.bid,
        title: 'Platform fee paid',
        body:
            'Your \$${platformFeeShare.toStringAsFixed(2)} platform fee for $shipmentId was collected.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
  }

  static List<AppNotification> get effectiveReceiverNotifications =>
      NotificationService.inboxFor(WalletRole.receiver);

  static List<AppNotification> get senderNotifications =>
      NotificationService.inboxFor(WalletRole.sender);

  static List<AppNotification> get travelerNotifications =>
      NotificationService.inboxFor(WalletRole.traveler);

  static ValueNotifier<int> get receiverNotificationsVersion =>
      NotificationService.version;

  static ValueNotifier<int> get senderNotificationsVersion =>
      NotificationService.version;

  static ValueNotifier<int> get travelerNotificationsVersion =>
      NotificationService.version;

  static void triggerReceiverNotificationOnAcceptance({
    required String shipmentId,
    required String travelerName,
  }) {
    _notifyBidAccepted(
      shipmentId: shipmentId,
      bid: acceptedBidsByShipmentId[shipmentId] ??
          Bid(
            id: 'fallback',
            travelerName: travelerName,
            initial: travelerName.isNotEmpty ? travelerName[0] : 'T',
            rating: 4.9,
            reviewCount: 0,
            price: 18,
            travelDate: DateTime.now(),
            routeMatchConfidence: 90,
          ),
    );
  }

  static const receiverAutoCancelPolicy =
      'If timer expires, booking auto-cancels and escrow principal is refunded. '
      'Platform fees are non-refundable after timer expiry.';
  static const receiverPlatformFeeRefundableOnAutoCancel = false;
  static DateTime? _receiverPaymentWindowStartedAt;
  static bool receiverPaymentAutoCancelled = false;
  static double? receiverApprovedFeeShare;
  static final Set<String> receiverPaidShipmentIds = {
    'WW-48291',
    'WW-74011',
    'WW-74012',
    'WW-74021',
    'WW-74022',
  };

  static bool get isReceiverPaymentPending =>
      !receiverPaymentAutoCancelled && receiverApprovedFeeShare == null;

  /// Receiver must pay the 50% platform fee before opening parcel details.
  static bool needsReceiverPayment(Shipment shipment) {
    final status = effectiveStatus(shipment);
    if (status != ShipmentStatus.bidAccepted) return false;
    if (receiverPaidShipmentIds.contains(shipment.id)) return false;
    if (receiverPaymentAutoCancelled) return false;
    return true;
  }

  static Duration receiverPaymentWindowFor(Shipment shipment) {
    final now = DateTime.now();
    final departureInHours = shipment.travelDate.difference(now).inHours;
    return departureInHours <= 24
        ? const Duration(hours: 2)
        : const Duration(hours: 12);
  }

  static void startReceiverPaymentWindowIfNeeded(Shipment shipment) {
    _receiverPaymentWindowStartedAt ??= DateTime.now();
    receiverPaymentAutoCancelled = false;
  }

  static DateTime receiverPaymentDeadline(Shipment shipment) {
    startReceiverPaymentWindowIfNeeded(shipment);
    return _receiverPaymentWindowStartedAt!.add(receiverPaymentWindowFor(shipment));
  }

  static Duration receiverPaymentRemaining(Shipment shipment) {
    final remaining = receiverPaymentDeadline(shipment).difference(DateTime.now());
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  static bool isReceiverPaymentExpired(Shipment shipment) =>
      receiverPaymentRemaining(shipment) == Duration.zero;

  static void autoCancelReceiverPayment(Shipment shipment) {
    if (receiverPaymentAutoCancelled) return;
    receiverPaymentAutoCancelled = true;
    refundEscrowOnCancellation(
      shipmentId: shipment.id,
      reason: 'Receiver payment window expired',
      refundPlatformFee: receiverPlatformFeeRefundableOnAutoCancel,
    );
    setShipmentStatus(shipment.id, ShipmentStatus.open, skipEscrowSideEffects: true, skipNotification: true);
    NotificationService.push(
      AppNotification(
        id: 'rcv-cancel-${shipment.id}',
        role: WalletRole.receiver,
        type: AppNotificationType.cancellation,
        title: 'Payment window expired',
        body:
            'Booking for ${shipment.id} auto-cancelled. Escrow principal refunded; platform fees are non-refundable.',
        time: 'Just now',
        route: '/receiver-notifications',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'snd-cancel-${shipment.id}',
        role: WalletRole.sender,
        type: AppNotificationType.cancellation,
        title: 'Booking auto-cancelled',
        body: 'Receiver payment window expired for ${shipment.id}. Escrow refunded.',
        time: 'Just now',
        route: '/sender-notifications',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-cancel-${shipment.id}',
        role: WalletRole.traveler,
        type: AppNotificationType.cancellation,
        title: 'Delivery cancelled',
        body: 'Shipment ${shipment.id} was auto-cancelled due to receiver payment timeout.',
        time: 'Just now',
        route: '/traveler-notifications',
      ),
    );
  }

  static bool approveReceiverFeeShare({
    required Shipment shipment,
    required double feeAmount,
  }) {
    if (receiverPaidShipmentIds.contains(shipment.id)) {
      receiverApprovedFeeShare = feeAmount;
      return true;
    }

    if (feeAmount > 0) {
      final feeCents = (feeAmount * 100).round();
      if (!WalletService.ensureAvailableWithCardFallback(
        role: WalletRole.receiver,
        amountCents: feeCents,
      )) {
        return false;
      }
      if (!WalletService.chargePlatformFee(
        role: WalletRole.receiver,
        shipmentId: shipment.id,
        amountCents: feeCents,
        description: '${shipment.id} · Platform fee',
      )) {
        return false;
      }
    }

    receiverApprovedFeeShare = feeAmount;
    receiverPaymentAutoCancelled = false;
    receiverPaidShipmentIds.add(shipment.id);
    NotificationService.push(
      AppNotification(
        id: 'rcv-pay-ok-${shipment.id}',
        role: WalletRole.receiver,
        type: AppNotificationType.receiverPayment,
        title: 'Payment successful',
        body: feeAmount == 0
            ? 'Platform fee waived for ${shipment.id}.'
            : '\$${feeAmount.toStringAsFixed(2)} platform fee paid for ${shipment.id}.',
        time: 'Just now',
        route: '/receiver-tracking',
      ),
    );
    return true;
  }

  /// Default parcel for the sender Bid Requests screen entry points.
  static const defaultBidRequestsShipmentId = 'WW-27490';

  /// Static bid requests shown on the sender Bid Requests screen.
  static List<Bid> get bidRequests =>
      bidRequestsForShipment(defaultBidRequestsShipmentId);

  /// Accepted traveler bids keyed by sender parcel ID (for chat navigation).
  static final acceptedBidsByShipmentId = <String, Bid>{
    'WW-48291': bids.first,
    'WW-61023': Bid(
      id: 'accepted-bid-61023',
      travelerName: 'Moussa T.',
      initial: 'M',
      rating: 4.8,
      reviewCount: 15,
      price: 35,
      travelDate: DateTime(2026, 6, 18),
      routeMatchConfidence: 93,
      flightNumber: 'AF718',
      message: 'I can deliver your notarized documents safely to Senegal.',
    ),
    'WW-19847': Bid(
      id: 'accepted-bid-19847',
      travelerName: 'Kofi M.',
      initial: 'K',
      rating: 4.7,
      reviewCount: 11,
      price: 28,
      travelDate: DateTime(2026, 5, 20),
      routeMatchConfidence: 87,
      flightNumber: 'BA075',
    ),
    'WW-15902': Bid(
      id: 'accepted-bid-15902',
      travelerName: 'Sophie R.',
      initial: 'S',
      rating: 4.8,
      reviewCount: 7,
      price: 42,
      travelDate: DateTime(2026, 4, 8),
      routeMatchConfidence: 90,
      flightNumber: 'AF124',
      message: 'Experienced with electronics — I pack carefully.',
    ),
    'WW-74011': Bid(
      id: 'accepted-bid-74011',
      travelerName: 'Fatou B.',
      initial: 'F',
      rating: 4.9,
      reviewCount: 12,
      price: 30,
      travelDate: DateTime.now().add(const Duration(days: 5)),
      routeMatchConfidence: 91,
      flightNumber: 'AF502',
      message: 'Happy to carry your documents carefully.',
    ),
    'WW-74012': Bid(
      id: 'accepted-bid-74012',
      travelerName: 'Ibrahim K.',
      initial: 'I',
      rating: 4.6,
      reviewCount: 9,
      price: 28,
      travelDate: DateTime.now().add(const Duration(hours: 12)),
      routeMatchConfidence: 88,
      flightNumber: 'BA078',
      message: 'Departing soon — I can still take this.',
    ),
    'WW-74021': Bid(
      id: 'accepted-bid-74021',
      travelerName: 'Amara O.',
      initial: 'A',
      rating: 4.8,
      reviewCount: 14,
      price: 32,
      travelDate: DateTime.now().add(const Duration(days: 4)),
      routeMatchConfidence: 92,
      flightNumber: 'LH562',
      message: 'I can deliver your documents to Lagos safely.',
    ),
    'WW-74022': Bid(
      id: 'accepted-bid-74022',
      travelerName: 'Youssef H.',
      initial: 'Y',
      rating: 4.5,
      reviewCount: 8,
      price: 26,
      travelDate: DateTime.now().add(const Duration(hours: 10)),
      routeMatchConfidence: 86,
      flightNumber: 'IB3357',
      message: 'Flight soon — still happy to carry this.',
    ),
  };

  static Bid? acceptedBidForShipment(String shipmentId) =>
      acceptedBidsByShipmentId[shipmentId];

  /// Parcel requests matched to the traveler's posted route (API when available).
  static final matchingRequests = <MatchingRequest>[];

  static final deliveryRequests = [
    DeliveryRequest(
      id: 'req-1',
      fromCity: 'London',
      toCity: 'Lagos',
      travelDate: DateTime(2026, 6, 20),
      maxBudget: 35,
      category: 'objects',
      weightKg: 2,
      size: 'small box',
      senderName: 'James O.',
      senderInitial: 'J',
      senderRating: 4.8,
      description:
          'Object package: personal clothing items for family — folded and sealed in a small box.',
      senderMessage:
          'Please keep the box dry and upright. My family will collect it at Lagos airport arrivals.',
      meetupLocations: const ['Airport', 'Coffee Shop'],
      photoCount: 2,
    ),
    DeliveryRequest(
      id: 'req-2',
      fromCity: 'London',
      toCity: 'Lagos',
      travelDate: DateTime(2026, 6, 18),
      maxBudget: 20,
      category: 'documents',
      weightKg: 0.5,
      size: 'envelope',
      senderName: 'Fatima A.',
      senderInitial: 'F',
      senderRating: 5.0,
      description:
          'Document package: notarized university transcripts in a sealed envelope.',
      senderMessage:
          'These are important sealed documents. Please do not bend or open the envelope.',
      meetupLocations: const ['Airport', 'Hotel Lobby'],
      photoCount: 1,
    ),
    DeliveryRequest(
      id: 'req-3',
      fromCity: 'Paris',
      toCity: 'Dakar',
      travelDate: DateTime(2026, 6, 15),
      maxBudget: 40,
      category: 'objects',
      weightKg: 1.2,
      size: 'small box',
      senderName: 'Marc L.',
      senderInitial: 'M',
      senderRating: 4.9,
      description:
          'Object package: small electronics and accessories packed for hand delivery.',
      senderMessage:
          'Please handle carefully and meet me at CDG cafe near Terminal 2E.',
      meetupLocations: const ['Airport', 'Coffee Shop'],
      photoCount: 2,
    ),
  ];

  static const chatMessages = [
    ChatMessage(
      text: "Hi! I'm Aissatou. I'll be on AF718 on Jun 15. When can we meet for handoff?",
      isMine: false,
      time: '10:42 AM',
    ),
    ChatMessage(
      text: 'Hi Aissatou! Can we meet at CDG airport Terminal 2E around 2pm on the 14th?',
      isMine: true,
      time: '10:44 AM',
    ),
    ChatMessage(
      text: "Perfect! I'll be there. Please have the parcel sealed and labelled.",
      isMine: false,
      time: '10:45 AM',
    ),
    ChatMessage(
      text: "Done! Here's a photo of the parcel 📦",
      isMine: true,
      time: '10:47 AM',
    ),
    ChatMessage(
      text: '',
      isMine: true,
      time: '10:48 AM',
      isImage: true,
      imageName: 'parcel_photo.jpg',
    ),
    ChatMessage(
      text: 'Looks good! See you then 👍',
      isMine: false,
      time: '10:49 AM',
    ),
  ];

  /// Traveler bottom-nav chat (sender contact on active delivery).
  static const travelerTabChatContactName = 'Marc L.';
  static const travelerTabChatContactInitial = 'M';
  static const travelerTabChatShipmentId = 'WW-48291';

  static const travelerTabChatMessages = [
    ChatMessage(
      text: "Hi! I'm Aissatou. I'll be on AF718 on Jun 15. When can we meet for handoff?",
      isMine: true,
      time: '10:42 AM',
    ),
    ChatMessage(
      text: 'Hi Aissatou! Can we meet at CDG airport Terminal 2E around 2pm on the 14th?',
      isMine: false,
      time: '10:44 AM',
    ),
    ChatMessage(
      text: "Perfect! I'll be there. Please have the parcel sealed and labelled.",
      isMine: true,
      time: '10:45 AM',
    ),
    ChatMessage(
      text: "Done! Here's a photo of the parcel 📦",
      isMine: false,
      time: '10:47 AM',
    ),
    ChatMessage(
      text: '',
      isMine: false,
      time: '10:48 AM',
      isImage: true,
      imageName: 'parcel_photo.jpg',
    ),
    ChatMessage(
      text: 'Looks good! See you then 👍',
      isMine: true,
      time: '10:49 AM',
    ),
  ];

  /// Demo WhatsApp-style inboxes (4–5 conversations per role).
  static const senderChatInbox = [
    ChatConversationPreview(
      id: 's1',
      name: 'Aissatou D.',
      initial: 'A',
      lastMessage: 'Will do. I always pack parcels carefully — happy to share a photo if needed.',
      time: '2:33 PM',
      shipmentId: 'WW-48291',
      unreadCount: 1,
      messages: chatMessages,
    ),
    ChatConversationPreview(
      id: 's2',
      name: 'Amadou K.',
      initial: 'A',
      lastMessage: 'I can pick up near Terminal 1 tomorrow morning.',
      time: '11:20 AM',
      shipmentId: 'WW-48102',
      unreadCount: 2,
      messages: [
        ChatMessage(
          text: 'Hi! I saw your parcel to Lagos. I fly tomorrow.',
          isMine: false,
          time: '11:05 AM',
        ),
        ChatMessage(
          text: 'Great — can we meet at the airport?',
          isMine: true,
          time: '11:12 AM',
        ),
        ChatMessage(
          text: 'I can pick up near Terminal 1 tomorrow morning.',
          isMine: false,
          time: '11:20 AM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 's3',
      name: 'Fatou B.',
      initial: 'F',
      lastMessage: 'Parcel received confirmation looks good on my side.',
      time: 'Yesterday',
      shipmentId: 'WW-47955',
      messages: [
        ChatMessage(
          text: 'Parcel received confirmation looks good on my side.',
          isMine: false,
          time: '4:10 PM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 's4',
      name: 'Ibrahim S.',
      initial: 'I',
      lastMessage: 'Please confirm the meetup location before Friday.',
      time: 'Mon',
      shipmentId: 'WW-47810',
      unreadCount: 1,
      messages: [
        ChatMessage(
          text: 'Please confirm the meetup location before Friday.',
          isMine: false,
          time: '9:02 AM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 's5',
      name: 'Mariama N.',
      initial: 'M',
      lastMessage: 'Thanks — see you at the coffee shop.',
      time: 'Sun',
      shipmentId: 'WW-47701',
      messages: [
        ChatMessage(
          text: 'Thanks — see you at the coffee shop.',
          isMine: false,
          time: '6:40 PM',
        ),
      ],
    ),
  ];

  static const travelerChatInbox = <ChatConversationPreview>[];

  static const receiverChatInbox = [
    ChatConversationPreview(
      id: 'r1',
      name: 'Aissatou D.',
      initial: 'A',
      lastMessage: 'I will message you on arrival at the station.',
      time: '3:05 PM',
      shipmentId: 'WW-48291',
      unreadCount: 2,
      messages: [
        ChatMessage(
          text: 'Hi! I am bringing your parcel from Paris.',
          isMine: false,
          time: '2:50 PM',
        ),
        ChatMessage(
          text: 'I will message you on arrival at the station.',
          isMine: false,
          time: '3:05 PM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 'r2',
      name: 'Kofi Mensah',
      initial: 'K',
      lastMessage: 'Delivery window is between 4–6pm.',
      time: '12:40 PM',
      shipmentId: 'WW-48188',
      messages: [
        ChatMessage(
          text: 'Delivery window is between 4–6pm.',
          isMine: false,
          time: '12:40 PM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 'r3',
      name: 'Nadia Ba',
      initial: 'N',
      lastMessage: 'Please keep your phone on for meetup updates.',
      time: 'Yesterday',
      shipmentId: 'WW-48044',
      unreadCount: 1,
      messages: [
        ChatMessage(
          text: 'Please keep your phone on for meetup updates.',
          isMine: false,
          time: '7:15 PM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 'r4',
      name: 'Yves Toure',
      initial: 'Y',
      lastMessage: 'Parcel handed over successfully.',
      time: 'Wed',
      shipmentId: 'WW-47900',
      messages: [
        ChatMessage(
          text: 'Parcel handed over successfully.',
          isMine: false,
          time: '2:01 PM',
        ),
      ],
    ),
    ChatConversationPreview(
      id: 'r5',
      name: 'Lamine Gueye',
      initial: 'L',
      lastMessage: 'Running 10 minutes late — almost there.',
      time: 'Tue',
      shipmentId: 'WW-47822',
      unreadCount: 1,
      messages: [
        ChatMessage(
          text: 'Running 10 minutes late — almost there.',
          isMine: false,
          time: '6:18 PM',
        ),
      ],
    ),
  ];

  static List<ChatConversationPreview> chatInboxFor(WalletRole role) {
    return switch (role) {
      WalletRole.sender => senderChatInbox,
      WalletRole.traveler => travelerChatInbox,
      WalletRole.receiver => receiverChatInbox,
    };
  }

  static ChatConversationPreview? chatConversationById(
    WalletRole role,
    String id,
  ) {
    for (final c in chatInboxFor(role)) {
      if (c.id == id) return c;
    }
    return null;
  }

  static const reviews = [
    Review(
      reviewerName: 'Aissatou D.',
      initial: 'A',
      rating: 5,
      text: 'Great sender, parcel was well packaged and on time.',
      date: 'May 28, 2026',
    ),
    Review(
      reviewerName: 'Kofi M.',
      initial: 'K',
      rating: 4,
      text: 'Smooth transaction, would carry again.',
      date: 'May 15, 2026',
    ),
  ];

  static const walletTransactions = [
    WalletTransaction(
      amount: 18,
      description: 'WW-33104 · Delivery payout',
      date: 'May 30',
      type: TransactionType.credit,
    ),
    WalletTransaction(
      amount: 22,
      description: 'WW-21883 · Delivery payout',
      date: 'May 22',
      type: TransactionType.credit,
    ),
    WalletTransaction(
      amount: 50,
      description: 'Withdrawal to Barclays',
      date: 'May 18',
      type: TransactionType.debit,
    ),
  ];

  static const platformFeeInternational = 5.0;
  static const platformFeeShare = 2.50;

  /// Document platform fees (USD).
  static const platformFeeDocumentSenderUsd = 2.0;
  static const platformFeeDocumentTravelerUsd = 2.0;
  static const platformFeeDocumentReceiverUsd = 2.0;
  static const platformFeeDocumentSenderPaysReceiverUsd = 3.0;

  /// Object platform fees (USD).
  static const platformFeeObjectSenderUsd = 4.0;
  static const platformFeeObjectTravelerUsd = 4.0;
  static const platformFeeObjectReceiverUsd = 4.0;
  static const platformFeeObjectSenderPaysReceiverUsd = 6.0;

  /// Whether the sender elected to cover the receiver's platform fee at post time.
  static final paysReceiverFeeByShipmentId = <String, bool>{};

  static void setPaysReceiverFee(String shipmentId, bool paysReceiverFee) {
    paysReceiverFeeByShipmentId[shipmentId] = paysReceiverFee;
  }

  static bool paysReceiverFeeFor(String shipmentId) =>
      paysReceiverFeeByShipmentId[shipmentId] ?? false;

  static bool isDocumentParcelCategory(String category) {
    final normalized = category.trim().toLowerCase();
    return normalized == 'documents' || normalized == 'document';
  }

  /// Sender platform fee for a parcel category.
  static double senderPlatformFeeUsd({
    required String category,
    bool paysReceiverFee = false,
  }) {
    final isDocument = isDocumentParcelCategory(category);
    if (paysReceiverFee) {
      return isDocument
          ? platformFeeDocumentSenderPaysReceiverUsd
          : platformFeeObjectSenderPaysReceiverUsd;
    }
    return isDocument
        ? platformFeeDocumentSenderUsd
        : platformFeeObjectSenderUsd;
  }

  /// Traveler platform fee for a parcel category.
  static double travelerPlatformFeeUsd(String category) {
    return isDocumentParcelCategory(category)
        ? platformFeeDocumentTravelerUsd
        : platformFeeObjectTravelerUsd;
  }

  /// Receiver platform fee. Zero when the sender covers the receiver share.
  static double receiverPlatformFeeUsd({
    required String category,
    bool paysReceiverFee = false,
  }) {
    if (paysReceiverFee) return 0;
    return isDocumentParcelCategory(category)
        ? platformFeeDocumentReceiverUsd
        : platformFeeObjectReceiverUsd;
  }

  static String _senderCorridorKey(String fromCode, String toCode) =>
      '${fromCode.toUpperCase()}|${toCode.toUpperCase()}';

  /// True when the shipment is past Matching Travelers (Traveler Selected+)
  /// and not yet delivered — i.e. an in-progress booking on that corridor.
  static bool _isInProgressBeyondOpen(Shipment s) {
    final status = effectiveStatus(s);
    return status != ShipmentStatus.open && status != ShipmentStatus.delivered;
  }

  /// Drops open Matching Travelers / Receiver Pending cards that share a
  /// corridor with an already-selected (or later) sender shipment.
  /// Prevents France→Senegal duplicating Paris→Dakar Traveler Selected.
  static void purgeOpenSenderDuplicatesOfInProgress() {
    final advancedCorridors = <String>{
      for (final s in senderShipments)
        if (_isInProgressBeyondOpen(s))
          _senderCorridorKey(s.fromCode, s.toCode),
    };
    if (advancedCorridors.isEmpty) return;

    final removedIds = <String>[];
    senderShipments.removeWhere((s) {
      if (effectiveStatus(s) != ShipmentStatus.open) return false;
      if (!advancedCorridors
          .contains(_senderCorridorKey(s.fromCode, s.toCode))) {
        return false;
      }
      removedIds.add(s.id);
      return true;
    });
    if (removedIds.isEmpty) return;

    for (final id in removedIds) {
      receiverAcceptedShipmentIds.remove(id);
      bidRequestsByShipmentId.remove(id);
      selectedMatchingTravelerByShipmentId.remove(id);
      senderPendingBidCounts.remove(id);
    }
    bidRequestsVersion.value++;
  }

  static bool _hasInProgressSenderOnCorridor(String fromCode, String toCode) {
    final key = _senderCorridorKey(fromCode, toCode);
    return senderShipments.any(
      (s) =>
          _isInProgressBeyondOpen(s) &&
          _senderCorridorKey(s.fromCode, s.toCode) == key,
    );
  }

  /// Registers a newly posted demo delivery into sender listings.
  static void registerPostedDelivery({
    required String shipmentId,
    required String fromCity,
    required String toCity,
    required String fromCode,
    required String toCode,
    required DateTime travelDate,
    required String parcelCategory,
    required double parcelWeightKg,
    required String parcelSize,
    required String description,
    required int parcelPhotoCount,
    bool paysReceiverFee = false,
    bool seedDemoMatches = true,
  }) {
    setPaysReceiverFee(shipmentId, paysReceiverFee);
    if (senderShipments.any((s) => s.id == shipmentId)) return;
    // Keep Traveler Selected (e.g. WW-48291 Paris→Dakar) instead of adding
    // a second Matching Travelers card on the same FR→SN corridor.
    if (_hasInProgressSenderOnCorridor(fromCode, toCode)) {
      purgeOpenSenderDuplicatesOfInProgress();
      return;
    }
    senderShipments.insert(
      0,
      Shipment(
        id: shipmentId,
        fromCity: fromCity,
        toCity: toCity,
        fromCode: fromCode,
        toCode: toCode,
        travelDate: travelDate,
        status: ShipmentStatus.open,
        role: ShipmentRole.sender,
        parcelCategory: parcelCategory,
        parcelWeightKg: parcelWeightKg,
        parcelSize: parcelSize,
        description: description,
        parcelPhotoCount: parcelPhotoCount,
      ),
    );
    // Demo only: pretend the receiver already accepted so Matching Travelers
    // can be exercised without a second account.
    if (seedDemoMatches) {
      receiverAcceptedShipmentIds.add(shipmentId);
      _seedDemoMatchingTravelers(
        shipmentId: shipmentId,
        travelDate: travelDate,
        fromCity: fromCity,
        toCity: toCity,
      );
    }
    bidRequestsVersion.value++;
  }

  /// Seeds demo matching travelers for a newly posted parcel.
  static void _seedDemoMatchingTravelers({
    required String shipmentId,
    required DateTime travelDate,
    required String fromCity,
    required String toCity,
  }) {
    if (bidRequestsByShipmentId.containsKey(shipmentId) &&
        bidRequestsByShipmentId[shipmentId]!.isNotEmpty) {
      return;
    }
    final stamp = shipmentId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    bidRequestsByShipmentId[shipmentId] = [
      Bid(
        id: 'bid-req-$stamp-1',
        travelerName: 'Aissatou D.',
        initial: 'A',
        rating: 4.9,
        reviewCount: 24,
        price: 22,
        travelDate: travelDate,
        routeMatchConfidence: 95,
        flightNumber: 'AF718',
        message:
            'I travel $fromCity → $toCity regularly and can hand-carry your parcel safely.',
        featured: true,
        bio: 'Frequent traveler with careful hand-carry handling.',
        completedDeliveries: 24,
      ),
      Bid(
        id: 'bid-req-$stamp-2',
        travelerName: 'Moussa T.',
        initial: 'M',
        rating: 4.8,
        reviewCount: 15,
        price: 25,
        travelDate: travelDate.add(const Duration(days: 1)),
        routeMatchConfidence: 90,
        flightNumber: 'TK505',
        message: 'Flexible meetup times — happy to help with this route.',
        bio: 'Reliable corridor traveler.',
        completedDeliveries: 15,
      ),
      Bid(
        id: 'bid-req-$stamp-3',
        travelerName: 'Fatou B.',
        initial: 'F',
        rating: 4.6,
        reviewCount: 18,
        price: 20,
        travelDate: travelDate,
        routeMatchConfidence: 86,
        message: 'I have spare luggage space on this trip.',
        bio: 'Budget-friendly traveler on this corridor.',
        completedDeliveries: 18,
      ),
    ];
  }

  /// Minimum wallet balance (USD) a traveler must hold to post a trip.
  static const tripPostingFeeReserveUsd =
      TripCreationWalletValidation.minimumBalanceUsd;

  /// Section 2.3 — KYC must be approved for marketplace actions.
  static String? validateKycApproved(AuthUser? authUser) {
    if (authUser?.isKycApproved == true) return null;
    if (authUser?.isKycSubmitted == true) {
      return 'KYC is pending review. You will be notified once approved.';
    }
    if (authUser?.isKycRejected == true) {
      return 'KYC was rejected. Please retry identity verification.';
    }
    return 'KYC must be approved before this action.';
  }

  /// Validates KYC + wallet balance before allowing a traveler to post a trip.
  /// Returns an error message, or null when posting is allowed.
  static String? validateTripPosting(AuthUser? authUser) {
    final kycError = validateKycApproved(authUser);
    if (kycError != null) return kycError;

    return TripCreationWalletValidation.validate();
  }
  static const postDeliveryMaximumBudget = 40.0;
  static const travelerAvailableLuggageCapacityKg = 8.0;

  static const verifiedRecipients = <VerifiedRecipient>[
    VerifiedRecipient(
      id: 'rec-1',
      name: 'Amadou Diallo',
      phone: '+221 77 123 4567',
      verified: true,
    ),
    VerifiedRecipient(
      id: 'rec-2',
      name: 'Fatou Ndiaye',
      phone: '+221 76 555 0192',
      verified: true,
    ),
    VerifiedRecipient(
      id: 'rec-3',
      name: 'Pending Contact',
      phone: '+33 600 000 000',
      verified: false,
    ),
  ];

  static final parcelRequestsVersion = ValueNotifier<int>(0);
  static int _nextParcelRequestId = 91001;
  static String? lastCreatedParcelRequestId;
  static bool parcelCreationPhotosUploaded = false;

  static String computeRouteHash({
    required String origin,
    required String destination,
    required DateTime travelDate,
  }) {
    final raw = '${origin.trim().toLowerCase()}|${destination.trim().toLowerCase()}|${travelDate.toIso8601String()}';
    return raw.hashCode.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

  static VerifiedRecipient? recipientById(String? id) {
    if (id == null) return null;
    for (final recipient in verifiedRecipients) {
      if (recipient.id == id) return recipient;
    }
    return null;
  }

  static ParcelCreationResult submitParcelRequest({
    required TravelerTrip trip,
    required String category,
    required double weightKg,
    required String volume,
    required String recipientId,
    required double proposedBudgetUsd,
    required String description,
    required List<String> photoPaths,
    required String senderName,
    required String senderInitial,
    required double senderRating,
  }) {
    final recipient = recipientById(recipientId);
    if (recipient == null || !recipient.verified) {
      throw StateError('Recipient must be verified');
    }
    if (photoPaths.isEmpty || photoPaths.length > 3) {
      throw StateError('Upload 1–3 parcel photos before activation');
    }

    final requestId = 'PR-$_nextParcelRequestId';
    _nextParcelRequestId++;
    final routeHash = computeRouteHash(
      origin: trip.origin,
      destination: trip.destination,
      travelDate: trip.travelDate,
    );
    final normalizedCategory = category == 'objects' ? 'objects' : 'documents';

    final request = DeliveryRequest(
      id: requestId,
      fromCity: trip.origin,
      toCity: trip.destination,
      travelDate: trip.travelDate,
      maxBudget: proposedBudgetUsd,
      category: normalizedCategory,
      weightKg: weightKg,
      size: volume,
      senderName: senderName,
      senderInitial: senderInitial,
      senderRating: senderRating,
      description: description.trim(),
      photoCount: photoPaths.length,
    );
    deliveryRequests.insert(0, request);

    final fromCode = _guessCountryCode(trip.origin);
    final toCode = _guessCountryCode(trip.destination);
    if (_hasInProgressSenderOnCorridor(fromCode, toCode)) {
      purgeOpenSenderDuplicatesOfInProgress();
      lastCreatedParcelRequestId = requestId;
      parcelCreationPhotosUploaded = true;
      parcelRequestsVersion.value++;
      deliveryRequestsVersion.value++;
      bidRequestsVersion.value++;
      return ParcelCreationResult(
        requestId: requestId,
        routeHash: routeHash,
        budgetConstraintUsd: proposedBudgetUsd,
        category: normalizedCategory,
        route: trip.route,
        photoCount: photoPaths.length,
        recipientName: recipient.name,
      );
    }

    final shipment = Shipment(
      id: requestId,
      fromCity: trip.origin,
      toCity: trip.destination,
      fromCode: fromCode,
      toCode: toCode,
      travelDate: trip.travelDate,
      status: ShipmentStatus.open,
      role: ShipmentRole.sender,
      parcelCategory: normalizedCategory,
      parcelWeightKg: weightKg,
      parcelSize: volume,
      description: description.trim(),
      parcelPhotoCount: photoPaths.length,
    );
    senderShipments.insert(0, shipment);
    // Demo: receiver accepted + matching travelers available immediately.
    receiverAcceptedShipmentIds.add(requestId);
    _seedDemoMatchingTravelers(
      shipmentId: requestId,
      travelDate: trip.travelDate,
      fromCity: trip.origin,
      toCity: trip.destination,
    );
    lastCreatedParcelRequestId = requestId;
    parcelCreationPhotosUploaded = true;
    parcelRequestsVersion.value++;
    deliveryRequestsVersion.value++;
    bidRequestsVersion.value++;

    return ParcelCreationResult(
      requestId: requestId,
      routeHash: routeHash,
      budgetConstraintUsd: proposedBudgetUsd,
      category: normalizedCategory,
      route: trip.route,
      photoCount: photoPaths.length,
      recipientName: recipient.name,
    );
  }

  static String _guessCountryCode(String place) {
    final lower = place.toLowerCase();
    if (lower.contains('london') || lower.contains('paris') || lower.contains('france')) {
      return lower.contains('london') ? 'GB' : 'FR';
    }
    if (lower.contains('lagos') || lower.contains('senegal') || lower.contains('dakar')) {
      return lower.contains('lagos') ? 'NG' : 'SN';
    }
    if (lower.contains('dubai')) return 'AE';
    if (lower.contains('casablanca')) return 'MA';
    return 'WW';
  }

  static final deliveryRequestsVersion = ValueNotifier<int>(0);

  static final travelerPostedTrips = <TravelerTrip>[];

  /// Seeded demo listings — none while trips API is not available.
  static const seedTravelerTripIds = <String>{};

  /// Trips shown on traveler Home / My Trips (API-backed when available).
  static List<TravelerTrip> travelerTripsForDisplay({required bool demoMode}) {
    return List<TravelerTrip>.from(travelerPostedTrips);
  }

  static var _nextTripId = 8;

  static final travelerPostedTripsVersion = ValueNotifier(0);

  /// Replaces in-memory trips with GET /trips results (keeps Home / My Trips in sync).
  static void replaceTravelerPostedTrips(List<TravelerTrip> trips) {
    travelerPostedTrips
      ..clear()
      ..addAll(trips);
    travelerPostedTripsVersion.value++;
  }

  static void addTravelerPostedTrip(TravelerTrip trip) {
    final tripWithId = trip.id.isEmpty
        ? TravelerTrip(
            id: 'trip-$_nextTripId',
            origin: trip.origin,
            destination: trip.destination,
            travelDate: trip.travelDate,
            luggageCapacityKg: trip.luggageCapacityKg,
            status: trip.status,
          )
        : trip;
    if (trip.id.isEmpty) _nextTripId++;
    travelerPostedTrips.insert(0, tripWithId);
    rebuildMatchingRequestsForTrip(tripWithId);
    travelerPostedTripsVersion.value++;
  }

  static void updateTravelerTrip(TravelerTrip updated) {
    final index = travelerPostedTrips.indexWhere((t) => t.id == updated.id);
    if (index < 0) return;
    travelerPostedTrips[index] = updated;
    rebuildMatchingRequestsForTrip(updated);
    travelerPostedTripsVersion.value++;
  }

  static void cancelTravelerTrip(String tripId) {
    travelerPostedTrips.removeWhere((t) => t.id == tripId);
    matchingRequests.removeWhere((m) => m.tripId == tripId);
    travelerPostedTripsVersion.value++;
  }

  /// Traveler / sender open-listing & trip cancel requires travel still
  /// [cancelMinHoursBeforeTravel] hours (or more) away.
  /// Booked shipment cancel (sender or traveler) is allowed through collected;
  /// the same window decides whether platform fees are refunded (≥24h) or kept (<24h).
  static const cancelMinHoursBeforeTravel = 24;
  static const travelerCancelMinHoursBeforeTravel = cancelMinHoursBeforeTravel;
  static const senderCancelMinHoursBeforeTravel = cancelMinHoursBeforeTravel;

  static bool canCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    return travelDate.difference(at) >=
        const Duration(hours: cancelMinHoursBeforeTravel);
  }

  /// ≥24h before travel → platform fees refunded to all parties on cancel.
  static bool isPlatformFeeRefundableOnCancel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  static bool canTravelerCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  /// Open listings with no sender requests can always be withdrawn.
  static bool canTravelerCancelTrip(
    TravelerTrip trip, {
    DateTime? now,
  }) {
    if (trip.status == TripStatus.openBid &&
        matchingRequestCountForTrip(trip.id) == 0) {
      return true;
    }
    return canTravelerCancelBeforeTravel(trip.travelDate, now: now);
  }

  static bool canSenderCancelBeforeTravel(
    DateTime travelDate, {
    DateTime? now,
  }) =>
      canCancelBeforeTravel(travelDate, now: now);

  /// Booked shipment cancel (sender, traveler, or receiver) through collected
  /// inclusive. Not allowed once in-transit / delivered. Escrow always
  /// refunded; platform fees refunded only when travel is still ≥24h away.
  static bool isBookingCancellable(Shipment shipment) {
    final status = effectiveStatus(shipment);
    if (acceptedBidForShipment(shipment.id) == null &&
        WalletService.escrowCentsForShipment(shipment.id) <= 0) {
      return false;
    }
    return switch (status) {
      ShipmentStatus.bidAccepted ||
      ShipmentStatus.photosUploaded ||
      ShipmentStatus.collected =>
        true,
      _ => false,
    };
  }

  static bool isSenderBookingCancellable(Shipment shipment) =>
      isBookingCancellable(shipment);

  static bool isTravelerBookingCancellable(Shipment shipment) =>
      isBookingCancellable(shipment);

  static bool isReceiverBookingCancellable(Shipment shipment) =>
      isBookingCancellable(shipment);

  static String get travelerCancelBlockedMessage =>
      'Cancellation is only allowed at least '
      '$travelerCancelMinHoursBeforeTravel hours before the flight date.';

  static String get senderCancelBlockedMessage =>
      'Cancellation is only allowed at least '
      '$senderCancelMinHoursBeforeTravel hours before the flight date.';

  static String senderBookingCancelResultMessage({
    required bool platformFeesRefunded,
  }) {
    if (platformFeesRefunded) {
      return 'Booking cancelled. Escrow and platform fees refunded.';
    }
    return 'Booking cancelled. Escrow refunded to sender; platform fees kept.';
  }

  static String travelerBookingCancelResultMessage({
    required bool platformFeesRefunded,
  }) {
    if (platformFeesRefunded) {
      return 'Request cancelled. Escrow and platform fees refunded.';
    }
    return 'Request cancelled. Escrow refunded to sender; platform fees kept.';
  }

  static String receiverBookingCancelResultMessage({
    required bool platformFeesRefunded,
  }) {
    if (platformFeesRefunded) {
      return 'Request cancelled. Escrow and platform fees refunded.';
    }
    return 'Request cancelled. Escrow refunded to sender; platform fees kept.';
  }

  /// Cancels a posted trip when policy allows (≥24h before travel, or
  /// open listing with zero sender requests).
  /// Returns `false` if the trip is missing or cancel is blocked.
  static bool tryCancelTravelerTrip(String tripId) {
    final trip = travelerTripById(tripId);
    if (trip == null) return false;
    if (!canTravelerCancelTrip(trip)) return false;
    cancelTravelerTrip(tripId);
    return true;
  }

  static bool _purgedFranceSenegalTrip = false;

  /// Drops the stuck France→Senegal open listing (0 requests) from live demo state.
  static void purgeFranceSenegalOpenTripOnce() {
    if (_purgedFranceSenegalTrip) return;
    _purgedFranceSenegalTrip = true;
    final ids = travelerPostedTrips
        .where(
          (t) =>
              t.origin == countryToCountryOriginCountry &&
              t.destination == countryToCountryDestinationCountry &&
              t.status == TripStatus.openBid &&
              matchingRequestCountForTrip(t.id) == 0,
        )
        .map((t) => t.id)
        .toList();
    for (final id in ids) {
      cancelTravelerTrip(id);
    }
  }

  /// Rebuilds route-similarity matches for a posted trip against open delivery requests.
  static void rebuildMatchingRequestsForTrip(TravelerTrip trip) {
    matchingRequests.removeWhere((m) => m.tripId == trip.id);

    for (final request in deliveryRequests) {
      final score = RouteSimilarity.scoreTripToRequest(trip, request);
      if (score < 50) continue;
      matchingRequests.add(
        MatchingRequest(
          tripId: trip.id,
          request: request,
          matchScore: score,
        ),
      );
    }

    // Also score against open sender parcels so new trips match live listings.
    for (final shipment in senderShipments.where((s) => s.status == ShipmentStatus.open)) {
      final score = RouteSimilarity.scoreTripToShipment(trip, shipment);
      if (score < 50) continue;
      final already = matchingRequests.any(
        (m) =>
            m.tripId == trip.id &&
            m.request.fromCity == shipment.fromCity &&
            m.request.toCity == shipment.toCity,
      );
      if (already) continue;
      matchingRequests.add(
        MatchingRequest(
          tripId: trip.id,
          request: DeliveryRequest(
            id: 'match-${shipment.id}-${trip.id}',
            fromCity: shipment.fromCity,
            toCity: shipment.toCity,
            travelDate: shipment.travelDate,
            maxBudget: 40,
            category: shipment.parcelCategory,
            weightKg: shipment.parcelWeightKg,
            size: shipment.parcelSize,
            senderName: currentUser.name,
            senderInitial: currentUser.initial,
            senderRating: currentUser.rating,
            description: shipment.description.isEmpty
                ? 'Open parcel on ${shipment.route}'
                : shipment.description,
          ),
          matchScore: score,
        ),
      );
    }

    matchingRequests.sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }

  /// Posted trips discoverable by senders, optionally ranked for a parcel route.
  static List<({TravelerTrip trip, int matchScore})> discoverableTripsForShipment(
    Shipment shipment,
  ) {
    final ranked = travelerPostedTrips
        .map(
          (trip) => (
            trip: trip,
            matchScore: RouteSimilarity.scoreTripToShipment(trip, shipment),
          ),
        )
        .where((e) => e.matchScore >= 50)
        .toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return ranked;
  }

  static List<({TravelerTrip trip, int matchScore})> get allDiscoverableTrips {
    return travelerPostedTrips
        .map((trip) => (trip: trip, matchScore: 100))
        .toList();
  }

  /// Hot routes derived from posted traveler trips (fallback to seeded list).
  static List<HotRoute> get discoverableHotRoutes {
    final grouped = <String, List<TravelerTrip>>{};
    for (final trip in travelerPostedTrips) {
      grouped.putIfAbsent(trip.route, () => []).add(trip);
    }
    if (grouped.isEmpty) return hotRoutes;

    final routes = grouped.entries.map((e) {
      final sample = e.value.first;
      return HotRoute(
        fromCity: sample.origin,
        toCity: sample.destination,
        travelerCount: e.value.length,
        fromPrice: 18,
      );
    }).toList();
    return routes.isEmpty ? hotRoutes : routes;
  }

  static const travelerUser = UserProfile(
    name: 'Aissatou D.',
    email: 'aissatou@email.com',
    phone: '+33 612 345 678',
    countryCode: 'FR',
    rating: 4.9,
    reviewCount: 24,
    walletBalance: 0,
    memberSince: 'Apr 2026',
    bio: 'Regular traveler between Europe and West Africa ✈️',
    isVerified: true,
  );

  static const travelerTotalTripsCompleted = 18;
  static const travelerParcelsDelivered = 16;
  static const travelerTotalDeliveries = 16;
  static const travelerActiveTrips = 2;
  static const travelerSuccessfulDeliveryRate = 96;
  static const travelerAverageRating = 4.9;

  static const countryNames = {
    'FR': 'France',
    'US': 'United States',
    'GB': 'United Kingdom',
    'NG': 'Nigeria',
    'AE': 'United Arab Emirates',
    'CA': 'Canada',
    'SN': 'Senegal',
  };

  static String countryName(String countryCode) =>
      countryNames[countryCode] ?? countryCode;

  static const receiverUser = UserProfile(
    name: 'Amara Okonkwo',
    email: 'amara@email.com',
    phone: '+234 801 234 5678',
    countryCode: 'NG',
    rating: 4.8,
    reviewCount: 6,
    walletBalance: 0,
    memberSince: 'Jun 2026',
    bio: 'Receiving parcels from family abroad 📦',
    isVerified: true,
  );

  /// Minimum wallet balance (USD) required for a receiver to accept a parcel request.
  static const receiverAcceptMinBalanceUsd = 2.0;

  /// Non-refundable platform fee charged when the receiver accepts an incoming request.
  static const receiverIncomingPlatformFeeUsd = 2.0;

  static final incomingParcelRequestsVersion = ValueNotifier<int>(0);

  static final List<IncomingParcelRequest> _incomingParcelRequests = [
    IncomingParcelRequest(
      id: 'WW-61050',
      senderName: 'James O.',
      senderInitial: 'J',
      parcelType: 'Documents',
      weightKg: 0.8,
      pickupLocation: 'London, UK',
      receiverLocation: 'Lagos, Nigeria',
      travelDate: DateTime(2026, 6, 15),
    ),
  ];

  static IncomingParcelRequest get demoIncomingParcelRequest =>
      _incomingParcelRequests.first;

  static IncomingParcelRequest? incomingParcelRequestById(String id) {
    for (final request in _incomingParcelRequests) {
      if (request.id == id) return request;
    }
    return null;
  }

  static List<IncomingParcelRequest> get pendingIncomingParcelRequests =>
      _incomingParcelRequests
          .where((r) => r.status == IncomingParcelRequestStatus.pending)
          .toList(growable: false);

  static bool isIncomingParcelRequestPending(String shipmentId) {
    final request = incomingParcelRequestById(shipmentId);
    return request?.status == IncomingParcelRequestStatus.pending;
  }

  /// Tracking, NFC, chat, and parcel timeline are blocked until the receiver accepts.
  static bool canReceiverAccessParcelFeatures(String shipmentId) {
    final request = incomingParcelRequestById(shipmentId);
    if (request == null) return true;
    return request.status == IncomingParcelRequestStatus.accepted;
  }

  static Shipment? receiverShipmentById(String? shipmentId) {
    if (shipmentId == null || shipmentId.isEmpty) {
      return receiverActiveShipment;
    }
    for (final shipment in receiverShipments) {
      if (shipment.id == shipmentId) return shipment;
    }
    final request = incomingParcelRequestById(shipmentId);
    if (request != null && request.status == IncomingParcelRequestStatus.accepted) {
      return _shipmentFromIncomingRequest(request);
    }
    // Fall back to traveler/sender copy so CP2 deep-links still open tracking.
    final shared = shipmentById(shipmentId, travelerView: true) ??
        shipmentById(shipmentId);
    if (shared == null) return null;
    return shared.copyWith(role: ShipmentRole.receiver);
  }

  static Shipment _shipmentFromIncomingRequest(IncomingParcelRequest request) {
    final parts = request.pickupLocation.split(',');
    final destParts = request.receiverLocation.split(',');
    return Shipment(
      id: request.id,
      fromCity: parts.first.trim(),
      toCity: destParts.first.trim(),
      fromCode: request.pickupLocation.contains('London') ? 'GB' : 'FR',
      toCode: request.receiverLocation.contains('Lagos') ? 'NG' : 'SN',
      travelDate: request.travelDate,
      status: ShipmentStatus.open,
      role: ShipmentRole.receiver,
      parcelCategory: request.parcelType,
      parcelWeightKg: request.weightKg,
      description: 'Parcel from ${request.senderName}',
    );
  }

  static String? validateReceiverIncomingAccept(String requestId) {
    final request = incomingParcelRequestById(requestId);
    if (request == null) return 'Parcel request not found.';
    if (request.status != IncomingParcelRequestStatus.pending) {
      return 'This request has already been handled.';
    }
    if (WalletService.availableUsd(WalletRole.receiver) <
        receiverAcceptMinBalanceUsd) {
      return 'You need at least \$${receiverAcceptMinBalanceUsd.toStringAsFixed(0)} in your wallet to accept this request.';
    }
    return null;
  }

  static bool acceptIncomingParcelRequest(String requestId) {
    final error = validateReceiverIncomingAccept(requestId);
    if (error != null) return false;

    final index = _incomingParcelRequests.indexWhere((r) => r.id == requestId);
    if (index < 0) return false;

    final request = _incomingParcelRequests[index];
    final feeCents = (receiverIncomingPlatformFeeUsd * 100).round();
    if (!WalletService.ensureAvailableWithCardFallback(
      role: WalletRole.receiver,
      amountCents: feeCents,
    )) {
      return false;
    }
    if (!WalletService.chargePlatformFee(
      role: WalletRole.receiver,
      shipmentId: requestId,
      amountCents: feeCents,
      description: '$requestId · Platform fee',
    )) {
      return false;
    }

    _incomingParcelRequests[index] =
        request.copyWith(status: IncomingParcelRequestStatus.accepted);

    final shipment = _shipmentFromIncomingRequest(request);
    if (!receiverShipments.any((s) => s.id == shipment.id)) {
      receiverShipments.insert(0, shipment);
    }
    incomingParcelRequestsVersion.value++;
    nfcCheckpointVersion.value++;

    NotificationService.push(
      AppNotification(
        id: 'rcv-accepted-$requestId',
        role: WalletRole.receiver,
        type: AppNotificationType.deliveryStatus,
        title: 'Parcel request accepted',
        body:
            'You accepted ${request.senderName}\'s parcel request. We will match a traveler and notify you.',
        time: 'Just now',
        route: '/receiver-tracking?shipmentId=$requestId',
      ),
    );
    return true;
  }

  static void rejectIncomingParcelRequest(String requestId) {
    final index = _incomingParcelRequests.indexWhere((r) => r.id == requestId);
    if (index < 0) return;
    final request = _incomingParcelRequests[index];
    if (request.status != IncomingParcelRequestStatus.pending) return;

    _incomingParcelRequests[index] =
        request.copyWith(status: IncomingParcelRequestStatus.rejected);
    incomingParcelRequestsVersion.value++;
  }

  static final receiverActiveShipment = Shipment(
    id: 'WW-48291',
    fromCity: 'Paris',
    toCity: 'Dakar',
    fromCode: 'FR',
    toCode: 'SN',
    travelDate: DateTime(2026, 7, 26),
    status: ShipmentStatus.bidAccepted,
    role: ShipmentRole.receiver,
    parcelCategory: 'Documents',
    parcelWeightKg: 0.8,
    parcelSize: 'small box',
    description: 'Legal documents from notary office',
    travelerName: 'Aissatou D.',
    flightNumber: 'AF718',
  );

  /// Static preview flag — NFC delivery confirmed for WW-48291 across all roles.
  static bool nfcDeliveryConfirmed = false;

  /// Bumps when NFC checkpoint / shipment handoff state changes (UI refresh).
  static final nfcCheckpointVersion = ValueNotifier(0);

  /// Shipments where sender marked "Parcel Handed to Traveler" — NFC CP1 is open
  /// for both sender and traveler. Starts empty; only sender can activate.
  static final nfcCheckpoint1ActivatedShipmentIds = <String>{};

  /// Per-party CP1 taps — both required before handoff completes.
  static final nfcCheckpoint1SenderConfirmedIds = <String>{};
  static final nfcCheckpoint1TravelerConfirmedIds = <String>{};

  /// Shipments where NFC Checkpoint 1 (sender↔traveler handoff) is complete.
  /// Cancel-demo WW-74012 is Collected but CP1 already done (no NFC UI).
  static final nfcCheckpoint1ConfirmedShipmentIds = <String>{
    'WW-74012',
  };

  /// Traveler selected Delivered while In Transit — unlocks NFC CP2.
  static final nfcCheckpoint2ActivatedShipmentIds = <String>{};

  /// Per-party CP2 taps — both traveler + receiver required before delivery completes.
  static final nfcCheckpoint2TravelerConfirmedIds = <String>{};
  static final nfcCheckpoint2ReceiverConfirmedIds = <String>{};

  /// Shipments where NFC Checkpoint 2 (traveler↔receiver delivery) is complete.
  static final nfcCheckpoint2ConfirmedShipmentIds = <String>{};

  static bool isNfcCheckpoint1Confirmed(String shipmentId) =>
      nfcCheckpoint1ConfirmedShipmentIds.contains(shipmentId);

  static bool isNfcCheckpoint1Activated(String shipmentId) =>
      nfcCheckpoint1ActivatedShipmentIds.contains(shipmentId) &&
      !isNfcCheckpoint1Confirmed(shipmentId);

  static bool isNfcCheckpoint1SenderTapped(String shipmentId) =>
      nfcCheckpoint1SenderConfirmedIds.contains(shipmentId);

  static bool isNfcCheckpoint1TravelerTapped(String shipmentId) =>
      nfcCheckpoint1TravelerConfirmedIds.contains(shipmentId);

  static bool isNfcCheckpoint2Confirmed(String shipmentId) =>
      nfcCheckpoint2ConfirmedShipmentIds.contains(shipmentId);

  static bool isNfcCheckpoint2TravelerTapped(String shipmentId) =>
      nfcCheckpoint2TravelerConfirmedIds.contains(shipmentId);

  static bool isNfcCheckpoint2ReceiverTapped(String shipmentId) =>
      nfcCheckpoint2ReceiverConfirmedIds.contains(shipmentId);

  /// CP2 unlocks after CP1 is done and traveler selected Delivered
  /// (see [activateNfcCheckpoint2]). Do not gate on a single role's shipment
  /// copy — sender/traveler/receiver may seed different statuses for the same ID.
  static bool isNfcCheckpoint2Available(String shipmentId) {
    if (isNfcCheckpoint2Confirmed(shipmentId)) return false;
    if (!isNfcCheckpoint1Confirmed(shipmentId)) return false;
    return nfcCheckpoint2ActivatedShipmentIds.contains(shipmentId);
  }

  static bool isNfcCheckpoint2Activated(String shipmentId) =>
      nfcCheckpoint2ActivatedShipmentIds.contains(shipmentId) &&
      !isNfcCheckpoint2Confirmed(shipmentId);

  /// Traveler enables NFC Checkpoint 2 for the receiver while In Transit.
  /// Status stays In Transit until both traveler and receiver complete NFC matching.
  static void activateNfcCheckpoint2(String shipmentId) {
    if (isNfcCheckpoint2Confirmed(shipmentId)) return;
    if (!isNfcCheckpoint1Confirmed(shipmentId)) return;
    final alreadyActive = nfcCheckpoint2ActivatedShipmentIds.contains(shipmentId);
    nfcCheckpoint2ActivatedShipmentIds.add(shipmentId);
    // Keep all role copies on In Transit until both parties finish NFC CP2.
    _statusOverridesByShipmentId[shipmentId] = ShipmentStatus.inTransit;
    _applyStatusToShipmentLists(shipmentId, ShipmentStatus.inTransit);
    _ensureReceiverCanTrackShipment(shipmentId);
    nfcCheckpointVersion.value++;
    bidRequestsVersion.value++;
    if (!alreadyActive) {
      _notifyNfcCheckpoint2Activated(shipmentId);
    }
  }

  /// Make sure the receiver My Shipments / Track list includes this parcel.
  static void _ensureReceiverCanTrackShipment(String shipmentId) {
    for (final shipment in receiverShipments) {
      if (shipment.id == shipmentId) return;
    }
    final source = shipmentById(shipmentId, travelerView: true) ??
        shipmentById(shipmentId);
    if (source == null) return;
    receiverShipments.insert(
      0,
      source.copyWith(
        role: ShipmentRole.receiver,
        status: ShipmentStatus.inTransit,
      ),
    );
  }

  static void _notifyNfcCheckpoint2Activated(String shipmentId) {
    NotificationService.push(
      AppNotification(
        id: 'trv-cp2-ready-$shipmentId',
        role: WalletRole.traveler,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 2 ready',
        body: 'Meet the receiver and complete NFC delivery for $shipmentId.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-cp2-ready-$shipmentId',
        role: WalletRole.receiver,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 2 ready',
        body: 'Traveler is ready to hand off $shipmentId. Complete NFC Checkpoint 2.',
        time: 'Just now',
        route: '/receiver-tracking?shipmentId=$shipmentId',
      ),
    );
  }

  /// Sender enables NFC Checkpoint 1 at meetup.
  /// Unlocks NFC for sender and traveler; status stays Traveler Selected until
  /// both parties complete NFC matching, then becomes Collected.
  static void activateNfcCheckpoint1(String shipmentId) {
    if (isNfcCheckpoint1Confirmed(shipmentId)) return;
    final alreadyActive = nfcCheckpoint1ActivatedShipmentIds.contains(shipmentId);
    nfcCheckpoint1ActivatedShipmentIds.add(shipmentId);
    nfcCheckpointVersion.value++;
    bidRequestsVersion.value++;
    if (!alreadyActive) {
      _notifyNfcCheckpoint1Activated(shipmentId);
    }
  }

  static void _notifyNfcCheckpoint1Activated(String shipmentId) {
    NotificationService.push(
      AppNotification(
        id: 'snd-cp1-ready-$shipmentId',
        role: WalletRole.sender,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 1 ready',
        body:
            'NFC is enabled for $shipmentId. Complete NFC matching with the traveler to mark Collected.',
        time: 'Just now',
        route: '/shipment/$shipmentId',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-cp1-ready-$shipmentId',
        role: WalletRole.traveler,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 1 ready',
        body:
            'Sender enabled NFC for $shipmentId. Complete NFC matching to confirm handoff and mark Collected.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
  }

  /// One party completes their NFC CP1 tap. When both have tapped: mark CP1 done
  /// and set status to Collected.
  /// Requires sender to have enabled NFC first ([activateNfcCheckpoint1]).
  /// Traveler can tap only after the sender has completed their NFC tap.
  /// Returns `true` when both parties are done and CP1 is fully confirmed.
  static bool confirmNfcCheckpoint1Party(
    String shipmentId, {
    required bool isTraveler,
  }) {
    if (isNfcCheckpoint1Confirmed(shipmentId)) return true;

    final shipment = shipmentById(shipmentId, travelerView: isTraveler) ??
        shipmentById(shipmentId);
    if (shipment == null) return false;

    // NFC must be enabled by sender first (or already Collected for legacy seeds).
    final status = effectiveStatus(shipment);
    final nfcEnabled = nfcCheckpoint1ActivatedShipmentIds.contains(shipmentId) ||
        status == ShipmentStatus.collected;
    if (!nfcEnabled) return false;

    if (isTraveler) {
      if (!isNfcCheckpoint1SenderTapped(shipmentId)) return false;
      nfcCheckpoint1TravelerConfirmedIds.add(shipmentId);
    } else {
      final firstSenderTap = !isNfcCheckpoint1SenderTapped(shipmentId);
      nfcCheckpoint1SenderConfirmedIds.add(shipmentId);
      nfcCheckpoint1ActivatedShipmentIds.add(shipmentId);
      if (firstSenderTap) {
        _notifyTravelerNfcCheckpoint1Ready(shipmentId);
      }
    }
    nfcCheckpointVersion.value++;

    final bothReady = isNfcCheckpoint1SenderTapped(shipmentId) &&
        isNfcCheckpoint1TravelerTapped(shipmentId);
    if (!bothReady) return false;

    confirmNfcHandoffCheckpoint1(shipmentId);
    return true;
  }

  static void _notifyTravelerNfcCheckpoint1Ready(String shipmentId) {
    NotificationService.push(
      AppNotification(
        id: 'trv-cp1-ready-$shipmentId',
        role: WalletRole.traveler,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 1 ready',
        body:
            'Sender completed their NFC tap for $shipmentId. Complete NFC Checkpoint 1 on your side to mark Collected.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
  }

  /// NFC Checkpoint 1 complete — both parties matched; status becomes Collected.
  static void confirmNfcHandoffCheckpoint1(String shipmentId) {
    if (isNfcCheckpoint1Confirmed(shipmentId)) return;
    nfcCheckpoint1ActivatedShipmentIds.add(shipmentId);
    nfcCheckpoint1SenderConfirmedIds.add(shipmentId);
    nfcCheckpoint1TravelerConfirmedIds.add(shipmentId);
    nfcCheckpoint1ConfirmedShipmentIds.add(shipmentId);
    setShipmentStatus(
      shipmentId,
      ShipmentStatus.collected,
      skipEscrowSideEffects: true,
      skipNotification: true,
    );
    nfcCheckpointVersion.value++;
    _notifyNfcCheckpoint1(shipmentId);
  }

  static void _notifyNfcCheckpoint1(String shipmentId) {
    NotificationService.push(
      AppNotification(
        id: 'snd-cp1-$shipmentId',
        role: WalletRole.sender,
        type: AppNotificationType.nfcPrompt,
        title: 'NFC Checkpoint 1 complete',
        body:
            'Handoff confirmed for $shipmentId via NFC. Parcel is now Collected. Traveler can mark In Transit when ready.',
        time: 'Just now',
        route: '/shipment/$shipmentId',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-cp1-$shipmentId',
        role: WalletRole.traveler,
        type: AppNotificationType.nfcPrompt,
        title: 'Parcel Collected',
        body:
            'NFC matching complete for $shipmentId. Status is Collected — mark In Transit when you begin travel.',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-cp1-$shipmentId',
        role: WalletRole.receiver,
        type: AppNotificationType.nfcPrompt,
        title: 'Parcel collected',
        body:
            'Handoff confirmed for $shipmentId. Traveler will mark In Transit, then enable NFC for final delivery.',
        time: 'Just now',
        route: '/receiver-tracking?shipmentId=$shipmentId',
      ),
    );
  }

  /// One party completes their NFC CP2 tap. When both have tapped: mark CP2 done,
  /// set status to Delivered, release escrow, and enable Leave Review.
  /// Returns `true` when both parties are done and CP2 is fully confirmed.
  static bool confirmNfcCheckpoint2Party(
    String shipmentId, {
    required bool isTraveler,
  }) {
    if (isNfcCheckpoint2Confirmed(shipmentId)) return true;
    if (!isNfcCheckpoint2Available(shipmentId) &&
        !isNfcCheckpoint2TravelerTapped(shipmentId) &&
        !isNfcCheckpoint2ReceiverTapped(shipmentId)) {
      return false;
    }

    if (isTraveler) {
      nfcCheckpoint2TravelerConfirmedIds.add(shipmentId);
    } else {
      nfcCheckpoint2ReceiverConfirmedIds.add(shipmentId);
    }
    nfcCheckpointVersion.value++;

    final bothReady = isNfcCheckpoint2TravelerTapped(shipmentId) &&
        isNfcCheckpoint2ReceiverTapped(shipmentId);
    if (!bothReady) return false;

    confirmNfcDelivery(shipmentId);
    return true;
  }

  /// NFC Checkpoint 2 complete — marks CP2 done, sets Delivered, releases escrow.
  static void confirmNfcDelivery(String shipmentId) {
    if (isNfcCheckpoint2Confirmed(shipmentId) &&
        nfcCheckpoint2ConfirmedShipmentIds.contains(shipmentId)) {
      return;
    }
    nfcCheckpoint2ActivatedShipmentIds.add(shipmentId);
    nfcCheckpoint2TravelerConfirmedIds.add(shipmentId);
    nfcCheckpoint2ReceiverConfirmedIds.add(shipmentId);
    nfcCheckpoint2ConfirmedShipmentIds.add(shipmentId);
    nfcDeliveryConfirmed = true;
    setShipmentStatus(shipmentId, ShipmentStatus.delivered, skipNotification: true);
    nfcCheckpointVersion.value++;
    _notifyDeliveryComplete(shipmentId);
  }

  static void _notifyDeliveryComplete(String shipmentId) {
    NotificationService.push(
      AppNotification(
        id: 'snd-del-$shipmentId',
        role: WalletRole.sender,
        type: AppNotificationType.deliveryStatus,
        title: 'Parcel delivered',
        body: '$shipmentId was delivered. Leave a review for your traveler.',
        time: 'Just now',
        route: '/delivery-review',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-pay-$shipmentId',
        role: WalletRole.traveler,
        type: AppNotificationType.deliveryStatus,
        title: 'Payout released',
        body: 'Escrow for $shipmentId released to your wallet.',
        time: 'Just now',
        route: '/wallet?role=traveler',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-del-$shipmentId',
        role: WalletRole.receiver,
        type: AppNotificationType.deliveryStatus,
        title: 'Parcel received',
        body: 'Delivery confirmed for $shipmentId via NFC Checkpoint 2. You can leave a review.',
        time: 'Just now',
        route: '/delivery-review',
      ),
    );
  }

  static final _disputedShipmentIds = <String>{};

  static bool isShipmentDisputed(String shipmentId) =>
      _disputedShipmentIds.contains(shipmentId) ||
      _statusOverridesByShipmentId[shipmentId] == ShipmentStatus.disputed;

  /// Freeze escrow and mark shipment disputed.
  ///
  /// Dispute is tracked as an overlay ([_disputedShipmentIds]) so the lifecycle
  /// badge (Open / Traveler Selected / …) stays in sync with My Shipments / timeline.
  static void fileDispute(String shipmentId, {String? reason}) {
    _disputedShipmentIds.add(shipmentId);
    // Drop a stale disputed override so badges keep the real lifecycle status.
    if (_statusOverridesByShipmentId[shipmentId] == ShipmentStatus.disputed) {
      _statusOverridesByShipmentId.remove(shipmentId);
    }
    WalletService.freezeEscrow(
      role: WalletRole.sender,
      shipmentId: shipmentId,
      description: reason ?? '$shipmentId · Dispute filed',
    );
    nfcCheckpointVersion.value++;
    bidRequestsVersion.value++;
    NotificationService.pushToRoles(
      roles: [WalletRole.sender, WalletRole.traveler, WalletRole.receiver],
      type: AppNotificationType.general,
      title: 'Dispute filed',
      body: 'Escrow frozen on $shipmentId pending investigation.',
      route: '/shipment/$shipmentId',
    );
  }

  /// Sender cancellation before in-transit / delivered.
  /// Always refunds escrow principal. Platform fees are refunded to all parties
  /// when travel is still ≥24h away; otherwise fees are kept.
  /// Returns `false` if the shipment cannot be cancelled.
  static bool cancelShipmentBooking(String shipmentId) =>
      _cancelBookedShipment(
        shipmentId: shipmentId,
        cancelledBy: WalletRole.sender,
      );

  /// Traveler cancellation before in-transit / delivered — same escrow / fee
  /// rules as [cancelShipmentBooking], including when the parcel is collected.
  static bool cancelTravelerBooking(String shipmentId) =>
      _cancelBookedShipment(
        shipmentId: shipmentId,
        cancelledBy: WalletRole.traveler,
      );

  /// Receiver cancellation before in-transit / delivered — same escrow / fee
  /// rules as [cancelShipmentBooking], including when the parcel is collected.
  static bool cancelReceiverBooking(String shipmentId) =>
      _cancelBookedShipment(
        shipmentId: shipmentId,
        cancelledBy: WalletRole.receiver,
      );

  static bool _cancelBookedShipment({
    required String shipmentId,
    required WalletRole cancelledBy,
  }) {
    final shipment = shipmentById(shipmentId) ??
        receiverShipmentById(shipmentId);
    if (shipment == null) return false;
    if (!isBookingCancellable(shipment)) return false;

    final refundPlatformFee =
        isPlatformFeeRefundableOnCancel(shipment.travelDate);
    final reason = switch (cancelledBy) {
      WalletRole.traveler => 'Shipment cancelled by traveler',
      WalletRole.receiver => 'Shipment cancelled by receiver',
      WalletRole.sender => 'Shipment cancelled by sender',
    };

    refundEscrowOnCancellation(
      shipmentId: shipmentId,
      reason: reason,
      refundPlatformFee: refundPlatformFee,
    );
    paysReceiverFeeByShipmentId.remove(shipmentId);
    lockedShipmentIds.remove(shipmentId);
    acceptedBidsByShipmentId.remove(shipmentId);
    setShipmentStatus(
      shipmentId,
      ShipmentStatus.open,
      skipEscrowSideEffects: true,
      skipNotification: true,
    );
    bidRequestsVersion.value++;

    final feeNoteRefunded = refundPlatformFee
        ? 'Escrow and platform fees refunded.'
        : 'Escrow refunded; platform fees kept.';
    final otherFeeNote = refundPlatformFee
        ? 'Your platform fee was refunded.'
        : 'Platform fees are non-refundable.';

    switch (cancelledBy) {
      case WalletRole.traveler:
        NotificationService.push(
          AppNotification(
            id: 'trv-cancel-booking-$shipmentId',
            role: WalletRole.traveler,
            type: AppNotificationType.cancellation,
            title: 'Request cancelled',
            body: 'You cancelled $shipmentId. $feeNoteRefunded',
            time: 'Just now',
            route: '/traveler-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'snd-cancel-booking-$shipmentId',
            role: WalletRole.sender,
            type: AppNotificationType.cancellation,
            title: 'Delivery cancelled',
            body:
                'Traveler cancelled shipment $shipmentId. Escrow was refunded. $otherFeeNote',
            time: 'Just now',
            route: '/sender-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'rcv-cancel-booking-$shipmentId',
            role: WalletRole.receiver,
            type: AppNotificationType.cancellation,
            title: 'Shipment cancelled',
            body: 'Traveler cancelled $shipmentId. $otherFeeNote',
            time: 'Just now',
            route: '/receiver-notifications',
          ),
        );
      case WalletRole.receiver:
        NotificationService.push(
          AppNotification(
            id: 'rcv-cancel-booking-$shipmentId',
            role: WalletRole.receiver,
            type: AppNotificationType.cancellation,
            title: 'Request cancelled',
            body: 'You cancelled $shipmentId. $feeNoteRefunded',
            time: 'Just now',
            route: '/receiver-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'snd-cancel-booking-$shipmentId',
            role: WalletRole.sender,
            type: AppNotificationType.cancellation,
            title: 'Delivery cancelled',
            body:
                'Receiver cancelled shipment $shipmentId. Escrow was refunded. $otherFeeNote',
            time: 'Just now',
            route: '/sender-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'trv-cancel-booking-$shipmentId',
            role: WalletRole.traveler,
            type: AppNotificationType.cancellation,
            title: 'Delivery cancelled',
            body: 'Receiver cancelled shipment $shipmentId. $otherFeeNote',
            time: 'Just now',
            route: '/traveler-notifications',
          ),
        );
      case WalletRole.sender:
        NotificationService.push(
          AppNotification(
            id: 'snd-cancel-booking-$shipmentId',
            role: WalletRole.sender,
            type: AppNotificationType.cancellation,
            title: 'Booking cancelled',
            body: 'You cancelled $shipmentId. $feeNoteRefunded',
            time: 'Just now',
            route: '/sender-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'trv-cancel-booking-$shipmentId',
            role: WalletRole.traveler,
            type: AppNotificationType.cancellation,
            title: 'Delivery cancelled',
            body: 'Sender cancelled shipment $shipmentId. $otherFeeNote',
            time: 'Just now',
            route: '/traveler-notifications',
          ),
        );
        NotificationService.push(
          AppNotification(
            id: 'rcv-cancel-booking-$shipmentId',
            role: WalletRole.receiver,
            type: AppNotificationType.cancellation,
            title: 'Shipment cancelled',
            body: 'Sender cancelled $shipmentId. $otherFeeNote',
            time: 'Just now',
            route: '/receiver-notifications',
          ),
        );
    }
    return true;
  }

  static void refundEscrowOnCancellation({
    required String shipmentId,
    required String reason,
    required bool refundPlatformFee,
  }) {
    WalletService.refundEscrow(
      role: WalletRole.sender,
      shipmentId: shipmentId,
      description: reason,
    );
    if (refundPlatformFee) {
      WalletService.refundAllPlatformFeesForShipment(shipmentId);
    }
    lockedShipmentIds.remove(shipmentId);
    acceptedBidsByShipmentId.remove(shipmentId);
  }

  static final _statusOverridesByShipmentId = <String, ShipmentStatus>{};

  static void setShipmentStatus(
    String shipmentId,
    ShipmentStatus status, {
    bool skipEscrowSideEffects = false,
    bool skipNotification = false,
  }) {
    // Dispute is an overlay flag, not a lifecycle status replacement.
    if (status == ShipmentStatus.disputed) {
      fileDispute(shipmentId);
      return;
    }
    _statusOverridesByShipmentId[shipmentId] = status;
    _applyStatusToShipmentLists(shipmentId, status);
    if (status == ShipmentStatus.photosUploaded ||
        status == ShipmentStatus.collected ||
        status == ShipmentStatus.inTransit ||
        status == ShipmentStatus.delivered) {
      photoUploadCompletionConfirmed = true;
    }
    if (!skipEscrowSideEffects && status == ShipmentStatus.delivered) {
      releaseEscrowOnDelivery(shipmentId);
    }
    nfcCheckpointVersion.value++;
    bidRequestsVersion.value++;
    if (!skipNotification) {
      _notifyShipmentStatusChange(shipmentId, status);
    }
  }

  static void _applyStatusToShipmentLists(String shipmentId, ShipmentStatus status) {
    void patch(List<Shipment> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].id == shipmentId) {
          list[i] = list[i].copyWith(status: status);
        }
      }
    }

    patch(senderShipments);
    patch(shipments);
    // Keep receiver tracking / My Shipments in sync when traveler updates status.
    patch(receiverShipments);
  }

  static void _notifyShipmentStatusChange(String shipmentId, ShipmentStatus status) {
    final label = status.label;
    NotificationService.push(
      AppNotification(
        id: 'snd-st-$shipmentId-${status.name}',
        role: WalletRole.sender,
        type: AppNotificationType.deliveryStatus,
        title: 'Shipment update',
        body: '$shipmentId is now: $label',
        time: 'Just now',
        route: '/shipment/$shipmentId',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'trv-st-$shipmentId-${status.name}',
        role: WalletRole.traveler,
        type: AppNotificationType.deliveryStatus,
        title: 'Shipment update',
        body: '$shipmentId is now: $label',
        time: 'Just now',
        route: '/shipment/$shipmentId?traveler=true',
      ),
    );
    NotificationService.push(
      AppNotification(
        id: 'rcv-st-$shipmentId-${status.name}',
        role: WalletRole.receiver,
        type: AppNotificationType.deliveryStatus,
        title: 'Shipment update',
        body: '$shipmentId is now: $label',
        time: 'Just now',
        route: '/receiver-tracking',
      ),
    );
    if (status == ShipmentStatus.inTransit) {
      NotificationService.push(
        AppNotification(
          id: 'trv-nfc2-prompt-$shipmentId',
          role: WalletRole.traveler,
          type: AppNotificationType.nfcPrompt,
          title: 'Ready for delivery',
          body:
              'When you meet the receiver, enable NFC for $shipmentId to unlock Checkpoint 2.',
          time: 'Just now',
          route: '/shipment/$shipmentId?traveler=true',
        ),
      );
      NotificationService.push(
        AppNotification(
          id: 'rcv-nfc2-prompt-$shipmentId',
          role: WalletRole.receiver,
          type: AppNotificationType.nfcPrompt,
          title: 'Parcel in transit',
          body:
              '$shipmentId is in transit. NFC Checkpoint 2 unlocks when the traveler enables NFC for you.',
          time: 'Just now',
          route: '/receiver-tracking?shipmentId=$shipmentId',
        ),
      );
    }
  }

  static final _escrowReleasedShipmentIds = <String>{};

  /// Release sender escrow to traveler wallet when delivery completes (NFC CP2).
  static void releaseEscrowOnDelivery(String shipmentId) {
    if (_escrowReleasedShipmentIds.contains(shipmentId)) return;
    if (isShipmentDisputed(shipmentId)) return;
    if (WalletService.isEscrowFrozen(shipmentId)) return;
    final bid = acceptedBidForShipment(shipmentId);
    if (bid == null) return;

    final released = WalletService.releaseEscrowToTraveler(
      senderRole: WalletRole.sender,
      travelerRole: WalletRole.traveler,
      shipmentId: shipmentId,
      description: '$shipmentId · Delivery payout',
    );
    if (released) {
      _escrowReleasedShipmentIds.add(shipmentId);
    }
  }

  static int escrowCentsForShipment(String shipmentId) =>
      WalletService.escrowCentsForShipment(shipmentId);

  static ShipmentStatus effectiveStatus(Shipment shipment) {
    final overridden = _statusOverridesByShipmentId[shipment.id];
    // Disputed is an overlay flag — do not replace the lifecycle badge/timeline.
    if (overridden != null && overridden != ShipmentStatus.disputed) {
      return overridden;
    }
    if (isNfcCheckpoint2Confirmed(shipment.id)) {
      return ShipmentStatus.delivered;
    }
    return shipment.status;
  }

  static int effectiveStepIndex(Shipment shipment) {
    final status = effectiveStatus(shipment);
    if (status == ShipmentStatus.open &&
        receiverAcceptedShipmentIds.contains(shipment.id)) {
      return 2;
    }
    return switch (status) {
      ShipmentStatus.open => 1,
      ShipmentStatus.receiverAccepted => 2,
      ShipmentStatus.bidAccepted => 2,
      ShipmentStatus.photosUploaded => 2,
      ShipmentStatus.collected => 3,
      ShipmentStatus.inTransit => 4,
      ShipmentStatus.delivered => 5,
      ShipmentStatus.disputed => 2,
    };
  }

  static const receiverReceivedShipmentCount = 6;

  static ProfileTrustMetrics get senderTrustMetrics => ProfileTrustMetrics(
        completedDeliveries: senderCompletedShipmentCount,
        cancellationRate: 3.1,
        disputeRate: 0.6,
      );

  static const travelerTrustMetrics = ProfileTrustMetrics(
    completedDeliveries: travelerTotalDeliveries,
    cancellationRate: 2.4,
    disputeRate: 1.2,
  );

  static const receiverTrustMetrics = ProfileTrustMetrics(
    completedDeliveries: receiverReceivedShipmentCount,
    cancellationRate: 1.8,
    disputeRate: 0.4,
  );

  static final securityLogs = <SecurityLogEntry>[
    SecurityLogEntry(
      action: 'Signed in with password',
      device: 'iPhone 15 · WWNGO App',
      location: 'Paris, FR',
      timestamp: DateTime(2026, 7, 8, 9, 14),
    ),
    SecurityLogEntry(
      action: 'Biometric login enabled',
      device: 'iPhone 15 · WWNGO App',
      location: 'Paris, FR',
      timestamp: DateTime(2026, 7, 7, 18, 42),
    ),
    SecurityLogEntry(
      action: 'Email verified',
      device: 'Chrome · Web',
      location: 'Paris, FR',
      timestamp: DateTime(2026, 7, 6, 11, 5),
    ),
    SecurityLogEntry(
      action: 'Phone number linked',
      device: 'WWNGO App',
      location: 'Paris, FR',
      timestamp: DateTime(2026, 7, 6, 11, 8),
    ),
    SecurityLogEntry(
      action: 'Password changed',
      device: 'iPhone 15 · WWNGO App',
      location: 'Lyon, FR',
      timestamp: DateTime(2026, 6, 28, 16, 20),
    ),
  ];

  /// Receiver cancel demo — collected, ≥24h before flight (escrow + fees refunded).
  static final receiverCancelDemoFar = Shipment(
    id: 'WW-74021',
    fromCity: 'Berlin',
    toCity: 'Lagos',
    fromCode: 'DE',
    toCode: 'NG',
    travelDate: DateTime.now().add(const Duration(days: 4)),
    status: ShipmentStatus.collected,
    role: ShipmentRole.receiver,
    parcelCategory: 'Documents',
    parcelWeightKg: 0.6,
    parcelSize: 'envelope',
    description: 'Receiver cancel demo · collected ≥24h before flight',
    travelerName: 'Amara O.',
    flightNumber: 'LH562',
  );

  /// Incoming demo list: one Traveler Selected ([receiverActiveShipment]) plus
  /// the Collected cancel demo — avoids duplicate Traveler Selected cards.
  static final receiverShipments = [
    receiverActiveShipment,
    receiverCancelDemoFar,
  ];

  /// Keeps a single Traveler Selected card on the receiver Incoming list.
  /// Prefers [receiverActiveShipment]; drops other [ShipmentStatus.bidAccepted].
  static void purgeExtraReceiverTravelerSelected() {
    final preferredId = receiverActiveShipment.id;
    final travelerSelected = receiverShipments
        .where((s) => effectiveStatus(s) == ShipmentStatus.bidAccepted)
        .toList();
    if (travelerSelected.length <= 1) return;

    final keepId = travelerSelected.any((s) => s.id == preferredId)
        ? preferredId
        : travelerSelected.first.id;

    receiverShipments.removeWhere(
      (s) =>
          effectiveStatus(s) == ShipmentStatus.bidAccepted && s.id != keepId,
    );
    nfcCheckpointVersion.value++;
  }

  /// Traveler-side counter offers (Counter Offers Sent screen).
  static final travelerBids = <TravelerBid>[];

  static final travelerBidsVersion = ValueNotifier(0);

  static var _nextTravelerBidId = 4;

  /// Minimum wallet balance required to submit a traveler bid.
  static const travelerBidMinBalanceUsd = 2.0;

  static TravelerTrip? compatibleTripForRequest(DeliveryRequest request) {
    TravelerTrip? best;
    var bestScore = 0;
    for (final trip in travelerPostedTrips) {
      final score = RouteSimilarity.scoreTripToRequest(trip, request);
      if (score >= 50 && score > bestScore) {
        best = trip;
        bestScore = score;
      }
    }
    return best;
  }

  /// Returns null when valid, otherwise an error message.
  static String? validateTravelerBid({
    required DeliveryRequest request,
    required double amount,
    String? tripId,
    AuthUser? authUser,
  }) {
    final kycError = validateKycApproved(authUser);
    if (kycError != null) return kycError;

    if (amount <= 0) {
      return 'Enter a valid bid amount.';
    }
    if (amount > request.maxBudget) {
      return 'Bid cannot exceed sender max budget (\$${request.maxBudget.toStringAsFixed(2)}).';
    }
    final balance = WalletService.availableUsd(WalletRole.traveler);
    if (balance < travelerBidMinBalanceUsd) {
      return 'Wallet must have at least \$${travelerBidMinBalanceUsd.toStringAsFixed(0)} to place a bid.';
    }

    if (tripId != null) {
      final trip = travelerTripById(tripId);
      if (trip == null) return 'Trip route is required for this bid.';
      final score = RouteSimilarity.scoreTripToRequest(trip, request);
      if (score < 50) {
        return 'Bid route is not compatible with this parcel request.';
      }
    } else {
      final compatibleTrip = compatibleTripForRequest(request);
      if (compatibleTrip == null) {
        return 'No compatible posted trip found for this route.';
      }
    }
    return null;
  }

  static void submitTravelerBid({
    required String requestId,
    required String tripId,
    required DeliveryRequest request,
    required double amount,
    AuthUser? authUser,
  }) {
    if (travelerBidForRequest(requestId) != null) return;
    final error = validateTravelerBid(
      request: request,
      amount: amount,
      tripId: tripId,
      authUser: authUser,
    );
    if (error != null) return;

    travelerBids.add(
      TravelerBid(
        id: 'tb-$_nextTravelerBidId',
        requestId: requestId,
        tripId: tripId,
        senderName: request.senderName,
        senderInitial: request.senderInitial,
        fromCity: request.fromCity,
        toCity: request.toCity,
        deliveryDate: request.travelDate,
        amount: amount,
        status: TravelerBidStatus.pending,
        sentAt: DateTime.now(),
        parcelPhotoCount: request.photoCount,
      ),
    );
    _nextTravelerBidId++;
    travelerBidsVersion.value++;
  }

  static TravelerBid? travelerBidForRequest(String requestId) {
    for (final bid in travelerBids) {
      if (bid.requestId == requestId) return bid;
    }
    return null;
  }

  static TravelerBid? travelerBidById(String id) {
    for (final bid in travelerBids) {
      if (bid.id == id) return bid;
    }
    return null;
  }

  /// Upserts an API-backed counter offer into the local traveler bids list.
  static void upsertTravelerBid(TravelerBid offer) {
    final byId = travelerBids.indexWhere((b) => b.id == offer.id);
    if (byId >= 0) {
      travelerBids[byId] = offer;
      travelerBidsVersion.value++;
      return;
    }
    final byRequest =
        travelerBids.indexWhere((b) => b.requestId == offer.requestId);
    if (byRequest >= 0) {
      travelerBids[byRequest] = offer;
      travelerBidsVersion.value++;
      return;
    }
    travelerBids.insert(0, offer);
    travelerBidsVersion.value++;
  }

  /// Replaces local traveler bids with the latest API list (keeps order).
  static void syncTravelerBidsFromApi(List<TravelerBid> offers) {
    travelerBids
      ..clear()
      ..addAll(offers);
    travelerBidsVersion.value++;
  }

  static const travelerChatMessages = [
    ChatMessage(
      text: 'Hi James! Thanks for accepting my bid. I can meet at Heathrow on the delivery date.',
      isMine: true,
      time: '2:30 PM',
    ),
    ChatMessage(
      text: 'Great! Please message me when you arrive so we can coordinate the handover.',
      isMine: false,
      time: '2:32 PM',
    ),
    ChatMessage(
      text: 'Will do. I always pack parcels carefully — happy to share a photo if needed.',
      isMine: true,
      time: '2:33 PM',
    ),
    ChatMessage(
      text: 'Perfect. Looking forward to working with you on this delivery.',
      isMine: false,
      time: '2:35 PM',
    ),
  ];

  static const senderChatMessages = [
    ChatMessage(
      text: 'Hi Marc! Thanks for accepting my bid. I can meet at CDG Terminal 2E on the travel date.',
      isMine: false,
      time: '2:30 PM',
    ),
    ChatMessage(
      text: 'Great! Please message me when you arrive so we can coordinate the handover.',
      isMine: true,
      time: '2:32 PM',
    ),
    ChatMessage(
      text: 'Will do. I always pack parcels carefully — happy to share a photo if needed.',
      isMine: false,
      time: '2:33 PM',
    ),
    ChatMessage(
      text: 'Perfect. Looking forward to working with you on this delivery.',
      isMine: true,
      time: '2:35 PM',
    ),
  ];

  static const receiverChatMessages = [
    ChatMessage(
      text: "Hi Amara! I'm Aissatou, carrying your parcel on AF718. I'll land in Lagos Jun 15.",
      isMine: false,
      time: '9:12 AM',
    ),
    ChatMessage(
      text: 'Thanks Aissatou! Can we meet at Murtala Muhammed Airport Terminal 2?',
      isMine: true,
      time: '9:15 AM',
    ),
    ChatMessage(
      text: "Yes, that works. I'll message you when I clear customs.",
      isMine: false,
      time: '9:16 AM',
    ),
    ChatMessage(
      text: 'Perfect. I will have my phone ready for NFC confirmation.',
      isMine: true,
      time: '9:18 AM',
    ),
  ];

  static const receiverPaymentOptions = [0.0, 2.0, 4.0];

  static final chatThreadsVersion = ValueNotifier(0);
  static final List<ChatMessage> liveSenderTravelerChatMessages =
      List<ChatMessage>.from(senderChatMessages);
  static final List<ChatMessage> liveTravelerReceiverChatMessages =
      List<ChatMessage>.from(receiverChatMessages);

  static bool locationAgreementConfirmed = false;
  static bool photoUploadCompletionConfirmed = false;

  static List<ChatMessage> chatMessagesForThread(ChatThread thread) {
    return switch (thread) {
      ChatThread.senderTraveler => liveSenderTravelerChatMessages,
      ChatThread.travelerReceiver => liveTravelerReceiverChatMessages,
    };
  }

  static bool get bidAcceptanceConfirmed =>
      acceptedBidsByShipmentId.isNotEmpty ||
      travelerBids.any((b) => b.status == TravelerBidStatus.accepted);

  static bool get photosUploadCompleted {
    if (photoUploadCompletionConfirmed) return true;
    if (parcelCreationPhotosUploaded) return true;
    final status = effectiveStatus(activeShipment);
    return status == ShipmentStatus.photosUploaded ||
        status == ShipmentStatus.collected ||
        status == ShipmentStatus.inTransit ||
        status == ShipmentStatus.delivered;
  }

  static bool isThreadUnlocked(ChatThread thread) {
    if (thread == ChatThread.travelerReceiver) {
      return canReceiverAccessParcelFeatures(receiverActiveShipment.id);
    }
    return true;
  }

  static List<String> chatThreadLockReasons(ChatThread thread) {
    final reasons = <String>[];
    if (!locationAgreementConfirmed) {
      reasons.add('Location agreement pending');
    }
    if (!photosUploadCompleted) {
      reasons.add('Upload 1–3 parcel photos to unlock chat');
    }
    if (!bidAcceptanceConfirmed) {
      reasons.add('Bid acceptance pending');
    }
    return reasons;
  }

  static void appendChatMessage(ChatThread thread, ChatMessage message) {
    chatMessagesForThread(thread).add(message);
    chatThreadsVersion.value++;
  }

  static double totalPayment(
    double travelerPayout, {
    String category = 'Documents',
    String? shipmentId,
  }) {
    final paysReceiver =
        shipmentId != null ? paysReceiverFeeFor(shipmentId) : false;
    return travelerPayout +
        senderPlatformFeeUsd(category: category, paysReceiverFee: paysReceiver);
  }

  static List<Shipment> get travelerShipments => const <Shipment>[];

  static Shipment? shipmentById(String id, {bool travelerView = false}) {
    if (travelerView) {
      for (final s in shipments) {
        if (s.id == id && s.role == ShipmentRole.traveler) return s;
      }
      for (final s in shipments) {
        if (s.id == id) return s;
      }
      return null;
    }
    // Sender / receiver track: prefer sender-role parcels so In Transit / Delivered
    // details match My Shipments (not the traveler copy of the same ID).
    for (final s in senderShipments) {
      if (s.id == id) return s;
    }
    for (final s in shipments) {
      if (s.id == id && s.role == ShipmentRole.sender) return s;
    }
    for (final s in shipments) {
      if (s.id == id) return s;
    }
    return null;
  }

  static MatchingRequest? matchingRequestById(String id) {
    for (final m in matchingRequests) {
      if (m.request.id == id) return m;
    }
    return null;
  }

  static List<MatchingRequest> matchingRequestsForTrip(String tripId) {
    return matchingRequests.where((m) => m.tripId == tripId).toList();
  }

  static int matchingRequestCountForTrip(String tripId) {
    return matchingRequestsForTrip(tripId).length;
  }

  static TravelerTrip? travelerTripById(String id) {
    for (final trip in travelerPostedTrips) {
      if (trip.id == id) return trip;
    }
    return null;
  }
}
