import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../../router/app_router.dart';

/// WhatsApp-style in-app notification banner (slides from top while app is open).
abstract final class PushNotificationBanner {
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;
  static _PushBannerState? _bannerState;

  static void show({
    required String title,
    String? body,
    VoidCallback? onTap,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    void insert() {
      final overlay = rootNavigatorKey.currentState?.overlay;
      if (overlay == null) return;

      _dismiss(immediate: true);

      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) {
          final topInset = MediaQuery.paddingOf(context).top;
          return Positioned(
            top: topInset + 8,
            left: 10,
            right: 10,
            child: _WhatsAppStyleBanner(
              title: trimmedTitle,
              body: body?.trim(),
              onTap: () {
                _dismiss();
                onTap?.call();
              },
              onDismiss: _dismiss,
              onReady: (state) => _bannerState = state,
            ),
          );
        },
      );

      _entry = entry;
      overlay.insert(entry);
      HapticFeedback.mediumImpact();

      _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
    }

    if (rootNavigatorKey.currentState?.overlay != null) {
      insert();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => insert());
    }
  }

  static void _dismiss({bool immediate = false}) {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    final entry = _entry;
    if (entry == null) return;

    if (immediate || _bannerState == null) {
      entry.remove();
      _entry = null;
      _bannerState = null;
      return;
    }

    _bannerState!.dismiss().then((_) {
      entry.remove();
      if (_entry == entry) {
        _entry = null;
        _bannerState = null;
      }
    });
  }
}

class _WhatsAppStyleBanner extends StatefulWidget {
  const _WhatsAppStyleBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
    required this.onReady,
  });

  final String title;
  final String? body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final ValueChanged<_PushBannerState> onReady;

  @override
  State<_WhatsAppStyleBanner> createState() => _PushBannerState();
}

class _PushBannerState extends State<_WhatsAppStyleBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady(this);
    });
  }

  Future<void> dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _avatarLetter {
    final trimmed = widget.title.trim();
    if (trimmed.isEmpty) return 'W';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Material(
            color: Colors.transparent,
            elevation: 12,
            shadowColor: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(16),
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                setState(() {
                  _dragOffset = (_dragOffset + details.delta.dy).clamp(-120.0, 0.0);
                });
              },
              onVerticalDragEnd: (details) {
                if (_dragOffset < -40 || (details.primaryVelocity ?? 0) < -400) {
                  widget.onDismiss();
                  return;
                }
                setState(() => _dragOffset = 0);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        _avatarLetter,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WWNGO',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          if (widget.body != null && widget.body!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.body!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: widget.onDismiss,
                      icon: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
