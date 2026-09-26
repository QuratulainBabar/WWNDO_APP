import 'dart:typed_data';
import '../../l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/platform/keyboard_utils.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/api_config.dart';
import '../../core/navigation/app_navigation.dart';
import '../../core/phone/phone_countries.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_labeled_field.dart';
import '../../core/platform/temp_image_file.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/back_header.dart';
import '../../core/widgets/back_link.dart';
import '../../core/widgets/captured_image_preview.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/international_phone_field.dart';
import '../../core/widgets/legal_document_dialog.dart';
import '../../core/widgets/scrollable_form_screen.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/legal_documents.dart';
import '../../data/models/wallet_role.dart';
import '../../data/profile_demo_store.dart';
import '../../data/static_data.dart';
import '../../data/wallet_service.dart';
import '../../core/auth/kyc_verification_guard.dart';
import '../../core/config/demo_mode.dart';
import '../../core/widgets/kyc_status_badge.dart';
import '../../data/models/kyc_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kyc_provider.dart';
import '../onboarding/kyc_flow_actions.dart';
import '../onboarding/profile_photo_crop_screen.dart';
import '../sender/widgets/route_country_dropdown.dart';

enum EditProfileRole { sender, receiver, traveler }

EditProfileRole editProfileRoleFromRoute(GoRouterState state) {
  if (state.extra is EditProfileRole) {
    return state.extra as EditProfileRole;
  }
  if (state.extra == true) {
    return EditProfileRole.receiver;
  }
  return switch (state.uri.queryParameters['role']) {
    'receiver' => EditProfileRole.receiver,
    'traveler' => EditProfileRole.traveler,
    'sender' => EditProfileRole.sender,
    _ => EditProfileRole.sender,
  };
}

String settingsRouteForProfileRole(EditProfileRole role) => switch (role) {
      EditProfileRole.receiver => '/settings?role=receiver',
      EditProfileRole.traveler => '/settings?role=traveler',
      EditProfileRole.sender => '/settings?role=sender',
    };

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.role = EditProfileRole.sender});

  final EditProfileRole role;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _countryIso;
  late PhoneCountry _phoneCountry;
  String? _photoPath;
  /// In-memory preview so the circle updates immediately after pick / re-pick
  /// (Android may reuse the same cache path, which would not remount a path-based widget).
  Uint8List? _photoPreviewBytes;
  /// Cropped bytes from this session. Uploaded only when the user adjusts a new photo.
  Uint8List? _croppedPhotoBytes;
  /// User chose to continue without a profile photo (clears existing on save).
  bool _removeProfilePhoto = false;
  bool _saving = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');

    final savedIso = (user?.countryCode ?? '').trim().toUpperCase();
    final hasSavedIso = savedIso.isNotEmpty;

    late final PhoneCountry phoneCountry;
    late final String nationalRaw;

    if ((user?.phoneNumber ?? '').trim().isNotEmpty) {
      phoneCountry = PhoneCountries.byIso(hasSavedIso ? savedIso : 'FR');
      nationalRaw = user!.phoneNumber!.trim();
    } else if ((user?.phone ?? '').trim().isNotEmpty) {
      final parsed = PhoneCountries.parse(
        user!.phone,
        fallbackIso: hasSavedIso ? savedIso : 'FR',
      );
      phoneCountry = hasSavedIso ? PhoneCountries.byIso(savedIso) : parsed.country;
      nationalRaw = parsed.national;
    } else {
      phoneCountry = PhoneCountries.byIso(hasSavedIso ? savedIso : 'FR');
      nationalRaw = '';
    }

    _countryIso = hasSavedIso
        ? savedIso
        : ((user?.phone ?? '').trim().isNotEmpty ? phoneCountry.iso : null);
    _phoneCountry = _countryIso != null && _countryIso!.isNotEmpty
        ? PhoneCountries.byIso(_countryIso!)
        : phoneCountry;
    _phoneController = TextEditingController(
      text: nationalRaw.isEmpty
          ? ''
          : PhoneCountries.formatNationalAsYouType(nationalRaw, _phoneCountry),
    );
    _photoPath = ProfileDemoStore.photoPathFor(_walletRole);
    _photoPreviewBytes = ProfileDemoStore.photoBytesFor(_walletRole);
  }

  WalletRole get _walletRole => switch (widget.role) {
        EditProfileRole.receiver => WalletRole.receiver,
        EditProfileRole.traveler => WalletRole.traveler,
        EditProfileRole.sender => WalletRole.sender,
      };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onCountryChanged(String iso) {
    setState(() {
      _countryIso = iso;
      _phoneCountry = PhoneCountries.byIso(iso);
    });
  }

  Future<void> _pickPhoto() async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(
        title: 'Profile photo',
        subtitle: 'Choose how you want to add your photo',
      ),
    );
    if (!mounted) return;

    // Cancel → do not add a photo; clear any newly selected photo.
    if (result is ImageSourceSheetCancel) {
      setState(() {
        _croppedPhotoBytes = null;
        _photoPreviewBytes = null;
        _photoPath = null;
        _removeProfilePhoto = true;
      });
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

      final cropResult =
          await Navigator.of(context).push<ProfilePhotoCropResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => ProfilePhotoCropScreen(imageBytes: bytes),
        ),
      );
      if (!mounted || cropResult == null) return;

      setState(() {
        _croppedPhotoBytes = cropResult.bytes;
        _photoPreviewBytes = cropResult.bytes;
        _photoPath = null;
        _removeProfilePhoto = false;
      });
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not load that photo. Try another one.');
      }
    }
  }

  bool _hasExistingRemotePhoto(AuthProvider auth) {
    return (auth.user?.avatarUrl ?? '').trim().isNotEmpty;
  }

  bool _hasVisiblePhoto(AuthProvider auth) {
    if (_removeProfilePhoto) return false;
    if (_photoPreviewBytes != null && _photoPreviewBytes!.isNotEmpty) {
      return true;
    }
    if (_photoPath != null && _photoPath!.trim().isNotEmpty) return true;
    return _hasExistingRemotePhoto(auth);
  }

  Widget _buildProfilePhotoCircle(String avatarInitial, AuthProvider auth) {
    const size = 96.0;
    final Widget photo;
    if (!_removeProfilePhoto && _photoPreviewBytes != null) {
      photo = ClipOval(
        child: Image.memory(
          _photoPreviewBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    } else if (!_removeProfilePhoto && _photoPath != null) {
      photo = CapturedImagePreview(
        key: ValueKey(_photoPath),
        path: _photoPath!,
        width: size,
        height: size,
        clipOval: true,
      );
    } else if (!_removeProfilePhoto && _hasExistingRemotePhoto(auth)) {
      photo = ClipOval(
        child: Image.network(
          ApiConfig.resolveUploadUrl(auth.user!.avatarUrl!.trim()),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) =>
              AppAvatar(initial: avatarInitial, size: AvatarSize.large),
        ),
      );
    } else {
      photo = AppAvatar(initial: avatarInitial, size: AvatarSize.large);
    }

    return GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          photo,
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
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppToast.error(context, 'Name cannot be empty');
      return;
    }

    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      AppToast.error(context, 'Enter a valid email address');
      return;
    }
    if (_countryIso == null || _countryIso!.isEmpty) {
      AppToast.error(context, 'Select a country');
      return;
    }
    if (!PhoneCountries.isValidNational(
      _phoneController.text,
      country: _phoneCountry,
    )) {
      AppToast.error(context, 'Enter a valid phone number');
      return;
    }

    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);

    try {
      final national = PhoneCountries.nationalDigits(_phoneController.text);
      await auth.updateProfile(
        name: name,
        email: email,
        dialCode: _phoneCountry.dialCode,
        phoneNumber: national,
        phone: PhoneCountries.formatFull(_phoneCountry, _phoneController.text),
        countryCode: _countryIso!,
      );
      final cropped = _croppedPhotoBytes;
      if (_removeProfilePhoto) {
        ProfileDemoStore.clearPhotoForAllRoles();
        try {
          await auth.deleteAvatar();
        } catch (_) {
          // Non-fatal — profile fields still saved.
        }
      } else if (cropped != null && cropped.isNotEmpty) {
        final path = await writeTempImageFile(cropped);
        ProfileDemoStore.setPhotoForAllRoles(path: path, bytes: cropped);
        try {
          await auth.uploadAvatarBytes(cropped);
        } catch (_) {
          // Non-fatal — profile fields still saved.
        }
      }
      if (!mounted) return;
      AppToast.success(context, 'Profile updated');
      context.pushReplacement('/edit-profile/success', extra: widget.role);
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final auth = context.watch<AuthProvider>();
    final avatarInitial = (auth.user?.initial.isNotEmpty ?? false)
        ? auth.user!.initial
        : _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()[0].toUpperCase()
            : '?';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.surface,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: true,
        appBar: BackHeader(
          title: context.tr('Edit profile'),
          fallbackRoute: settingsRouteForProfileRole(widget.role),
        ),
        body: ColoredBox(
          color: AppColors.background,
          child: ScrollableFormScreen(
            actions: [
              AppButton(
                label: _saving || auth.loading ? 'Saving…' : 'Save changes',
                onPressed: _saving || auth.loading ? null : _save,
              ),
            ],
            child: switch (widget.role) {
              EditProfileRole.sender => _buildExtendedProfileForm(
                  typo,
                  auth: auth,
                  subtitle:
                      'This information is shown on your public profile when you send parcels.',
                  avatarInitial: avatarInitial,
                ),
              EditProfileRole.receiver => _buildExtendedProfileForm(
                  typo,
                  auth: auth,
                  subtitle:
                      'This information is shown on your public profile when you receive parcels.',
                  avatarInitial: avatarInitial,
                ),
              EditProfileRole.traveler => _buildExtendedProfileForm(
                  typo,
                  auth: auth,
                  subtitle:
                      'This information is shown on your public profile when you carry parcels.',
                  avatarInitial: avatarInitial,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExtendedProfileForm(
    AppTypography typo, {
    required AuthProvider auth,
    required String subtitle,
    required String avatarInitial,
  }) {
    final hasPhoto = _hasVisiblePhoto(auth);
    final caption =
        hasPhoto ? 'Tap to change photo' : 'Tap to upload a photo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile details', style: typo.h2),
        const SizedBox(height: 8),
        Text(subtitle, style: typo.sm.copyWith(height: 1.5)),
        const SizedBox(height: 24),
        AppLabeledField(
          label: 'Profile photo',
          labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
          child: Column(
            children: [
              _buildProfilePhotoCircle(avatarInitial, auth),
              const SizedBox(height: 8),
              Text(
                caption,
                style: typo.sm.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        AppLabeledField(
          label: 'Full name',
          labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
          child: TextField(
            controller: _nameController,
            onTap: ensureSoftKeyboardVisible,
            onTapOutside: dismissKeyboardOnTapOutside,
            style: typo.input,
            decoration: InputDecoration(
              hintText: 'Your full name',
              hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ),
        AppLabeledField(
          label: context.tr('Email'),
          labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
          child: TextField(
            controller: _emailController,
            onTap: ensureSoftKeyboardVisible,
            onTapOutside: dismissKeyboardOnTapOutside,
            keyboardType: TextInputType.emailAddress,
            style: typo.input,
            decoration: InputDecoration(
              hintText: 'you@email.com',
              hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
            ),
          ),
        ),
        RouteCountryDropdown(
          label: 'Country',
          value: _countryIso,
          hintText: 'Select country',
          onChanged: _onCountryChanged,
        ),
        InternationalPhoneField(
          label: 'Phone number',
          controller: _phoneController,
          country: _phoneCountry,
          onCountryChanged: (c) => setState(() {
            _phoneCountry = c;
            _countryIso = c.iso;
          }),
          labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
          inputStyle: typo.input,
          padding: const EdgeInsets.only(
            top: AppFieldSpacing.top,
            bottom: AppFieldSpacing.bottom,
          ),
        ),
      ],
    );
  }
}

class ProfileUpdatedSuccessScreen extends StatelessWidget {
  const ProfileUpdatedSuccessScreen({super.key, this.role = EditProfileRole.sender});

  final EditProfileRole role;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final settingsRoute = settingsRouteForProfileRole(role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
              child: BackLink(onTap: () => context.go(settingsRoute)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
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
                    Text('Profile updated', style: typo.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Your profile details have been saved. These details are now shown on your public profile.',
                      textAlign: TextAlign.center,
                      style: typo.sm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: 'Back to settings',
                      onPressed: () => context.go(settingsRoute),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _roleParam =>
      GoRouterState.of(context).uri.queryParameters['role'] ?? 'sender';

  String get _settingsRoute => switch (_roleParam) {
        'receiver' => '/settings?role=receiver',
        'traveler' => '/settings?role=traveler',
        _ => '/settings?role=sender',
      };

  Future<void> _updatePassword() async {
    final current = _currentController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      AppToast.error(context, 'Enter your current password');
      return;
    }
    if (newPassword.length < 8) {
      AppToast.error(context, 'New password must be at least 8 characters');
      return;
    }
    if (newPassword != confirm) {
      AppToast.error(context, 'Passwords do not match');
      return;
    }
    if (current == newPassword) {
      AppToast.error(context, 'New password must be different from current password');
      return;
    }

    final auth = context.read<AuthProvider>();

    try {
      await auth.changePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      if (!mounted) return;
      AppToast.success(context, 'Password updated successfully');
      context.pushReplacement('/change-password/success?role=$_roleParam');
    } on ApiException catch (e) {
      if (mounted) AppToast.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: BackHeader(
        title: 'Change password',
        fallbackRoute: _settingsRoute,
      ),
      body: ScrollableFormScreen(
        actions: [
          AppButton(
            label: auth.loading ? 'Updating…' : 'Update password',
            onPressed: auth.loading ? null : _updatePassword,
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update your password', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'Choose a strong password you have not used elsewhere.',
              style: typo.sm.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _passwordField(
              label: 'Current password',
              controller: _currentController,
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            _passwordField(
              label: 'New password',
              controller: _newController,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            _passwordField(
              label: 'Confirm new password',
              controller: _confirmController,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    final typo = context.typo;
    return AppLabeledField(
      label: label,
      labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.only(top: AppFieldSpacing.top, bottom: 12),
      child: TextField(
        controller: controller,
        onTap: () => ensureSoftKeyboardVisible(retry: true),
        onTapOutside: dismissKeyboardOnTapOutside,
        obscureText: obscure,
        style: typo.input,
        decoration: InputDecoration(
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.textSecondary,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}

class ChangePasswordSuccessScreen extends StatelessWidget {
  const ChangePasswordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final settingsRoute = roleParam == 'receiver'
        ? '/settings?role=receiver'
        : roleParam == 'traveler'
            ? '/settings?role=traveler'
            : '/settings?role=sender';
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
              Text('Password updated', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Your password has been changed successfully.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to settings',
                onPressed: () => context.go(settingsRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BackHeader(title: 'Terms & Privacy'),
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Legal documents', style: typo.h2),
            const SizedBox(height: 8),
            Text(
              'WWNGO is a peer-to-peer marketplace for Senders, Travelers, and Receivers. '
              'Review the full Terms and Privacy Policy before you use the Platform.',
              style: typo.sm.copyWith(height: 1.6),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'View Terms & Conditions',
              onPressed: () => showLegalDocumentDialog(
                context: context,
                title: LegalDocuments.termsTitle,
                sections: LegalDocuments.termsSections,
              ),
            ),
            const SizedBox(height: AppButton.stackGap),
            AppButton(
              label: 'View Privacy Policy',
              variant: AppButtonVariant.outline,
              onPressed: () => showLegalDocumentDialog(
                context: context,
                title: LegalDocuments.privacyTitle,
                sections: LegalDocuments.privacySections,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Last updated ${LegalDocuments.lastUpdated}',
              style: typo.sm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletWithdrawalSuccessScreen extends StatelessWidget {
  const WalletWithdrawalSuccessScreen({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final walletRoute = roleParam == null ? '/wallet' : '/wallet?role=$roleParam';
    final homeRoute = roleParam == 'receiver'
        ? '/receiver-home'
        : roleParam == 'traveler'
            ? '/traveler-home'
            : '/home';
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                child: const Icon(Icons.account_balance_outlined, size: 40, color: AppColors.success),
              ),
              const SizedBox(height: 20),
              Text('Withdrawal initiated', style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '${WalletService.formatMajor(amount)} is being transferred via Stripe Connect to your linked bank account. Arrives in 2–5 business days.',
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Back to wallet',
                textStyle: typo.button.copyWith(fontWeight: FontWeight.w700),
                onPressed: () => context.go(walletRoute),
              ),
              const SizedBox(height: AppButton.stackGap),
              AppButton(
                label: 'Go to home',
                variant: AppButtonVariant.outline,
                textStyle: typo.button.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                onPressed: () => context.go(homeRoute),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KycStatusScreen extends StatefulWidget {
  const KycStatusScreen({super.key});

  @override
  State<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends State<KycStatusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final demo = context.read<DemoModeProvider>().enabled;
      if (demo) return;
      try {
        await context.read<KycProvider>().refreshStatus(sync: true);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final roleParam = GoRouterState.of(context).uri.queryParameters['role'];
    final settingsRoute = roleParam == 'receiver'
        ? '/settings?role=receiver'
        : roleParam == 'traveler'
            ? '/settings?role=traveler'
            : '/settings?role=sender';
    final typo = context.typo;
    final user = context.watch<AuthProvider>().user;
    final kyc = context.watch<KycProvider>();
    final displayName = user?.name ?? StaticData.currentUser.name;
    final status = (kyc.lastStatus?.kycStatus.name ?? user?.kycStatus ?? 'pending')
        .toLowerCase();

    final (title, message, icon, iconColor, bgColor) = switch (status) {
      'approved' => (
          'Verification approved',
          '$displayName is verified on WWNGO. You can post deliveries, create trips, place bids, and withdraw earnings.',
          Icons.verified_user_outlined,
          AppColors.success,
          AppColors.success.withValues(alpha: 0.12),
        ),
      'submitted' => (
          'Pending review',
          'Your documents are with Sumsub for automated checks and manual review (SLA up to 48 hours).',
          Icons.hourglass_top_rounded,
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.12),
        ),
      'rejected' => (
          'Verification failed',
          'Your identity could not be verified. Please retry with a valid, clearly photographed document.',
          Icons.error_outline_rounded,
          AppColors.danger,
          AppColors.danger.withValues(alpha: 0.1),
        ),
      _ => (
          'Verification required',
          'Complete identity verification to unlock posting parcels, creating trips, and placing bids.',
          Icons.badge_outlined,
          AppColors.primary,
          AppColors.primary.withValues(alpha: 0.1),
        ),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.surface,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: BackHeader(
          title: context.tr('Identity verification'),
          fallbackRoute: settingsRoute,
        ),
        body: ScrollableFormScreen(
          actions: [
            if (status != 'approved')
              AppButton(
                label: kyc.loading
                    ? 'Please wait…'
                    : status == 'submitted'
                        ? 'Refresh status'
                        : 'Verify Identity',
                onPressed: kyc.loading
                    ? null
                    : () {
                        if (status == 'submitted') {
                          KycFlowActions.refreshAndRoute(context);
                        } else {
                          context.push(KycVerificationGuard.routeForUser(user));
                        }
                      },
              ),
            AppButton(
              label: 'Back to settings',
              variant: status == 'approved' ? AppButtonVariant.primary : AppButtonVariant.outline,
              onPressed: () => appNavigateBackFromContext(context, fallback: settingsRoute),
            ),
          ],
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 40, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(title, style: typo.h1, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: typo.sm.copyWith(height: 1.5),
              ),
              const SizedBox(height: 16),
              KycStatusBadge(user: user),
              const SizedBox(height: 8),
              Text(
                'Status: ${KycStatusValue.fromString(status).label}',
                style: typo.bodyBold.copyWith(color: iconColor),
              ),
              if (kyc.loading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
              if (kyc.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  kyc.error!,
                  textAlign: TextAlign.center,
                  style: typo.sm.copyWith(color: AppColors.danger),
                ),
              ],
              if (user != null && status == 'approved') ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.kycBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verified details', style: typo.bodyBold),
                      const SizedBox(height: 8),
                      Text('Name: ${user.name}', style: typo.sm),
                      Text('Email: ${user.email}', style: typo.sm),
                      Text('Country: ${user.countryCode}', style: typo.sm),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
