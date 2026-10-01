import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../layout/responsive.dart';
import '../navigation/app_navigation.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'back_link.dart';

class BackHeader extends StatelessWidget implements PreferredSizeWidget {
  const BackHeader({
    super.key,
    required this.title,
    this.onBack,
    this.fallbackRoute,
    this.centerTitle = true,
    this.showBottomBorder = true,
  });

  final String title;
  final VoidCallback? onBack;
  final String? fallbackRoute;
  final bool centerTitle;
  final bool showBottomBorder;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  void _handleBack(BuildContext context) {
    appNavigateBackFromContext(context, fallback: fallbackRoute);
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    final backControl = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBack ?? () => _handleBack(context),
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: BackLinkLabel(),
        ),
      ),
    );

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: AppColors.surface,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: preferredSize.height,
      titleSpacing: context.horizontalPadding,
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: AppColors.border),
            )
          : null,
      title: centerTitle
          ? Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  // Keep title clear of the back control on narrow screens /
                  // longer translations without forcing the back label to wrap.
                  padding: const EdgeInsets.symmetric(horizontal: 88),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.headerTitle,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.38,
                    ),
                    child: backControl,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.38,
                  ),
                  child: backControl,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.headerTitle,
                  ),
                ),
              ],
            ),
    );
  }
}

class SimpleHeader extends StatelessWidget implements PreferredSizeWidget {
  const SimpleHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Size get preferredSize => Size.fromHeight(subtitle != null ? 64 : 52);

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        14,
        context.horizontalPadding,
        14,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Text(title, style: typo.headerTitle),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: typo.sm),
          ],
        ],
      ),
    );
  }
}
