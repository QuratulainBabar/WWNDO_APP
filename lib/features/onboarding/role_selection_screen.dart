import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/selected_role.dart';
import '../../core/auth/post_auth_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_svg_icon.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/screen_body.dart';
import '../../data/models/wallet_role.dart';
import '../../providers/auth_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  WalletRole? _selectedRole;
  bool _saving = false;

  Future<void> _continue() async {
    final role = _selectedRole;
    if (role == null || _saving) return;

    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);

    try {
      try {
        final updated = await auth.setRole(SelectedRoleStore.apiValue(role));
        await SelectedRoleStore.saveForUser(
          userId: updated.id,
          email: updated.email,
          role: role,
        );
      } catch (e) {
        // Still continue onboarding if role API/storage fails; keep local cache.
        final user = auth.user;
        if (user != null) {
          await SelectedRoleStore.saveForUser(
            userId: user.id,
            email: user.email,
            role: role,
          );
          await auth.repository.updateCurrentUser(user.copyWith(role: SelectedRoleStore.apiValue(role)));
        }
        if (e is ApiException && mounted) {
          // Non-blocking: show warning but proceed.
          AppToast.info(context, 'Role saved locally. Continuing…');
        }
      }

      if (!mounted) return;

      // Email/phone verify → Sumsub KYC → home
      await PostAuthNavigation.continueAfterAuth(
        context,
        offerBiometricSetup: false,
        requireVerification: true,
      );
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          e is ApiException ? e.message : 'Could not continue. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select your account', style: typo.h1),
            const SizedBox(height: 8),
            Text(
              'Select how you want to use WWNGO today.',
              style: typo.subheading,
            ),
            const SizedBox(height: 24),
            _RoleCard(
              iconAsset: AppIcons.roleSender,
              title: 'Sender',
              description: 'Create parcel requests and choose matching travelers.',
              selected: _selectedRole == WalletRole.sender,
              onTap: () => setState(() => _selectedRole = WalletRole.sender),
            ),
            _RoleCard(
              iconAsset: AppIcons.roleTraveler,
              title: 'Traveler',
              description: 'Create trips and carry parcels on your route.',
              selected: _selectedRole == WalletRole.traveler,
              onTap: () => setState(() => _selectedRole = WalletRole.traveler),
            ),
            _RoleCard(
              iconAsset: AppIcons.roleReceiver,
              title: 'Receiver',
              description: 'Accept parcel requests and receive your parcel securely.',
              selected: _selectedRole == WalletRole.receiver,
              onTap: () => setState(() => _selectedRole = WalletRole.receiver),
            ),
            const SizedBox(height: 8),
            AppButton(
              label: _saving ? 'Continuing…' : 'Continue',
              onPressed: _selectedRole == null || _saving ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.iconAsset,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return AppCard(
      highlighted: selected,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AppSvgIcon(
                    asset: iconAsset,
                    size: 26,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: typo.bodyBold.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(description, style: typo.sm),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
