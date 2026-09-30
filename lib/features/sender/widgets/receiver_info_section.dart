import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/keyboard_utils.dart';
import '../../../core/phone/phone_countries.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_labeled_field.dart';
import '../../../core/widgets/international_phone_field.dart';
import '../../../data/models/meetup_location.dart';
import '../../../l10n/app_localizations.dart';
import 'field_info_tag.dart';

/// Receiver contact fields + Google Maps meetup location picker.
class ReceiverInfoSection extends StatefulWidget {
  const ReceiverInfoSection({
    super.key,
    this.emailErrorText,
    this.phoneErrorText,
    this.meetupErrorText,
    this.meetupLocations = const [],
    this.initialEmail,
    this.initialPhone,
    this.emailFieldKey,
    this.phoneFieldKey,
    this.meetupFieldKey,
    this.onEmailChanged,
    this.onPhoneChanged,
    this.onMeetupLocationsChanged,
  });

  final String? emailErrorText;
  final String? phoneErrorText;
  final String? meetupErrorText;
  final List<MeetupLocation> meetupLocations;
  final String? initialEmail;
  final String? initialPhone;
  final Key? emailFieldKey;
  final Key? phoneFieldKey;
  final Key? meetupFieldKey;
  final ValueChanged<String>? onEmailChanged;
  final ValueChanged<String>? onPhoneChanged;
  final ValueChanged<List<MeetupLocation>>? onMeetupLocationsChanged;

  @override
  State<ReceiverInfoSection> createState() => _ReceiverInfoSectionState();
}

class _ReceiverInfoSectionState extends State<ReceiverInfoSection> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  PhoneCountry _phoneCountry = PhoneCountries.byIso('FR');
  bool _meetupFocused = false;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    final phone = widget.initialPhone?.trim();
    if (phone != null && phone.isNotEmpty) {
      final parsed = PhoneCountries.parse(phone);
      _phoneCountry = parsed.country;
      _phoneController.text = parsed.national;
    }
    _phoneController.addListener(_emitPhone);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_emitPhone);
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emitPhone() {
    final national = PhoneCountries.nationalDigits(_phoneController.text);
    final full = national.isEmpty
        ? ''
        : PhoneCountries.formatFull(_phoneCountry, _phoneController.text);
    widget.onPhoneChanged?.call(full);
  }

  Future<void> _openMeetupPicker() async {
    setState(() => _meetupFocused = true);
    final result = await context.push<List<MeetupLocation>>(
      '/add-meetup-locations',
      extra: <String, dynamic>{
        'locations': widget.meetupLocations,
        'maxLocations': 1,
      },
    );
    if (!mounted) return;
    setState(() => _meetupFocused = false);
    if (result != null) {
      widget.onMeetupLocationsChanged?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final l10n = context.l10n;
    final hasMeetup = widget.meetupLocations.isNotEmpty;
    final meetupLabel = hasMeetup
        ? widget.meetupLocations.first.displayLabel
        : l10n.selectMeetupLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.receiverSection,
          style: typo.h3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.receiverContactIntro,
          style: typo.sm.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        AppLabeledField(
          label: l10n.receiverEmail,
          labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
          child: KeyedSubtree(
            key: widget.emailFieldKey,
            child: TextField(
              controller: _emailController,
              onTap: ensureSoftKeyboardVisible,
              onTapOutside: dismissKeyboardOnTapOutside,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              style: typo.input,
              onChanged: (value) => widget.onEmailChanged?.call(value.trim()),
              decoration: InputDecoration(
                hintText: 'receiver@example.com',
                hintStyle: typo.input.copyWith(color: AppColors.textDisabled),
                errorText: widget.emailErrorText,
              ),
            ),
          ),
        ),
        KeyedSubtree(
          key: widget.phoneFieldKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InternationalPhoneField(
                controller: _phoneController,
                country: _phoneCountry,
                label: l10n.receiverPhoneNumber,
                labelStyle: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                onCountryChanged: (country) {
                  setState(() => _phoneCountry = country);
                  _emitPhone();
                },
              ),
              if (widget.phoneErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    widget.phoneErrorText!,
                    style: typo.sm.copyWith(color: AppColors.danger),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: widget.meetupFieldKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.meetupLocationGoogleMaps,
                    style: typo.inputLabel.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const FieldInfoTag(
                    title: 'Traveler ↔ Receiver meetup',
                    message:
                        'This is the destination meetup spot where the traveler will meet the receiver to deliver the parcel (NFC Checkpoint Traveler & Receiver).\n\n'
                        'Choose a public place in the To / destination city.',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openMeetupPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.meetupErrorText != null
                            ? AppColors.danger
                            : (_meetupFocused
                                ? AppColors.primary
                                : AppColors.border),
                        width: _meetupFocused || widget.meetupErrorText != null
                            ? 1.5
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _meetupFocused || hasMeetup
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            meetupLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typo.input.copyWith(
                              color: hasMeetup
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasMeetup ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _meetupFocused
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.meetupErrorText != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.meetupErrorText!,
                  style: typo.sm.copyWith(color: AppColors.danger),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        FieldInfoHint(
          text: l10n.receiverDropOffNote,
        ),
      ],
    );
  }
}
