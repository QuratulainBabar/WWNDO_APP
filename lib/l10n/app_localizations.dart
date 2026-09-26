import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/l10n/app_language.dart';
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
    final key = kEnglishToKey[english];
    if (key == null) return english;
    return _t(key);
  }

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
  AppLocalizations get l10n {
    // Rebuild when the user picks a new language in Settings.
    try {
      watch<LocaleProvider>();
    } catch (_) {
      // Outside MultiProvider (tests / early frames) — Localizations still works.
    }
    return AppLocalizations.of(this);
  }

  /// Translate a known English UI literal for the active language.
  String tr(String english) => l10n.translate(english);
}
