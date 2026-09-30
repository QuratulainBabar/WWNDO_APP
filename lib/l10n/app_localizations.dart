import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_language.dart';
import '../data/legal_documents.dart';
import '../providers/locale_provider.dart';
import 'string_tables.dart';

/// App UI strings for the active [locale].
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'No AppLocalizations found in context');
    return value!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static List<Locale> get supportedLocales =>
      AppLanguage.supported.map((l) => l.locale).toList(growable: false);

  String _t(String key) {
    final code = locale.languageCode;
    return kStringTables[code]?[key] ??
        kStringTables['en']?[key] ??
        key;
  }

  String _tp(String key, Map<String, String> params) {
    var value = _t(key);
    params.forEach((k, v) {
      value = value.replaceAll('{$k}', v);
    });
    return value;
  }

  /// Translate a known English UI literal using the active locale tables.
  /// Returns [english] unchanged when it is not in the catalog.
  String translate(String english) {
    // Exact literal matches are checked first so generic parameterized
    // patterns below (e.g. "{id} updated") never shadow a static catalog
    // entry that happens to end the same way (e.g. "Profile updated").
    final exactKey = kEnglishToKey[english];
    if (exactKey != null) return _t(exactKey);

    // API enums like documents/objects are stored lowercase; catalog uses Title case.
    if (english.isNotEmpty) {
      final titled =
          '${english[0].toUpperCase()}${english.substring(1)}';
      if (titled != english) {
        final titledKey = kEnglishToKey[titled];
        if (titledKey != null) return _t(titledKey);
      }
    }

    final matchingCount =
        RegExp(r'^Matching Travelers \((\d+)\)$').firstMatch(english);
    if (matchingCount != null) {
      return matchingTravelersCount(int.parse(matchingCount.group(1)!));
    }

    final delivered = RegExp(
      r'^Parcel (.+) was delivered successfully\.$',
    ).firstMatch(english);
    if (delivered != null) {
      return parcelDeliveredBody(delivered.group(1)!);
    }
    final inTransit = RegExp(
      r'^Parcel (.+) is now in transit\.$',
    ).firstMatch(english);
    if (inTransit != null) {
      return parcelInTransitBody(inTransit.group(1)!);
    }
    final feePaid = RegExp(
      r'^(.+) platform fee deducted from your card for (.+)\.$',
    ).firstMatch(english);
    if (feePaid != null) {
      return platformFeeDeductedBody(feePaid.group(1)!, feePaid.group(2)!);
    }
    final nfc = RegExp(
      r'^NFC match confirmed for Trip/Delivery (.+)\. You and the Traveler verified the same delivery — the Traveler is connected',
    ).firstMatch(english);
    if (nfc != null) {
      return nfcMatchConfirmedBody(nfc.group(1)!);
    }

    // --- Toast message templates (AppToast literals with interpolation) ---
    final itemUpdatedMatch = RegExp(r'^(.+) updated$').firstMatch(english);
    if (itemUpdatedMatch != null) {
      return itemUpdated(itemUpdatedMatch.group(1)!);
    }
    final itemCancelledMatch =
        RegExp(r'^(.+) cancelled$').firstMatch(english);
    if (itemCancelledMatch != null) {
      return itemCancelled(itemCancelledMatch.group(1)!);
    }
    final stripeConnectErrorMatch =
        RegExp(r'^Stripe Connect: (.+)$').firstMatch(english);
    if (stripeConnectErrorMatch != null) {
      return stripeConnectError(stripeConnectErrorMatch.group(1)!);
    }
    final couldNotAttachImageMatch =
        RegExp(r'^Could not attach image: (.+)$').firstMatch(english);
    if (couldNotAttachImageMatch != null) {
      return couldNotAttachImage(couldNotAttachImageMatch.group(1)!);
    }
    final couldNotCaptureImageMatch =
        RegExp(r'^Could not capture image: (.+)$').firstMatch(english);
    if (couldNotCaptureImageMatch != null) {
      return couldNotCaptureImage(couldNotCaptureImageMatch.group(1)!);
    }
    final couldNotOpenCameraMatch =
        RegExp(r'^Could not open camera: (.+)$').firstMatch(english);
    if (couldNotOpenCameraMatch != null) {
      return couldNotOpenCamera(couldNotOpenCameraMatch.group(1)!);
    }
    final couldNotPickImageMatch =
        RegExp(r'^Could not pick image: (.+)$').firstMatch(english);
    if (couldNotPickImageMatch != null) {
      return couldNotPickImage(couldNotPickImageMatch.group(1)!);
    }
    final couldNotProposeMeetupMatch =
        RegExp(r'^Could not propose meetup: (.+)$').firstMatch(english);
    if (couldNotProposeMeetupMatch != null) {
      return couldNotProposeMeetup(couldNotProposeMeetupMatch.group(1)!);
    }
    final couldNotConfirmMeetupMatch =
        RegExp(r'^Could not confirm meetup: (.+)$').firstMatch(english);
    if (couldNotConfirmMeetupMatch != null) {
      return couldNotConfirmMeetup(couldNotConfirmMeetupMatch.group(1)!);
    }
    final couldNotOpenDisputeMatch =
        RegExp(r'^Could not open dispute: (.+)$').firstMatch(english);
    if (couldNotOpenDisputeMatch != null) {
      return couldNotOpenDispute(couldNotOpenDisputeMatch.group(1)!);
    }
    final unableMarkInTransitMatch =
        RegExp(r'^Unable to mark in transit: (.+)$').firstMatch(english);
    if (unableMarkInTransitMatch != null) {
      return unableMarkInTransit(unableMarkInTransitMatch.group(1)!);
    }
    final nfcErrorMatch = RegExp(r'^NFC error: (.+)$').firstMatch(english);
    if (nfcErrorMatch != null) {
      return nfcError(nfcErrorMatch.group(1)!);
    }
    final nfcCheckpointFailedMatch =
        RegExp(r'^NFC checkpoint failed: (.+)$').firstMatch(english);
    if (nfcCheckpointFailedMatch != null) {
      return nfcCheckpointFailed(nfcCheckpointFailedMatch.group(1)!);
    }
    final paymentFailedWithErrorMatch =
        RegExp(r'^Payment failed: (.+)$').firstMatch(english);
    if (paymentFailedWithErrorMatch != null) {
      return paymentFailedWithError(paymentFailedWithErrorMatch.group(1)!);
    }
    final payNowAfterAcceptMatch = RegExp(
      r'^Pay Now is available after (.+) accepts your request\.$',
    ).firstMatch(english);
    if (payNowAfterAcceptMatch != null) {
      return payNowAfterAccept(payNowAfterAcceptMatch.group(1)!);
    }
    final noPayableOfferFromMatch =
        RegExp(r'^No payable offer from (.+) yet\.$').firstMatch(english);
    if (noPayableOfferFromMatch != null) {
      return noPayableOfferFrom(noPayableOfferFromMatch.group(1)!);
    }
    final waitingForAcceptPayMatch = RegExp(
      r'^Waiting for (.+) to accept\. You[’\x27]ll be able to pay once their offer is ready\.$',
    ).firstMatch(english);
    if (waitingForAcceptPayMatch != null) {
      return waitingForAcceptPay(waitingForAcceptPayMatch.group(1)!);
    }
    final waitingForCounterOfferMatch = RegExp(
      r'^Waiting for (.+) to send a counter offer\. You[’\x27]ll get a notification when it[’\x27]s ready to pay\.$',
    ).firstMatch(english);
    if (waitingForCounterOfferMatch != null) {
      return waitingForCounterOffer(waitingForCounterOfferMatch.group(1)!);
    }
    final newCodeSentToMatch =
        RegExp(r'^A new code was sent to (.+)$').firstMatch(english);
    if (newCodeSentToMatch != null) {
      return newCodeSentTo(newCodeSentToMatch.group(1)!);
    }
    final bidFromRejectedMatch =
        RegExp(r'^Bid from (.+) rejected$').firstMatch(english);
    if (bidFromRejectedMatch != null) {
      return bidFromRejected(bidFromRejectedMatch.group(1)!);
    }
    final requestFromApprovedMatch =
        RegExp(r'^Request from (.+) approved$').firstMatch(english);
    if (requestFromApprovedMatch != null) {
      return requestFromApproved(requestFromApprovedMatch.group(1)!);
    }
    final emailDelayedBackupCodeMatch = RegExp(
      r'^Email is delayed or failed\. You can sign in with backup code (.+)\.$',
    ).firstMatch(english);
    if (emailDelayedBackupCodeMatch != null) {
      return emailDelayedBackupCode(emailDelayedBackupCodeMatch.group(1)!);
    }
    final enableBiometricAfterLoginMatch = RegExp(
      r'^Log in with email and password first, then enable (.+) in Settings \(or when prompted\)\.$',
    ).firstMatch(english);
    if (enableBiometricAfterLoginMatch != null) {
      return enableBiometricAfterLogin(
        enableBiometricAfterLoginMatch.group(1)!,
      );
    }
    final biometricWebOnlyInfoMatch = RegExp(
      r'^(.+) login works on the Android/iOS app, not in the browser\.$',
    ).firstMatch(english);
    if (biometricWebOnlyInfoMatch != null) {
      return biometricWebOnlyInfo(biometricWebOnlyInfoMatch.group(1)!);
    }
    final loginPasswordThenBiometricMatch = RegExp(
      r'^Log in with password first, then enable (.+)\.$',
    ).firstMatch(english);
    if (loginPasswordThenBiometricMatch != null) {
      return loginPasswordThenBiometric(
        loginPasswordThenBiometricMatch.group(1)!,
      );
    }
    final couldNotEnableBiometricMatch = RegExp(
      r'^Could not enable (.+)\. Please try again\.$',
    ).firstMatch(english);
    if (couldNotEnableBiometricMatch != null) {
      return couldNotEnableBiometric(couldNotEnableBiometricMatch.group(1)!);
    }
    final paymentFailedBookingNotCreatedDetailMatch = RegExp(
      r'^Payment failed\. Booking was not created\. (.+)$',
    ).firstMatch(english);
    if (paymentFailedBookingNotCreatedDetailMatch != null) {
      return paymentFailedBookingNotCreatedDetail(
        paymentFailedBookingNotCreatedDetailMatch.group(1)!,
      );
    }
    final travelerRequestLimitMessageMatch = RegExp(
      r'^You can request at most (\d+) travelers for this parcel\.$',
    ).firstMatch(english);
    if (travelerRequestLimitMessageMatch != null) {
      return travelerRequestLimitMessage(
        travelerRequestLimitMessageMatch.group(1)!,
      );
    }
    final cancelBlockedHoursMessageMatch = RegExp(
      r'^Cancellation is only allowed at least (\d+) hours before the flight date\.$',
    ).firstMatch(english);
    if (cancelBlockedHoursMessageMatch != null) {
      return cancelBlockedHoursMessage(
        cancelBlockedHoursMessageMatch.group(1)!,
      );
    }
    final minWalletTripMessageMatch = RegExp(
      r'^Minimum (.+) wallet balance is required to create a trip\.$',
    ).firstMatch(english);
    if (minWalletTripMessageMatch != null) {
      return minWalletTripMessage(minWalletTripMessageMatch.group(1)!);
    }
    final minWalletDeliveryMessageMatch = RegExp(
      r'^Minimum (.+) wallet balance is required to create a delivery\.$',
    ).firstMatch(english);
    if (minWalletDeliveryMessageMatch != null) {
      return minWalletDeliveryMessage(
        minWalletDeliveryMessageMatch.group(1)!,
      );
    }
    final walletNeededAcceptMessageMatch = RegExp(
      r'^You need at least (.+) in your wallet to accept \(includes platform fee\)\.$',
    ).firstMatch(english);
    if (walletNeededAcceptMessageMatch != null) {
      return walletNeededAcceptMessage(
        walletNeededAcceptMessageMatch.group(1)!,
      );
    }
    final bidCannotExceedMaxBudgetMatch = RegExp(
      r'^Bid cannot exceed sender max budget \((.+)\)\.$',
    ).firstMatch(english);
    if (bidCannotExceedMaxBudgetMatch != null) {
      return bidCannotExceedMaxBudget(
        bidCannotExceedMaxBudgetMatch.group(1)!,
      );
    }
    final walletMustHaveAtLeastFinalBudgetMatch = RegExp(
      r'^Wallet must have at least (.+) to send a final budget\.$',
    ).firstMatch(english);
    if (walletMustHaveAtLeastFinalBudgetMatch != null) {
      return walletMustHaveAtLeastFinalBudget(
        walletMustHaveAtLeastFinalBudgetMatch.group(1)!,
      );
    }

    return english;
  }

  // --- Toast message template getters (AppToast literals with interpolation) ---
  String itemUpdated(String id) => _tp('itemUpdated', {'id': id});
  String itemCancelled(String id) => _tp('itemCancelled', {'id': id});
  String stripeConnectError(String message) =>
      _tp('stripeConnectError', {'message': message});
  String couldNotAttachImage(String error) =>
      _tp('couldNotAttachImage', {'error': error});
  String couldNotCaptureImage(String error) =>
      _tp('couldNotCaptureImage', {'error': error});
  String couldNotOpenCamera(String error) =>
      _tp('couldNotOpenCamera', {'error': error});
  String couldNotPickImage(String error) =>
      _tp('couldNotPickImage', {'error': error});
  String couldNotProposeMeetup(String error) =>
      _tp('couldNotProposeMeetup', {'error': error});
  String couldNotConfirmMeetup(String error) =>
      _tp('couldNotConfirmMeetup', {'error': error});
  String couldNotOpenDispute(String error) =>
      _tp('couldNotOpenDispute', {'error': error});
  String unableMarkInTransit(String error) =>
      _tp('unableMarkInTransit', {'error': error});
  String nfcError(String error) => _tp('nfcError', {'error': error});
  String nfcCheckpointFailed(String error) =>
      _tp('nfcCheckpointFailed', {'error': error});
  String paymentFailedWithError(String error) =>
      _tp('paymentFailedWithError', {'error': error});
  String payNowAfterAccept(String name) =>
      _tp('payNowAfterAccept', {'name': name});
  String noPayableOfferFrom(String name) =>
      _tp('noPayableOfferFrom', {'name': name});
  String waitingForAcceptPay(String name) =>
      _tp('waitingForAcceptPay', {'name': name});
  String waitingForCounterOffer(String name) =>
      _tp('waitingForCounterOffer', {'name': name});
  String newCodeSentTo(String contact) =>
      _tp('newCodeSentTo', {'contact': contact});
  String bidFromRejected(String name) =>
      _tp('bidFromRejected', {'name': name});
  String requestFromApproved(String name) =>
      _tp('requestFromApproved', {'name': name});
  String emailDelayedBackupCode(String code) =>
      _tp('emailDelayedBackupCode', {'code': code});
  String enableBiometricAfterLogin(String label) =>
      _tp('enableBiometricAfterLogin', {'label': label});
  String biometricWebOnlyInfo(String label) =>
      _tp('biometricWebOnlyInfo', {'label': label});
  String loginPasswordThenBiometric(String label) =>
      _tp('loginPasswordThenBiometric', {'label': label});
  String couldNotEnableBiometric(String label) =>
      _tp('couldNotEnableBiometric', {'label': label});
  String paymentFailedBookingNotCreatedDetail(String detail) =>
      _tp('paymentFailedBookingNotCreatedDetail', {'detail': detail});
  String travelerRequestLimitMessage(String n) =>
      _tp('travelerRequestLimitMessage', {'n': n});
  String cancelBlockedHoursMessage(String hours) =>
      _tp('cancelBlockedHoursMessage', {'hours': hours});
  String minWalletTripMessage(String amount) =>
      _tp('minWalletTripMessage', {'amount': amount});
  String minWalletDeliveryMessage(String amount) =>
      _tp('minWalletDeliveryMessage', {'amount': amount});
  String walletNeededAcceptMessage(String amount) =>
      _tp('walletNeededAcceptMessage', {'amount': amount});
  String bidCannotExceedMaxBudget(String amount) =>
      _tp('bidCannotExceedMaxBudget', {'amount': amount});
  String walletMustHaveAtLeastFinalBudget(String amount) =>
      _tp('walletMustHaveAtLeastFinalBudget', {'amount': amount});

  String get appName => _t('appName');
  String get settings => _t('settings');
  String get appearance => _t('appearance');
  String get theme => _t('theme');
  String get darkMode => _t('darkMode');
  String get lightMode => _t('lightMode');
  String get currency => _t('currency');
  String get preferredCurrency => _t('preferredCurrency');
  String get currencyDescription => _t('currencyDescription');
  String get language => _t('language');
  String get preferredLanguage => _t('preferredLanguage');
  String get languageDescription => _t('languageDescription');
  String get accountVerification => _t('accountVerification');
  String get verifyEmailPhone => _t('verifyEmailPhone');
  String get verifyEmailPhoneSubtitle => _t('verifyEmailPhoneSubtitle');
  String get profile => _t('profile');
  String get editProfile => _t('editProfile');
  String get walletAndPayments => _t('walletAndPayments');
  String get availableBalance => _t('availableBalance');
  String get escrowBalance => _t('escrowBalance');
  String get topUpWallet => _t('topUpWallet');
  String get withdraw => _t('withdraw');
  String get transactionHistory => _t('transactionHistory');
  String get security => _t('security');
  String biometricLogin(String label) => _tp('biometricLogin', {'label': label});
  String biometricLoginSubtitle(String label) =>
      _tp('biometricLoginSubtitle', {'label': label});
  String get biometricLoginWebSubtitle => _t('biometricLoginWebSubtitle');
  String get legal => _t('legal');
  String get termsOfService => _t('termsOfService');
  String get privacyPolicy => _t('privacyPolicy');
  String get logout => _t('logout');
  String get home => _t('home');
  String get trip => _t('trip');
  String get trips => _t('trips');
  String get shipments => _t('shipments');
  String get alert => _t('alert');
  String get alerts => _t('alerts');
  String get chat => _t('chat');
  String get chats => _t('chats');
  String get browse => _t('browse');
  String get track => _t('track');
  String get back => _t('back');
  String get continueLabel => _t('continueLabel');
  String get cancel => _t('cancel');
  String get save => _t('save');
  String get confirm => _t('confirm');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get search => _t('search');
  String get loading => _t('loading');
  String get retry => _t('retry');
  String get done => _t('done');
  String get close => _t('close');
  String get next => _t('next');
  String get skip => _t('skip');
  String get yes => _t('yes');
  String get no => _t('no');
  String get ok => _t('ok');
  String get submit => _t('submit');
  String get accept => _t('accept');
  String get reject => _t('reject');
  String get payNow => _t('payNow');
  String get payWithStripe => _t('payWithStripe');
  String get welcome => _t('welcome');
  String get welcomeBack => _t('welcomeBack');
  String heyUser(String name) => _tp('heyUser', {'name': name});
  String get login => _t('login');
  String get signUp => _t('signUp');
  String get email => _t('email');
  String get password => _t('password');
  String get phone => _t('phone');
  String get name => _t('name');
  String get forgotPassword => _t('forgotPassword');
  String get createAccount => _t('createAccount');
  String get shipTagline => _t('shipTagline');
  String get shipTaglineWelcome => _t('shipTaglineWelcome');
  String get welcomeSubtext => _t('welcomeSubtext');
  String get joinWwngoSubtitle => _t('joinWwngoSubtitle');
  String get addProfilePhoto => _t('addProfilePhoto');
  String get creatingAccountEllipsis => _t('creatingAccountEllipsis');
  String get createAccountArrow => _t('createAccountArrow');
  String get emailPlaceholder => _t('emailPlaceholder');
  String get atLeast8Characters => _t('atLeast8Characters');
  String get iAgreeToThe => _t('iAgreeToThe');
  String get termsShort => _t('termsShort');
  String get andConjunction => _t('andConjunction');
  String get termsAndConditions => _t('termsAndConditions');
  String get loginToWwngoAccount => _t('loginToWwngoAccount');
  String get loggingInEllipsis => _t('loggingInEllipsis');
  String get dontHaveAccount => _t('dontHaveAccount');
  String lastUpdatedPrefix(String date) =>
      _tp('lastUpdatedPrefix', {'date': date});
  String readFullOnline(String title) =>
      _tp('readFullOnline', {'title': title});
  String get chooseHowAddPhoto => _t('chooseHowAddPhoto');

  // Traveler trips / deliveries / counter-offers / shipment detail.
  String get counterOffersSent => _t('counterOffersSent');
  String get counterOffersSentSubtitle => _t('counterOffersSentSubtitle');
  String get noCounterOffersYet => _t('noCounterOffersYet');
  String get acceptedOffersSubtitle => _t('acceptedOffersSubtitle');
  String get noPendingAcceptedOffers => _t('noPendingAcceptedOffers');
  String get unableToLoadCounterOffers => _t('unableToLoadCounterOffers');
  String get unableToLoadAcceptedOffers => _t('unableToLoadAcceptedOffers');
  String get noActiveTripsYet => _t('noActiveTripsYet');
  String get noCompletedTripsYet => _t('noCompletedTripsYet');
  String get noCancelledTripsYet => _t('noCancelledTripsYet');
  String get noCompletedDeliveriesYet => _t('noCompletedDeliveriesYet');
  String get noCancelledDeliveriesYet => _t('noCancelledDeliveriesYet');
  String get routeMap => _t('routeMap');
  String get openMap => _t('openMap');
  String get openInMaps => _t('openInMaps');
  String get statusTimeline => _t('statusTimeline');
  String get parcelType => _t('parcelType');
  String get shipmentEscrow => _t('shipmentEscrow');
  String get releasedToTravelerCp2 => _t('releasedToTravelerCp2');
  String get refundedToSender => _t('refundedToSender');
  String get escrowFrozenDispute => _t('escrowFrozenDispute');
  String get heldUntilCp2 => _t('heldUntilCp2');
  String get noActiveEscrow => _t('noActiveEscrow');
  String get nfcCheckpointTravelerReceiver => _t('nfcCheckpointTravelerReceiver');
  String get nfcCheckpointTravelerSender => _t('nfcCheckpointTravelerSender');
  String get finalDeliveryConfirmedEscrow => _t('finalDeliveryConfirmedEscrow');
  String get nfcTravelerReceiverConfirmed => _t('nfcTravelerReceiverConfirmed');
  String get checkSenderTraveler => _t('checkSenderTraveler');
  String get checkTravelerReceiver => _t('checkTravelerReceiver');
  String get leaveReviewForReceiver => _t('leaveReviewForReceiver');
  String get leaveReviewForSender => _t('leaveReviewForSender');
  String get leaveAReview => _t('leaveAReview');
  String get dispute => _t('dispute');
  String get offerAmount => _t('offerAmount');
  String get sentOn => _t('sentOn');
  String get timelineOpen => _t('timelineOpen');
  String get receiverAccepted => _t('receiverAccepted');
  String get escrowRefunded => _t('escrowRefunded');
  String get escrowFrozen => _t('escrowFrozen');
  String get disputeOpen => _t('disputeOpen');
  String get openCircleSenderTraveler => _t('openCircleSenderTraveler');
  String get openCircleTravelerReceiver => _t('openCircleTravelerReceiver');

  // Receiver parcel request / shipments / tracking.
  String get newRequest => _t('newRequest');
  String get parcelRequest => _t('parcelRequest');
  String get requestAcceptedExclaim => _t('requestAcceptedExclaim');
  String wantsToSendYouAParcel(String name) =>
      _tp('wantsToSendYouAParcel', {'name': name});
  String get paymentDetails => _t('paymentDetails');
  String get walletBalance => _t('walletBalance');
  String get pickupLocation => _t('pickupLocation');
  String get receiverLocation => _t('receiverLocation');
  String get travelerToBeMatched => _t('travelerToBeMatched');
  String get willBeAssigned => _t('willBeAssigned');
  String feeCoveredBySenderParen(String amount) =>
      _tp('feeCoveredBySenderParen', {'amount': amount});
  String chargedFromWalletOnPayNow(String amount) =>
      _tp('chargedFromWalletOnPayNow', {'amount': amount});
  String get feeFullyCoveredBySender => _t('feeFullyCoveredBySender');
  String get requestAcceptedBody => _t('requestAcceptedBody');
  String get youAcceptedParcelRequest => _t('youAcceptedParcelRequest');
  String get youDeclinedParcelRequest => _t('youDeclinedParcelRequest');
  String get parcelsAddressedToYou => _t('parcelsAddressedToYou');
  String get incomingTab => _t('incomingTab');
  String get pastTab => _t('pastTab');
  String get reviewAndAcceptRequest => _t('reviewAndAcceptRequest');
  String get noIncomingParcels => _t('noIncomingParcels');
  String get noPastDeliveries => _t('noPastDeliveries');
  String get whenSomeoneSendsParcel => _t('whenSomeoneSendsParcel');
  String get completedDeliveriesShowHere => _t('completedDeliveriesShowHere');
  String get shipmentDetails => _t('shipmentDetails');
  String get chatWithTraveler => _t('chatWithTraveler');
  String get waitingForTravelerToChat => _t('waitingForTravelerToChat');
  String get chatWithSender => _t('chatWithSender');
  String get viewDispute => _t('viewDispute');
  String get startNfcWithTraveler => _t('startNfcWithTraveler');
  String get nfcMeetTravelerHint => _t('nfcMeetTravelerHint');
  String get acceptUnlockTracking => _t('acceptUnlockTracking');
  String get unableToLoadShipments => _t('unableToLoadShipments');
  String get unableToLoadTracking => _t('unableToLoadTracking');
  String get noShipmentsToTrack => _t('noShipmentsToTrack');
  String get shipmentNotFound => _t('shipmentNotFound');
  String get parcelRequestNotFound => _t('parcelRequestNotFound');
  String get unableToLoadParcelRequest => _t('unableToLoadParcelRequest');
  String weightWithKg(String kg) => _tp('weightWithKg', {'kg': kg});

  // Role selection / account verify / OTP / KYC.
  String get selectYourAccount => _t('selectYourAccount');
  String get selectHowUseWwngo => _t('selectHowUseWwngo');
  String get roleSelectDescSender => _t('roleSelectDescSender');
  String get roleSelectDescTraveler => _t('roleSelectDescTraveler');
  String get roleSelectDescReceiver => _t('roleSelectDescReceiver');
  String get continuingEllipsis => _t('continuingEllipsis');
  String get verifyYourAccount => _t('verifyYourAccount');
  String get verifyAccountSubtitle => _t('verifyAccountSubtitle');
  String statusColon(String status) => _tp('statusColon', {'status': status});
  String get unverified => _t('unverified');
  String get verifiedLower => _t('verifiedLower');
  String get verifyAction => _t('verifyAction');
  String get notLinkedYet => _t('notLinkedYet');
  String get pleaseLogIn => _t('pleaseLogIn');
  String get addPhoneNumber => _t('addPhoneNumber');
  String get verifyEmailTitle => _t('verifyEmailTitle');
  String get verifySmsTitle => _t('verifySmsTitle');
  String enterCodeSentTo(String contact) =>
      _tp('enterCodeSentTo', {'contact': contact});
  String get sendingVerificationCode => _t('sendingVerificationCode');
  String get verificationCode => _t('verificationCode');
  String get confirmVerification => _t('confirmVerification');
  String get verifyingEllipsis => _t('verifyingEllipsis');
  String get resendCode => _t('resendCode');
  String codeExpiresIn(String time) => _tp('codeExpiresIn', {'time': time});
  String get codeExpired => _t('codeExpired');
  String get identityVerificationTitle => _t('identityVerificationTitle');
  String get poweredBySumsub => _t('poweredBySumsub');
  String get verifyYourIdentity => _t('verifyYourIdentity');
  String get sumsubIdLivenessHint => _t('sumsubIdLivenessHint');
  String get whatYouWillDo => _t('whatYouWillDo');
  String get kycStepPhotographId => _t('kycStepPhotographId');
  String get kycStepLiveness => _t('kycStepLiveness');
  String get kycStepWaitReview => _t('kycStepWaitReview');
  String get identityVerifiedExclaim => _t('identityVerifiedExclaim');
  String get identityVerifiedBody => _t('identityVerifiedBody');
  String get continueToApp => _t('continueToApp');
  String get pleaseWaitEllipsis => _t('pleaseWaitEllipsis');
  String get approved => _t('approved');
  String get getStarted => _t('getStarted');
  String get exploreApp => _t('exploreApp');
  String get sender => _t('sender');
  String get traveler => _t('traveler');
  String get receiver => _t('receiver');
  String get roleSender => _t('roleSender');
  String get roleTraveler => _t('roleTraveler');
  String get roleReceiver => _t('roleReceiver');
  String get selectRole => _t('selectRole');
  String get notifications => _t('notifications');
  String get noNotifications => _t('noNotifications');
  String get markAllRead => _t('markAllRead');
  String get paymentSummary => _t('paymentSummary');
  String get paymentMethod => _t('paymentMethod');
  String get payFromWallet => _t('payFromWallet');
  String get payWithCard => _t('payWithCard');
  String get totalDueNow => _t('totalDueNow');
  String get platformFee => _t('platformFee');
  String get yourPlatformFee => _t('yourPlatformFee');
  String get acceptedBidAmount => _t('acceptedBidAmount');
  String get amount => _t('amount');
  String get budget => _t('budget');
  String get maximumBudget => _t('maximumBudget');
  String get counterOffer => _t('counterOffer');
  String get placeBid => _t('placeBid');
  String get yourPrice => _t('yourPrice');
  String get maxBudget => _t('maxBudget');
  String get messageOptional => _t('messageOptional');
  String get messageToSender => _t('messageToSender');
  String get postDelivery => _t('postDelivery');
  String get createTrip => _t('createTrip');
  String get myPostedParcels => _t('myPostedParcels');
  String get myTrips => _t('myTrips');
  String get myBids => _t('myBids');
  String get matchingRequests => _t('matchingRequests');
  String get discoverTravelers => _t('discoverTravelers');
  String get incomingRequests => _t('incomingRequests');
  String get wallet => _t('wallet');
  String get topUp => _t('topUp');
  String get topUpSuccessful => _t('topUpSuccessful');
  String get withdrawalInitiated => _t('withdrawalInitiated');
  String get securedByStripe => _t('securedByStripe');
  String get escrowProtected => _t('escrowProtected');
  String get securePayment => _t('securePayment');
  String get processing => _t('processing');
  String get tryAgain => _t('tryAgain');
  String get errorGeneric => _t('errorGeneric');
  String get noResults => _t('noResults');
  String get seeAll => _t('seeAll');
  String get viewDetails => _t('viewDetails');
  String get status => _t('status');
  String get route => _t('route');
  String get from => _t('from');
  String get to => _t('to');
  String get weight => _t('weight');
  String get travelDate => _t('travelDate');
  String get parcelDetails => _t('parcelDetails');
  String get deliveryDetails => _t('deliveryDetails');
  String get tracking => _t('tracking');
  String get confirmDelivery => _t('confirmDelivery');
  String get rateExperience => _t('rateExperience');
  String get sendMessage => _t('sendMessage');
  String get typeMessage => _t('typeMessage');
  String get online => _t('online');
  String get offline => _t('offline');
  String get justNow => _t('justNow');
  String get yesterday => _t('yesterday');
  String get today => _t('today');
  String get kycVerification => _t('kycVerification');
  String get kycPending => _t('kycPending');
  String get kycApproved => _t('kycApproved');
  String get kycRejected => _t('kycRejected');
  String get useFaceIdFingerprint => _t('useFaceIdFingerprint');
  String unlockWithBiometric(String label) =>
      _tp('unlockWithBiometric', {'label': label});
  String get verifyItsYou => _t('verifyItsYou');
  String awayForAWhile(String label) =>
      _tp('awayForAWhile', {'label': label});
  String get loginWithPassword => _t('loginWithPassword');
  String waitingForBiometric(String label) =>
      _tp('waitingForBiometric', {'label': label});
  String get settingsSaved => _t('settingsSaved');
  String get languageUpdated => _t('languageUpdated');

  // Extra catalog keys (homes, profile, settings, trust indicators).
  String get changePassword => _t('changePassword');
  String get helpSupport => _t('helpSupport');
  String get helpSupportSubtitle => _t('helpSupportSubtitle');
  String get legalPolicies => _t('legalPolicies');
  String get legalPoliciesSubtitle => _t('legalPoliciesSubtitle');
  String get account => _t('account');
  String get deleteAccount => _t('deleteAccount');
  String get quickActions => _t('quickActions');
  String get createTripShort => _t('createTripShort');
  String get myTripsTitle => _t('myTripsTitle');
  String get senderRequests => _t('senderRequests');
  String get myDeliveries => _t('myDeliveries');
  String get counterOffers => _t('counterOffers');
  String get acceptedOffers => _t('acceptedOffers');
  String get activeDeliveries => _t('activeDeliveries');
  String get activeDeliveriesLower => _t('activeDeliveriesLower');
  String get noActiveDeliveries => _t('noActiveDeliveries');
  String get noTripsYet => _t('noTripsYet');
  String get view => _t('view');
  String get moreOptions => _t('moreOptions');
  String luggageAvailable(String kg) => _tp('luggageAvailable', {'kg': kg});
  String get unableToLoadDeliveries => _t('unableToLoadDeliveries');
  String travelDateColon(String date) => _tp('travelDateColon', {'date': date});
  String get parcelSearchHint => _t('parcelSearchHint');
  String get createDelivery => _t('createDelivery');
  String get createDeliverySubtitle => _t('createDeliverySubtitle');
  String get myPostedDeliveries => _t('myPostedDeliveries');
  String get myPostedDeliveriesSubtitle => _t('myPostedDeliveriesSubtitle');
  String get notificationsSubtitle => _t('notificationsSubtitle');
  String get trustIndicators => _t('trustIndicators');
  String get kycStatus => _t('kycStatus');
  String get completedDeliveriesLabel => _t('completedDeliveriesLabel');
  String get cancellationRate => _t('cancellationRate');
  String get disputeRate => _t('disputeRate');
  String get phoneNumber => _t('phoneNumber');
  String get country => _t('country');
  String get rating => _t('rating');
  String get totalTripsCompleted => _t('totalTripsCompleted');
  String get parcelsDelivered => _t('parcelsDelivered');
  String get active => _t('active');
  String get completed => _t('completed');
  String get cancelled => _t('cancelled');
  String weightColon(String weight) => _tp('weightColon', {'weight': weight});
  String get receiverHasNotAccepted => _t('receiverHasNotAccepted');
  String get switchRole => _t('switchRole');
  String get switchRoleSubtitle => _t('switchRoleSubtitle');
  String get roleDescSender => _t('roleDescSender');
  String get roleDescTraveler => _t('roleDescTraveler');
  String get roleDescTravelerMultiline => _t('roleDescTravelerMultiline');
  String get roleDescReceiver => _t('roleDescReceiver');
  String get roleSwitchFailed => _t('roleSwitchFailed');
  String get kycBadgeApproved => _t('kycBadgeApproved');
  String get kycBadgePending => _t('kycBadgePending');
  String get kycBadgeRejected => _t('kycBadgeRejected');
  String get kycBadgeRequired => _t('kycBadgeRequired');
  String escrowWithAmount(String amount) =>
      _tp('escrowWithAmount', {'amount': amount});
  String get activeShipments => _t('activeShipments');
  String get completedShipments => _t('completedShipments');
  String get myShipments => _t('myShipments');
  String get shipmentHistory => _t('shipmentHistory');
  String get incomingParcel => _t('incomingParcel');
  String get latestParcel => _t('latestParcel');
  String get parcel => _t('parcel');
  String get chatTraveler => _t('chatTraveler');
  String get whatToExpect => _t('whatToExpect');
  String get receiverTip1 => _t('receiverTip1');
  String get receiverTip2 => _t('receiverTip2');
  String get receiverTip3 => _t('receiverTip3');
  String get noActiveShipments => _t('noActiveShipments');
  String get greetingFallbackName => _t('greetingFallbackName');
  String get connected => _t('connected');
  String get travelerStatistics => _t('travelerStatistics');
  String get totalDeliveries => _t('totalDeliveries');
  String get activeTrips => _t('activeTrips');
  String get successfulDeliveryRate => _t('successfulDeliveryRate');
  String get averageRating => _t('averageRating');
  String get linkStripeConnect => _t('linkStripeConnect');
  String get linkingStripeConnect => _t('linkingStripeConnect');
  String get requiredForWithdrawals => _t('requiredForWithdrawals');
  String get accountLinkedReady => _t('accountLinkedReady');
  String get unableToLoadIncoming => _t('unableToLoadIncoming');
  String fromLabel(String place) => _tp('fromLabel', {'place': place});
  String travelerColon(String name) => _tp('travelerColon', {'name': name});
  String arrivingColon(String when) => _tp('arrivingColon', {'when': when});
  String get noCompletedShipments => _t('noCompletedShipments');
  String get completedCityToCity => _t('completedCityToCity');
  String get immutableLedger => _t('immutableLedger');
  String get noTransactionsYet => _t('noTransactionsYet');
  String get topUpStripe => _t('topUpStripe');
  String get history => _t('history');
  String get youWillReceive => _t('youWillReceive');
  String get payoutRail => _t('payoutRail');
  String get arrivesIn => _t('arrivesIn');

  // Sender screenshot / post-delivery / alerts catalog keys.
  String get recentReviews => _t('recentReviews');
  String get noReviewsYet => _t('noReviewsYet');
  String get fromUpper => _t('fromUpper');
  String get toUpper => _t('toUpper');
  String get yourAlerts => _t('yourAlerts');
  String get noUnreadAlerts => _t('noUnreadAlerts');
  String get sectionEarlier => _t('sectionEarlier');
  String get sectionNew => _t('sectionNew');
  String get markAllReadShort => _t('markAllReadShort');
  String get chooseDeliveryType => _t('chooseDeliveryType');
  String get chooseDeliveryTypeSubtitle => _t('chooseDeliveryTypeSubtitle');
  String get cityToCity => _t('cityToCity');
  String get cityToCityDesc => _t('cityToCityDesc');
  String get countryToCountry => _t('countryToCountry');
  String get countryToCountryDesc => _t('countryToCountryDesc');
  String get postDeliveryArrow => _t('postDeliveryArrow');
  String get postingEllipsis => _t('postingEllipsis');
  String get searchLocation => _t('searchLocation');
  String get selectTravelDate => _t('selectTravelDate');
  String get parcelPhotos => _t('parcelPhotos');
  String get uploadParcelPhotosHint => _t('uploadParcelPhotosHint');
  String get uploadPhotos => _t('uploadPhotos');
  String get noPhotosSelectedYet => _t('noPhotosSelectedYet');
  String get enterMaxBudgetAmount => _t('enterMaxBudgetAmount');
  String get travelersSeeBudgetHint => _t('travelersSeeBudgetHint');
  String meetupLocationsMax(Object max) =>
      _tp('meetupLocationsMax', {'max': '$max'});
  String get meetupHandOverHint => _t('meetupHandOverHint');
  String get addLocations => _t('addLocations');
  String get descriptionLabel => _t('descriptionLabel');
  String get describeYourParcel => _t('describeYourParcel');
  String get receiverSection => _t('receiverSection');
  String get receiverContactIntro => _t('receiverContactIntro');
  String get receiverEmail => _t('receiverEmail');
  String get receiverPhoneNumber => _t('receiverPhoneNumber');
  String get meetupLocationGoogleMaps => _t('meetupLocationGoogleMaps');
  String get selectMeetupLocation => _t('selectMeetupLocation');
  String get receiverDropOffNote => _t('receiverDropOffNote');
  String get parcelAcknowledgement => _t('parcelAcknowledgement');
  String get parcelAckIntro => _t('parcelAckIntro');
  String get parcelAckTerm1 => _t('parcelAckTerm1');
  String get parcelAckTerm2 => _t('parcelAckTerm2');
  String get parcelAckTerm3 => _t('parcelAckTerm3');
  String get parcelAckTerm4 => _t('parcelAckTerm4');
  String get parcelAckTerm5 => _t('parcelAckTerm5');
  String get parcelAckCheckbox => _t('parcelAckCheckbox');
  String get payFullPlatformFee => _t('payFullPlatformFee');
  String parcelDeliveredBody(String id) =>
      _tp('parcelDeliveredBody', {'id': id});
  String parcelInTransitBody(String id) =>
      _tp('parcelInTransitBody', {'id': id});
  String platformFeeDeductedBody(String amount, String id) =>
      _tp('platformFeeDeductedBody', {'amount': amount, 'id': id});
  String nfcMatchConfirmedBody(String id) =>
      _tp('nfcMatchConfirmedBody', {'id': id});
  String get addParcelPhoto => _t('addParcelPhoto');
  String get uploadParcelPhotosShort => _t('uploadParcelPhotosShort');
  String get weightKg => _t('weightKg');
  String get enterParcelWeight => _t('enterParcelWeight');
  String get documents => _t('documents');
  String get objects => _t('objects');
  String get routeSection => _t('routeSection');
  String get parcelSection => _t('parcelSection');
  String get fromCity => _t('fromCity');
  String get toCity => _t('toCity');
  String get receiverPending => _t('receiverPending');
  String get matchingTravelers => _t('matchingTravelers');
  String matchingTravelersCount(Object count) =>
      _tp('matchingTravelersCount', {'count': '$count'});
  String get categoryDelivery => _t('categoryDelivery');
  String get categoryFee => _t('categoryFee');
  String unreadUpdatesOne(Object count) =>
      _tp('unreadUpdatesOne', {'count': '$count'});
  String unreadUpdatesMany(Object count) =>
      _tp('unreadUpdatesMany', {'count': '$count'});
  String get youreAllCaughtUp => _t('youreAllCaughtUp');
  String get alertsEmptySubtitle => _t('alertsEmptySubtitle');
  String requestedPrefix(String date) =>
      _tp('requestedPrefix', {'date': date});

  // Edit profile / KYC / wallet top-up / wallet / legal / help / ledger.
  String get profileDetails => _t('profileDetails');
  String get profileShownWhenSend => _t('profileShownWhenSend');
  String get profileShownWhenCarry => _t('profileShownWhenCarry');
  String get profileShownWhenReceive => _t('profileShownWhenReceive');
  String get profilePhoto => _t('profilePhoto');
  String get tapToChangePhoto => _t('tapToChangePhoto');
  String get tapToUploadPhoto => _t('tapToUploadPhoto');
  String get fullName => _t('fullName');
  String get yourFullName => _t('yourFullName');
  String get selectCountry => _t('selectCountry');
  String get saveChanges => _t('saveChanges');
  String get profileUpdated => _t('profileUpdated');
  String get profileUpdatedMessage => _t('profileUpdatedMessage');
  String get backToSettings => _t('backToSettings');
  String get verificationApproved => _t('verificationApproved');
  String verificationApprovedMessage(String name) =>
      _tp('verificationApprovedMessage', {'name': name});
  String get pendingReview => _t('pendingReview');
  String get pendingReviewMessage => _t('pendingReviewMessage');
  String get verificationFailedTitle => _t('verificationFailedTitle');
  String get verificationFailedMessage => _t('verificationFailedMessage');
  String get verificationRequired => _t('verificationRequired');
  String get verificationRequiredMessage => _t('verificationRequiredMessage');
  String statusLabel(String status) => _tp('statusLabel', {'status': status});
  String get verifiedDetails => _t('verifiedDetails');
  String get nameColon => _t('nameColon');
  String get emailColon => _t('emailColon');
  String get countryColon => _t('countryColon');
  String get pleaseWait => _t('pleaseWait');
  String get refreshStatus => _t('refreshStatus');
  String get verifyIdentity => _t('verifyIdentity');

  /// Localizes a [KycStatusValue.label] English literal ('Approved',
  /// 'Pending', 'Rejected') without importing the KYC model here.
  String kycStatusValueLabel(String englishLabel) => switch (englishLabel) {
        'Approved' => _t('statusApprovedLabel'),
        'Rejected' => _t('statusRejectedLabel'),
        _ => _t('statusPendingLabel'),
      };

  String topUpIntro(String currency) =>
      _tp('topUpIntro', {'currency': currency});
  String get enterAmount => _t('enterAmount');
  String get stripeSecurityBanner => _t('stripeSecurityBanner');
  String get enterValidAmount => _t('enterValidAmount');
  String get topUpFailed => _t('topUpFailed');
  String amountLabelCurrency(String currency) =>
      _tp('amountLabelCurrency', {'currency': currency});
  String minimumWithdrawal(String amount) =>
      _tp('minimumWithdrawal', {'amount': amount});
  String get withdrawViaStripeConnect => _t('withdrawViaStripeConnect');
  String get businessDays2to5 => _t('businessDays2to5');
  String get withdrawToBank => _t('withdrawToBank');
  String get withdrawing => _t('withdrawing');
  String get openingEllipsis => _t('openingEllipsis');
  String get finishPayoutSetup => _t('finishPayoutSetup');
  String get setUpPayoutAccount => _t('setUpPayoutAccount');
  String get recentTransactions => _t('recentTransactions');
  String get immutableLedgerCents => _t('immutableLedgerCents');
  String get accountLinkedFinish => _t('accountLinkedFinish');
  String get notLinked => _t('notLinked');
  String get connectedFinishSetup => _t('connectedFinishSetup');
  String get legalHubIntro => _t('legalHubIntro');
  String get privacyPolicySubtitle => _t('privacyPolicySubtitle');
  String get termsOfServiceSubtitle => _t('termsOfServiceSubtitle');
  String get cookiePolicy => _t('cookiePolicy');
  String get cookiePolicySubtitle => _t('cookiePolicySubtitle');

  // Localized Terms & Conditions / Privacy Policy / Cookie Policy content.
  String get legalTermsTitle => _t('legalTermsTitle');
  String get legalPrivacyTitle => _t('legalPrivacyTitle');
  String get legalLastUpdatedDate => _t('legalLastUpdatedDate');
  String get legalLastUpdatedLabel => lastUpdatedPrefix(legalLastUpdatedDate);

  List<LegalSection> localizedTermsSections() => [
        LegalSection(
          heading: _t('legalTerms1Heading'),
          body: _t('legalTerms1Body'),
        ),
        LegalSection(
          heading: _t('legalTerms2Heading'),
          body: _t('legalTerms2Body'),
        ),
        LegalSection(
          heading: _t('legalTerms3Heading'),
          bullets: [
            _t('legalTerms3Bullet1'),
            _t('legalTerms3Bullet2'),
            _t('legalTerms3Bullet3'),
            _t('legalTerms3Bullet4'),
            _t('legalTerms3Bullet5'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms4Heading'),
          body: _t('legalTerms4Body'),
          bullets: [
            _t('legalTerms4Bullet1'),
            _t('legalTerms4Bullet2'),
            _t('legalTerms4Bullet3'),
            _t('legalTerms4Bullet4'),
            _t('legalTerms4Bullet5'),
            _t('legalTerms4Bullet6'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms5Heading'),
          body: _t('legalTerms5Body'),
          bullets: [
            _t('legalTerms5Bullet1'),
            _t('legalTerms5Bullet2'),
            _t('legalTerms5Bullet3'),
            _t('legalTerms5Bullet4'),
            _t('legalTerms5Bullet5'),
            _t('legalTerms5Bullet6'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms6Heading'),
          body: _t('legalTerms6Body'),
          bullets: [
            _t('legalTerms6Bullet1'),
            _t('legalTerms6Bullet2'),
            _t('legalTerms6Bullet3'),
            _t('legalTerms6Bullet4'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms7Heading'),
          body: _t('legalTerms7Body'),
        ),
        LegalSection(
          heading: _t('legalTerms8Heading'),
          body: _t('legalTerms8Body'),
        ),
        LegalSection(
          heading: _t('legalTerms9Heading'),
          bullets: [
            _t('legalTerms9Bullet1'),
            _t('legalTerms9Bullet2'),
            _t('legalTerms9Bullet3'),
            _t('legalTerms9Bullet4'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms10Heading'),
          body: _t('legalTerms10Body'),
        ),
        LegalSection(
          heading: _t('legalTerms11Heading'),
          bullets: [
            _t('legalTerms11Bullet1'),
            _t('legalTerms11Bullet2'),
            _t('legalTerms11Bullet3'),
            _t('legalTerms11Bullet4'),
          ],
        ),
        LegalSection(
          heading: _t('legalTerms12Heading'),
          body: _t('legalTerms12Body'),
        ),
        LegalSection(
          heading: _t('legalTerms13Heading'),
          body: _t('legalTerms13Body'),
        ),
        LegalSection(
          heading: _t('legalTerms14Heading'),
          body: _t('legalTerms14Body'),
        ),
        LegalSection(
          heading: _t('legalTerms15Heading'),
          body: _t('legalTerms15Body'),
        ),
        LegalSection(
          heading: _t('legalTerms16Heading'),
          body: _t('legalTerms16Body'),
        ),
      ];

  List<LegalSection> localizedPrivacySections() => [
        LegalSection(
          heading: _t('legalPrivacy1Heading'),
          body: _t('legalPrivacy1Body'),
        ),
        LegalSection(
          heading: _t('legalPrivacy2Heading'),
          bullets: [
            _t('legalPrivacy2Bullet1'),
            _t('legalPrivacy2Bullet2'),
            _t('legalPrivacy2Bullet3'),
            _t('legalPrivacy2Bullet4'),
            _t('legalPrivacy2Bullet5'),
            _t('legalPrivacy2Bullet6'),
          ],
        ),
        LegalSection(
          heading: _t('legalPrivacy3Heading'),
          bullets: [
            _t('legalPrivacy3Bullet1'),
            _t('legalPrivacy3Bullet2'),
            _t('legalPrivacy3Bullet3'),
            _t('legalPrivacy3Bullet4'),
            _t('legalPrivacy3Bullet5'),
            _t('legalPrivacy3Bullet6'),
          ],
        ),
        LegalSection(
          heading: _t('legalPrivacy4Heading'),
          body: _t('legalPrivacy4Body'),
        ),
        LegalSection(
          heading: _t('legalPrivacy5Heading'),
          bullets: [
            _t('legalPrivacy5Bullet1'),
            _t('legalPrivacy5Bullet2'),
            _t('legalPrivacy5Bullet3'),
            _t('legalPrivacy5Bullet4'),
            _t('legalPrivacy5Bullet5'),
            _t('legalPrivacy5Bullet6'),
          ],
        ),
        LegalSection(
          heading: _t('legalPrivacy6Heading'),
          body: _t('legalPrivacy6Body'),
        ),
        LegalSection(
          heading: _t('legalPrivacy7Heading'),
          body: _t('legalPrivacy7Body'),
        ),
        LegalSection(
          heading: _t('legalPrivacy8Heading'),
          body: _t('legalPrivacy8Body'),
        ),
      ];

  List<LegalSection> localizedCookieSections() => [
        LegalSection(
          heading: _t('legalCookie1Heading'),
          body: _t('legalCookie1Body'),
        ),
        LegalSection(
          heading: _t('legalCookie2Heading'),
          bullets: [
            _t('legalCookie2Bullet1'),
            _t('legalCookie2Bullet2'),
            _t('legalCookie2Bullet3'),
          ],
        ),
        LegalSection(
          heading: _t('legalCookie3Heading'),
          body: _t('legalCookie3Body'),
        ),
      ];

  String get fullDocumentsOnline => _t('fullDocumentsOnline');
  String get latestLegalOnWebsite => _t('latestLegalOnWebsite');
  String get openWebsite => _t('openWebsite');
  String get helpSupportIntro => _t('helpSupportIntro');
  String get faq => _t('faq');
  String get faqSubtitle => _t('faqSubtitle');
  String get safetyTrust => _t('safetyTrust');
  String get safetyTrustSubtitle => _t('safetyTrustSubtitle');
  String get aboutWwngo => _t('aboutWwngo');
  String get aboutWwngoSubtitle => _t('aboutWwngoSubtitle');
  String get contactSupport => _t('contactSupport');
  String get visitWebsite => _t('visitWebsite');

  // Wallet payout / top-up / ledger description catalog keys.
  String get finishSettingUpPayout => _t('finishSettingUpPayout');
  String get linkPayoutToWithdraw => _t('linkPayoutToWithdraw');
  String get linkPayoutBeforeWithdraw => _t('linkPayoutBeforeWithdraw');
  String get withdrawalFailed => _t('withdrawalFailed');
  String get couldNotOpenStripeConnect => _t('couldNotOpenStripeConnect');
  String get couldNotStartPayoutSetup => _t('couldNotStartPayoutSetup');
  String get savingEllipsis => _t('savingEllipsis');
  String get backToWallet => _t('backToWallet');
  String get goToHome => _t('goToHome');
  String withdrawalTransferredMessage(String amount) =>
      _tp('withdrawalTransferredMessage', {'amount': amount});
  String walletCreditedUsd(String amount) =>
      _tp('walletCreditedUsd', {'amount': amount});
  String fxChargedCredited(String amount) =>
      _tp('fxChargedCredited', {'amount': amount});
  String fxPreviewUnavailable(String message) =>
      _tp('fxPreviewUnavailable', {'message': message});
  String toppedUpCredited(String amount) =>
      _tp('toppedUpCredited', {'amount': amount});
  String get continuePayoutSetup => _t('continuePayoutSetup');
  String get payoutAccountConnected => _t('payoutAccountConnected');
  String get returnToWalletFinishPayout => _t('returnToWalletFinishPayout');
  String get stripePayoutLinkedMessage => _t('stripePayoutLinkedMessage');
  String escrowReleasedFor(String id) => _tp('escrowReleasedFor', {'id': id});
  String platformFeeFor(String id) => _tp('platformFeeFor', {'id': id});
  String escrowHoldFor(String id) => _tp('escrowHoldFor', {'id': id});
  String get escrow => _t('escrow');
  String get strongPasswordHint => _t('strongPasswordHint');
  String get currentPassword => _t('currentPassword');
  String get newPassword => _t('newPassword');
  String get confirmNewPassword => _t('confirmNewPassword');
  String get passwordUpdatedTitle => _t('passwordUpdatedTitle');
  String get passwordChangedSuccessfully => _t('passwordChangedSuccessfully');
  String get enterCurrentPassword => _t('enterCurrentPassword');
  String get newPasswordMinLength => _t('newPasswordMinLength');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');
  String get newPasswordMustDiffer => _t('newPasswordMustDiffer');
  String get searchChats => _t('searchChats');
  String get noChatsYet => _t('noChatsYet');
  String get noMatchingChats => _t('noMatchingChats');
  String get conversationsAppearHere => _t('conversationsAppearHere');
  String get tryDifferentSearch => _t('tryDifferentSearch');
  String get unableToLoadChats => _t('unableToLoadChats');
  String get tapToStartChatting => _t('tapToStartChatting');
  String get noMessagesYet => _t('noMessagesYet');
  String get sayHelloToStart => _t('sayHelloToStart');
  String get messageEllipsis => _t('messageEllipsis');
  String messageUser(String name) => _tp('messageUser', {'name': name});
  String get photo => _t('photo');
  String get photoLibrary => _t('photoLibrary');
  String get attachFile => _t('attachFile');
  String get shareParcelPhotoHint => _t('shareParcelPhotoHint');
  String get takePhoto => _t('takePhoto');
  String get chatOpenCoordinate => _t('chatOpenCoordinate');
  String get chatUnlocksAfterPayment => _t('chatUnlocksAfterPayment');
  String get senderTravelerChat => _t('senderTravelerChat');
  String messagesEndToEndSecured(String id) =>
      _tp('messagesEndToEndSecured', {'id': id});
  String rolePairLabel(String left, String right, [String? id]) {
    final base = '$left ↔ $right';
    if (id == null || id.isEmpty) return base;
    return '$base · $id';
  }

  static const Map<String, String> _ledgerTypeKeys = {
    'topUp': 'ledgerTypeTopUp',
    'withdrawal': 'ledgerTypeWithdrawal',
    'escrowHold': 'ledgerTypeEscrowHold',
    'escrowRelease': 'ledgerTypeEscrowRelease',
    'escrowFreeze': 'ledgerTypeEscrowFreeze',
    'deliveryPayout': 'ledgerTypeDeliveryPayout',
    'platformFee': 'ledgerTypePlatformFee',
    'refund': 'ledgerTypeRefund',
  };

  /// Localizes a [LedgerEntryType.name] value (e.g. 'topUp', 'platformFee').
  String ledgerTypeLabel(String typeName) {
    final key = _ledgerTypeKeys[typeName];
    return key == null ? typeName : _t(key);
  }

  static const Map<String, String> _ledgerDescSuffixKeys = {
    'Escrow hold': 'ledgerTypeEscrowHold',
    'Platform fee': 'ledgerTypePlatformFee',
    'Delivery payout': 'ledgerTypeDeliveryPayout',
    'Escrow released (NFC CP2)': 'ledgerDescEscrowReleasedNfc',
    'Escrow principal refunded': 'ledgerDescEscrowPrincipalRefunded',
    'Platform fee refunded': 'ledgerDescPlatformFeeRefunded',
    'Escrow frozen': 'ledgerDescEscrowFrozen',
    'Booking failed — escrow reversed': 'ledgerDescBookingFailedReversed',
  };

  /// Localizes a [LedgerEntry.displayDescription] value. Descriptions are
  /// either a static English phrase ('Top-up via Stripe',
  /// 'Withdrawal via Stripe Connect') or `<id> · <suffix>`, where only the
  /// suffix is translated so the shipment/withdrawal id stays intact.
  String translateLedgerDescription(String description) {
    if (description == 'Top-up via Stripe') {
      return _t('ledgerDescTopUpStripe');
    }
    if (description == 'Withdrawal via Stripe Connect') {
      return _t('ledgerDescWithdrawalStripeConnect');
    }
    final escrowReleased =
        RegExp(r'^Escrow released for (.+)$').firstMatch(description);
    if (escrowReleased != null) {
      return escrowReleasedFor(escrowReleased.group(1)!);
    }
    final platformFee =
        RegExp(r'^Platform fee for (.+)$').firstMatch(description);
    if (platformFee != null) {
      return platformFeeFor(platformFee.group(1)!);
    }
    final escrowHold =
        RegExp(r'^Escrow hold for (.+)$').firstMatch(description);
    if (escrowHold != null) {
      return escrowHoldFor(escrowHold.group(1)!);
    }
    final sepIndex = description.lastIndexOf(' · ');
    if (sepIndex == -1) return description;
    final suffix = description.substring(sepIndex + 3);
    final key = _ledgerDescSuffixKeys[suffix];
    if (key == null) return description;
    final prefix = description.substring(0, sepIndex);
    return '$prefix · ${_t(key)}';
  }

  // Origin/main auth + traveler keys (merged).
  String get heyThere => _t('heyThere');
  String get travelerMyTrips => _t('travelerMyTrips');
  String get travelerCreateTrip => _t('travelerCreateTrip');
  String get unableToLoadTrips => _t('unableToLoadTrips');
  String luggageAvailableKg(String kg) =>
      _tp('luggageAvailableKg', {'kg': kg});
  String get noActiveDeliveriesYet => _t('noActiveDeliveriesYet');
  String travelDateLabel(String date) =>
      _tp('travelDateLabel', {'date': date});
  String escrowAmount(String amount) =>
      _tp('escrowAmount', {'amount': amount});
  String get statusBidAccepted => _t('statusBidAccepted');
  String get statusAwaitingReceiver => _t('statusAwaitingReceiver');
  String get statusCollected => _t('statusCollected');
  String get statusInTransit => _t('statusInTransit');
  String get statusDelivered => _t('statusDelivered');
  String get statusDisputed => _t('statusDisputed');
  String get statusCancelled => _t('statusCancelled');
  String get statusReadyForHandoff => _t('statusReadyForHandoff');
  String get statusPosted => _t('statusPosted');
  String get termsAgreePrefix => _t('termsAgreePrefix');
  String get termsLink => _t('termsLink');
  String get termsAnd => _t('termsAnd');
  String get privacyPolicyLink => _t('privacyPolicyLink');
  String get termsAgreeSuffix => _t('termsAgreeSuffix');
  String biometricWebOnly(String label) =>
      _tp('biometricWebOnly', {'label': label});
  String biometricEnableFirst(String label) =>
      _tp('biometricEnableFirst', {'label': label});
  String biometricNotAvailable(String label) =>
      _tp('biometricNotAvailable', {'label': label});
  String biometricNotSetUp(String label) =>
      _tp('biometricNotSetUp', {'label': label});
  String weSentCodeTo(String contact) =>
      _tp('weSentCodeTo', {'contact': contact});
  String createNewPasswordFor(String contact) =>
      _tp('createNewPasswordFor', {'contact': contact});
  String otpSubtitleFailed(String contact, String code) =>
      _tp('otpSubtitleFailed', {'contact': contact, 'code': code});
  String otpSubtitleSent(String contact, String code) =>
      _tp('otpSubtitleSent', {'contact': contact, 'code': code});
  String otpSubtitleSending(String contact, String code) =>
      _tp('otpSubtitleSending', {'contact': contact, 'code': code});
  String codeSentVia(String channel, String contact) =>
      _tp('codeSentVia', {'channel': channel, 'contact': contact});
  String selectLabel(String label) => _tp('selectLabel', {'label': label});
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLanguage.supported.any((l) => l.code == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => true;
}

extension AppLocalizationsX on BuildContext {
  /// Active app strings. Watches [LocaleProvider] so widgets rebuild on change.
  /// Prefers [LocaleProvider.locale] so UI never lags behind a language switch
  /// when Flutter's [Localizations] tree has not yet reloaded.
  AppLocalizations get l10n {
    try {
      final localeProvider = watch<LocaleProvider>();
      return AppLocalizations(localeProvider.locale);
    } catch (_) {
      // Outside MultiProvider (tests / early frames) — Localizations still works.
      return AppLocalizations.of(this);
    }
  }

  /// Translate a known English UI literal for the active language.
  String tr(String english) => l10n.translate(english);
}
