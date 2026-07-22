import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/meetup_location.dart';

/// Pin-box entry point for meetup locations on the post delivery form.
class MeetupLocationsCard extends StatelessWidget {
  const MeetupLocationsCard({
    super.key,
    required this.locations,
    required this.onTap,
    this.errorText,
    this.maxLocations = 3,
  });

  final List<MeetupLocation> locations;
  final VoidCallback onTap;
  final String? errorText;
  final int maxLocations;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final hasLocations = locations.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: errorText != null ? AppColors.danger : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.kycBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meetup Locations (Max $maxLocations)',
                          style: typo.inputLabel.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasLocations
                              ? '${locations.length} location${locations.length == 1 ? '' : 's'} added'
                              : 'Add up to $maxLocations public meetup locations',
                          style: typo.sm.copyWith(color: AppColors.textSecondary),
                        ),
                        if (hasLocations) ...[
                          const SizedBox(height: 6),
                          ...locations.take(2).map(
                                (loc) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '• ${loc.displayLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: typo.sm.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                          if (locations.length > 2)
                            Text(
                              '+ ${locations.length - 2} more',
                              style: typo.sm.copyWith(
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasLocations ? 'Edit' : 'Add locations',
                        style: typo.sm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: typo.sm.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
