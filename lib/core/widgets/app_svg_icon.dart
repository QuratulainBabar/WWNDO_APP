import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

abstract final class AppIcons {
  static const home = 'assets/icons/home.svg';
  static const trips = 'assets/icons/trips.svg';
  static const track = 'assets/icons/track.svg';
  static const profile = 'assets/icons/profile.svg';
  static const parcel = 'assets/icons/parcel.svg';
  static const postedParcels = 'assets/icons/posted_parcels.svg';
  static const traveler = 'assets/icons/traveler.svg';
  static const chat = 'assets/icons/chat.svg';
  static const browse = 'assets/icons/browse.svg';
  static const match = 'assets/icons/match.svg';
  static const history = 'assets/icons/history.svg';
  static const settings = 'assets/icons/settings.svg';
  static const partyPopper = 'assets/icons/party_popper.svg';
  static const notification = 'assets/icons/notification.svg';
  static const roleSender = 'assets/icons/role_sender.svg';
  static const roleTraveler = 'assets/icons/role_traveler.svg';
  static const roleReceiver = 'assets/icons/role_receiver.svg';
}

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon({
    super.key,
    required this.asset,
    this.size = 24,
    this.color,
  });

  final String asset;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? AppColors.primary,
        BlendMode.srcIn,
      ),
    );
  }
}
