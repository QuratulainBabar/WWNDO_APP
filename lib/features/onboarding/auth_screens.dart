import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/config/api_config.dart';
import '../../core/layout/responsive.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/platform/biometric_auth_service.dart';
import '../../core/platform/platform_ui.dart';
import '../../core/platform/temp_image_file.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/phone/phone_countries.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/international_phone_field.dart';
import '../../core/widgets/legal_document_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../data/legal_documents.dart';
import '../../data/profile_demo_store.dart';
import '../../data/static_data.dart';
import '../../providers/auth_provider.dart';
import '../sender/widgets/route_country_dropdown.dart';
import 'login_otp_verification_screen.dart';
import 'profile_photo_crop_screen.dart';

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
  final _imagePicker = ImagePicker();
  /// Country below Email — drives phone flag / dial code and account country.
  String? _countryIso;
  late PhoneCountry _phoneCountry =
      PhoneCountries.byIso(StaticData.currentUser.countryCode);
  bool _acceptedTerms = false;
  Uint8List? _profilePhotoBytes;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(
        title: 'Profile photo',
        subtitle: 'Choose how you want to add your photo',
      ),
    );
    if (!mounted) return;

    // Cancel → continue with no profile photo (clear any existing selection).
    if (result is ImageSourceSheetCancel) {
      setState(() => _profilePhotoBytes = null);
      return;
    }
    if (result is! ImageSource) return;

    try {
      final image = await _imagePicker.pickImage(
        source: result,
        imageQuality: 92,
        maxWidth: 2048,
      );
      if (!mounted || image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted || bytes.isEmpty) return;

      final cropResult = await Navigator.of(context).push<ProfilePhotoCropResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProfilePhotoCropScreen(imageBytes: bytes),
        ),
      );
      if (!mounted || cropResult == null) return;

      setState(() => _profilePhotoBytes = cropResult.bytes);
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not load that photo. Try another one.');
      }
    }
  }

  Future<void> _persistProfilePhoto(AuthProvider auth) async {
    final bytes = _profilePhotoBytes;
    if (bytes == null || bytes.isEmpty) return;

    // Always keep in-memory bytes first so Profile can show immediately,
    // even if temp-file write or upload fails.
    ProfileDemoStore.setPhotoForAllRoles(bytes: bytes);
    try {
      final path = await writeTempImageFile(bytes);
      if (path != null && path.isNotEmpty) {
        ProfileDemoStore.setPhotoForAllRoles(path: path, bytes: bytes);
      }
    } catch (_) {}

    try {
      await auth.uploadAvatarBytes(bytes);
    } catch (_) {
      // Non-fatal — account is already created; local preview still shows on Profile.
    }
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
        password: _passwordController.text.replaceAll(RegExp(r'[\r\n]'), '').trim(),
        countryCode: _countryIso!,
        acceptedTerms: _acceptedTerms,
      );

      if (!mounted) return;

      await _persistProfilePhoto(auth);
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

  Widget _profilePhotoPicker() {
    const size = 96.0;
    final hasPhoto = _profilePhotoBytes != null;

    final Widget photo;
    if (hasPhoto) {
      photo = Image.memory(
        _profilePhotoBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      photo = ColoredBox(
        color: AppColors.kycBackground,
        child: Center(
          child: Icon(
            Icons.add_a_photo_outlined,
            size: 36,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickProfilePhoto,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: photo,
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasPhoto ? 'Tap to change photo' : 'Add profile photo',
            style: context.typo.sm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
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
            const SizedBox(height: 20),
            _profilePhotoPicker(),
            const SizedBox(height: 8),
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
  /// Mirrors onChanged — browser autofill can update the visual field without
  /// always syncing [TextEditingController] before submit.
  String _emailTyped = '';
  String _passwordTyped = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _readEmail() {
    final fromController = _emailController.text.trim();
    if (fromController.isNotEmpty) return fromController;
    return _emailTyped.trim();
  }

  String _readPassword() {
    final fromController = _passwordController.text.replaceAll(RegExp(r'[\r\n]'), '').trim();
    if (fromController.isNotEmpty) return fromController;
    return _passwordTyped.replaceAll(RegExp(r'[\r\n]'), '').trim();
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
    // Capture credentials first. Do NOT call finishAutofillContext(shouldSave: false)
    // before reading — on Flutter web/Edge that discards autofill without writing
    // into the controllers and causes "Invalid email or password".
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final email = _readEmail();
    final password = _readPassword();

    if (email.isEmpty || password.isEmpty) {
      AppToast.error(
        context,
        'Enter your email and password. If the browser autofilled them, tap each field once, then try again.',
      );
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      AppToast.error(context, 'Enter a valid email address');
      return;
    }

    if (kDebugMode) {
      debugPrint('LOGIN → ${ApiConfig.authBase} (password len=${password.length})');
    }

    final auth = context.read<AuthProvider>();
    try {
      final result = await auth.login(email: email, password: password);
      if (!mounted) return;

      // Within the 7-day window: tokens issued, no OTP step.
      if (!result.requiresLoginOtp) {
        final user = result.user;
        if (user == null) {
          AppToast.error(context, 'Could not complete login. Please try again.');
          return;
        }
        if (user.accountStatus == 'suspended') {
          context.go('/account-suspended');
          return;
        }
        await PostAuthNavigation.continueAfterAuth(
          context,
          offerBiometricSetup: true,
          requireVerification: false,
        );
        return;
      }

      // 7+ days since last OTP (or never verified): require emailed OTP.
      context.push(
        '/login/verify-otp',
        extra: PasswordLoginOtpFlowData(
          email: result.email?.trim().isNotEmpty == true
              ? result.email!.trim()
              : email,
          password: password,
          alreadySent: false,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not sign in. Please try again.');
    }
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
                  onChanged: (value) => _emailTyped = value,
                ),
                _labeledField(
                  context,
                  'Password',
                  _passwordController,
                  obscure: true,
                  labelStyle: fieldLabelStyle,
                  inputStyle: inputStyle,
                  hintText: 'Enter your password',
                  onChanged: (value) => _passwordTyped = value,
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
    ValueChanged<String>? onChanged,
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
        onChanged: onChanged,
        style: fieldInputStyle,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: fieldInputStyle.copyWith(color: AppColors.textDisabled),
        ),
      ),
    );
  }
}
