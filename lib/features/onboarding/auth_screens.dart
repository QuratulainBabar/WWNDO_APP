import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/api_config.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/phone/phone_countries.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/international_phone_field.dart';
import '../../core/widgets/legal_document_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/legal_documents.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../sender/widgets/route_country_dropdown.dart';
import 'login_otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  /// Country below Email — drives phone flag / dial code and account country.
  String? _countryIso;
  late PhoneCountry _phoneCountry =
      PhoneCountries.byIso(StaticData.currentUser.countryCode);
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_acceptedTerms) {
      AppToast.error(context, 'You must agree to the Terms and Privacy Policy');
      return;
    }

    final validationError = _validateForm();
    if (validationError != null) {
      AppToast.error(context, validationError);
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      final national = PhoneCountries.nationalDigits(_phoneController.text);
      final user = await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        dialCode: _phoneCountry.dialCode,
        phoneNumber: national,
        phone: PhoneCountries.formatFull(_phoneCountry, _phoneController.text),
        password: _passwordController.text,
        countryCode: _countryIso!,
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;

      if (user.accountStatus == 'suspended') {
        context.go('/account-suspended');
      } else {
        // Register → role selection → email OTP.
        context.go('/role-selection');
      }
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  String? _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      return 'Full name is required';
    }
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    if (_countryIso == null || _countryIso!.isEmpty) {
      return 'Select a country';
    }
    if (!PhoneCountries.isValidNational(
      _phoneController.text,
      country: _phoneCountry,
    )) {
      return 'Enter a valid phone number';
    }
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _onCountryChanged(String iso) {
    setState(() {
      _countryIso = iso;
      // Auto-update phone flag + dial code; user can still override manually.
      _phoneCountry = PhoneCountries.byIso(iso);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pagePadding = context.pagePadding;
    final fieldLabelStyle =
        context.typo.inputLabel.copyWith(fontWeight: FontWeight.w600);
    final inputStyle = context.typo.input;
    final subtitleStyle = context.typo.subheading;

    final termsStyle = context.typo.link.copyWith(
      color: AppColors.textPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: ScrollableFormScreen(
        padding: pagePadding.copyWith(bottom: 12),
        actions: [
          AppButton(
            label: auth.loading ? 'Creating account…' : 'Create account →',
            onPressed: _acceptedTerms && !auth.loading ? _createAccount : null,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BackLink(fallbackRoute: '/welcome'),
            const SizedBox(height: 16),
            Text('Create account', style: context.typo.h1),
            const SizedBox(height: 8),
            Text(
              'Join WWNGO to send, carry, or receive parcels',
              style: subtitleStyle,
            ),
            _field(
              'Full name',
              _nameController,
              labelStyle: fieldLabelStyle,
              inputStyle: inputStyle,
              hintText: 'Your full name',
            ),
            _field(
              'Email',
              _emailController,
              labelStyle: fieldLabelStyle,
              inputStyle: inputStyle,
              keyboardType: TextInputType.emailAddress,
              hintText: 'you@email.com',
            ),
            RouteCountryDropdown(
              label: 'Country',
              value: _countryIso,
              hintText: 'Select country',
              onChanged: _onCountryChanged,
            ),
            InternationalPhoneField(
              controller: _phoneController,
              country: _phoneCountry,
              onCountryChanged: (c) => setState(() {
                _phoneCountry = c;
                _countryIso = c.iso;
              }),
              labelStyle: fieldLabelStyle,
              inputStyle: inputStyle,
            ),
            _field(
              'Password',
              _passwordController,
              obscure: true,
              labelStyle: fieldLabelStyle,
              inputStyle: inputStyle,
              hintText: 'At least 8 characters',
            ),
            const SizedBox(height: 12),
            _termsRow(termsStyle),
          ],
        ),
      ),
    );
  }

  Widget _termsRow(TextStyle termsStyle) {
    final linkStyle = termsStyle.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    Widget link(String label, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(label, style: linkStyle),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _acceptedTerms ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                behavior: HitTestBehavior.opaque,
                child: Text('I agree to the ', style: termsStyle),
              ),
              link(
                'Terms',
                () => showLegalDocumentDialog(
                  context: context,
                  title: LegalDocuments.termsTitle,
                  sections: LegalDocuments.termsSections,
                ),
              ),
              Text(' and ', style: termsStyle),
              link(
                'Privacy Policy',
                () => showLegalDocumentDialog(
                  context: context,
                  title: LegalDocuments.privacyTitle,
                  sections: LegalDocuments.privacySections,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    final typo = context.typo;
    final fieldInputStyle = inputStyle ?? typo.input;
    return AppLabeledField(
      label: label,
      labelStyle: labelStyle,
      padding: const EdgeInsets.only(top: AppFieldSpacing.top, bottom: 12),
      child: TextFormField(
        controller: controller,
        onTap: () => ensureSoftKeyboardVisible(retry: obscure),
        onTapOutside: dismissKeyboardOnTapOutside,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        style: fieldInputStyle,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: fieldInputStyle.copyWith(color: AppColors.textDisabled),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _openBiometricFlow() async {
    // Device Face ID / Fingerprint via local_auth.
    if (kIsWeb) {
      AppToast.info(
        context,
        '${PlatformUi.biometricShortLabel} login works on the Android/iOS app, not in the browser.',
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final canUnlock = await auth.canUnlockWithBiometric();
    if (!mounted) return;

    if (!canUnlock) {
      AppToast.info(
        context,
        'Log in with email and password first, then enable ${PlatformUi.biometricShortLabel} in Settings (or when prompted).',
      );
      return;
    }

    final supported = await BiometricAuthService.isDeviceSupported();
    final canCheck = await BiometricAuthService.canCheckBiometrics();
    final enrolled = await BiometricAuthService.getAvailableBiometrics();
    if (!mounted) return;

    if (!supported || !canCheck || enrolled.isEmpty) {
      context.push(
        '/biometric/unavailable',
        extra: !supported
            ? '${PlatformUi.biometricShortLabel} is not available on this device.'
            : 'No ${PlatformUi.biometricShortLabel.toLowerCase()} is set up on this device. Add one in your device settings first.',
      );
      return;
    }

    context.push('/biometric/login');
  }

  Future<void> _login() async {
    // Flush Android/iOS autofill into the controllers before reading them.
    // Without this, the password field can still hold a previous/empty value
    // while the user sees the filled password, and the API returns
    // "Invalid email or password".
    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext(shouldSave: false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.replaceAll(RegExp(r'[\r\n]'), '');

    if (email.isEmpty || password.isEmpty) {
      AppToast.error(context, 'Enter your email and password');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      AppToast.error(context, 'Enter a valid email address');
      return;
    }

    if (kDebugMode) {
      debugPrint('LOGIN → ${ApiConfig.authBase}');
    }

    // Navigate immediately — OTP screen sends email in the background so the
    // user is not stuck waiting on SMTP latency.
    if (!mounted) return;
    context.push(
      '/login/verify-otp',
      extra: PasswordLoginOtpFlowData(
        email: email,
        password: password,
        alreadySent: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;
    final fieldLabelStyle = typo.inputLabel.copyWith(fontWeight: FontWeight.w600);
    final inputStyle = typo.input;
    final footerStyle = typo.subheading;
    final footerLinkStyle = typo.linkBold;
    final subtitleStyle = typo.subheading;
    final forgotPasswordStyle = typo.link;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: AutofillGroup(
        child: BackLinkScreen(
          fallbackRoute: '/welcome',
          child: SingleChildScrollView(
            physics: PlatformUi.scrollPhysics,
            padding: context.pagePaddingWithKeyboard(EdgeInsets.zero),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Welcome back', style: typo.h1),
                const SizedBox(height: 12),
                Text(
                  'Log in to your WWNGO account',
                  style: subtitleStyle,
                ),
                const SizedBox(height: 32),
                _labeledField(
                  context,
                  'Email',
                  _emailController,
                  labelStyle: fieldLabelStyle,
                  inputStyle: inputStyle,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'you@email.com',
                ),
                _labeledField(
                  context,
                  'Password',
                  _passwordController,
                  obscure: true,
                  labelStyle: fieldLabelStyle,
                  inputStyle: inputStyle,
                  hintText: 'Enter your password',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Forgot password?', style: forgotPasswordStyle),
                  ),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: auth.loading ? 'Logging in…' : 'Log in',
                  onPressed: auth.loading ? null : _login,
                ),
                const SizedBox(height: AppButton.stackGap),
                AppButton(
                  label: PlatformUi.biometricLabel,
                  variant: AppButtonVariant.outline,
                  onPressed: auth.loading ? null : _openBiometricFlow,
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: RichText(
                      text: TextSpan(
                        style: footerStyle,
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(text: 'Sign up', style: footerLinkStyle),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool obscure = false,
    TextStyle? labelStyle,
    TextStyle? inputStyle,
    TextInputType? keyboardType,
    String? hintText,
  }) {
    final typo = context.typo;
    final fieldInputStyle = inputStyle ?? typo.input;
    return AppLabeledField(
      label: label,
      labelStyle: labelStyle,
      padding: EdgeInsets.only(top: AppFieldSpacing.top, bottom: context.fieldGap),
      child: TextFormField(
        controller: controller,
        onTap: () => ensureSoftKeyboardVisible(retry: obscure),
        onTapOutside: dismissKeyboardOnTapOutside,
        obscureText: obscure,
        autocorrect: false,
        enableSuggestions: !obscure,
        autofillHints: obscure
            ? const [AutofillHints.password]
            : const [AutofillHints.email, AutofillHints.username],
        keyboardType: keyboardType,
        textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: obscure ? (_) => _login() : null,
        style: fieldInputStyle,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: fieldInputStyle.copyWith(color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
