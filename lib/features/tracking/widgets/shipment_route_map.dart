import 'dart:convert';
import 'dart:math' as math;
import '../../../l10n/app_localizations.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/external_links.dart';
import '../../../data/models/shipment.dart';

/// Real map preview for the shipment route.
/// Tries Google Static Maps, then OpenStreetMap fallback.
class ShipmentRouteMap extends StatefulWidget {
  const ShipmentRouteMap({
    super.key,
    required this.shipment,
    required this.stepProgress,
  });

  final Shipment shipment;
  final int stepProgress;

  @override
  State<ShipmentRouteMap> createState() => _ShipmentRouteMapState();
}

class _ShipmentRouteMapState extends State<ShipmentRouteMap> {
  String? _mapUrl;
  bool _loading = true;
  String? _error;

  Shipment get shipment => widget.shipment;

  String get _origin {
    final city = shipment.fromCity.trim();
    final code = shipment.fromCode.trim();
    if (city.isEmpty) return code;
    if (code.isEmpty || code == 'XX') return city;
    return '$city, $code';
  }

  String get _destination {
    final city = shipment.toCity.trim();
    final code = shipment.toCode.trim();
    if (city.isEmpty) return code;
    if (code.isEmpty || code == 'XX') return city;
    return '$city, $code';
  }

  @override
  void initState() {
    super.initState();
    _resolveMap();
  }

  @override
  void didUpdateWidget(covariant ShipmentRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipment.fromCity != shipment.fromCity ||
        oldWidget.shipment.toCity != shipment.toCity ||
        oldWidget.shipment.fromCode != shipment.fromCode ||
        oldWidget.shipment.toCode != shipment.toCode) {
      _resolveMap();
    }
  }

  Future<void> _resolveMap() async {
    setState(() {
      _loading = true;
      _error = null;
      _mapUrl = null;
    });

    try {
      final googleUrl = _googleStaticMapUrl(width: 640, height: 360, scale: 2);
      if (googleUrl != null && await _urlLooksLikeImage(googleUrl)) {
        if (!mounted) return;
        setState(() {
          _mapUrl = googleUrl;
          _loading = false;
        });
        return;
      }

      final osmUrl = await _osmStaticMapUrl(width: 600, height: 340);
      if (osmUrl != null && await _urlLooksLikeImage(osmUrl)) {
        if (!mounted) return;
        setState(() {
          _mapUrl = osmUrl;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load map tiles';
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RouteMap] resolve failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load map';
      });
    }
  }

  String? _googleStaticMapUrl({
    required int width,
    required int height,
    required int scale,
  }) {
    final key = ApiConfig.googleMapsApiKey.trim();
    if (key.isEmpty || _origin.isEmpty || _destination.isEmpty) return null;

    final w = width.clamp(200, 640);
    final h = height.clamp(120, 640);
    final s = scale.clamp(1, 2);

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?size=${w}x$h'
        '&scale=$s'
        '&maptype=roadmap'
        '&markers=${Uri.encodeQueryComponent('color:0x1A56DB|label:A|$_origin')}'
        '&markers=${Uri.encodeQueryComponent('color:0x10B981|label:B|$_destination')}'
        '&path=${Uri.encodeQueryComponent('color:0x1A56DBFF|weight:4|$_origin|$_destination')}'
        '&key=${Uri.encodeQueryComponent(key)}';
  }

  Future<String?> _osmStaticMapUrl({
    required int width,
    required int height,
  }) async {
    final from = await _geocode(_origin);
    final to = await _geocode(_destination);
    if (from == null || to == null) return null;

    final centerLat = (from.$1 + to.$1) / 2;
    final centerLng = (from.$2 + to.$2) / 2;
    final zoom = _zoomForDistance(from, to);

    final w = width.clamp(200, 800);
    final h = height.clamp(120, 800);

    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$centerLat,$centerLng'
        '&zoom=$zoom'
        '&size=${w}x$h'
        '&maptype=mapnik'
        '&markers=${from.$1},${from.$2},lightblue1'
        '|${to.$1},${to.$2},green1';
  }

  int _zoomForDistance((double, double) a, (double, double) b) {
    final latDiff = (a.$1 - b.$1).abs();
    final lngDiff = (a.$2 - b.$2).abs();
    final span = math.max(latDiff, lngDiff);
    if (span > 40) return 3;
    if (span > 20) return 4;
    if (span > 10) return 5;
    if (span > 5) return 6;
    if (span > 2) return 7;
    if (span > 0.8) return 8;
    if (span > 0.3) return 9;
    return 10;
  }

  Future<(double, double)?> _geocode(String query) async {
    final key = ApiConfig.googleMapsApiKey.trim();
    if (key.isNotEmpty) {
      try {
        final uri = Uri.https(
          'maps.googleapis.com',
          '/maps/api/geocode/json',
          {'address': query, 'key': key},
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          if (json['status'] == 'OK') {
            final results = json['results'] as List?;
            if (results != null && results.isNotEmpty) {
              final loc =
                  (results.first as Map)['geometry']?['location'] as Map?;
              final lat = (loc?['lat'] as num?)?.toDouble();
              final lng = (loc?['lng'] as num?)?.toDouble();
              if (lat != null && lng != null) return (lat, lng);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[RouteMap] Google geocode failed: $e');
      }
    }

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'json',
        'limit': '1',
      });
      final res = await http
          .get(
            uri,
            headers: const {
              'User-Agent': 'WWNGO-App/1.0 (route-map)',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body);
        if (list is List && list.isNotEmpty) {
          final first = list.first as Map;
          final lat = double.tryParse('${first['lat']}');
          final lng = double.tryParse('${first['lon']}');
          if (lat != null && lng != null) return (lat, lng);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[RouteMap] Nominatim geocode failed: $e');
    }
    return null;
  }

  Future<bool> _urlLooksLikeImage(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '[RouteMap] image HTTP ${res.statusCode}: '
            '${res.bodyBytes.length > 120 ? res.body.substring(0, 120) : res.body}',
          );
        }
        return false;
      }
      final type = res.headers['content-type'] ?? '';
      if (type.contains('image')) return true;
      // Some gateways omit content-type; accept PNG/JPEG magic bytes.
      final bytes = res.bodyBytes;
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return true;
      }
      if (bytes.length >= 3 &&
          bytes[0] == 0xFF &&
          bytes[1] == 0xD8 &&
          bytes[2] == 0xFF) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('[RouteMap] image check failed: $e');
      return false;
    }
  }

  Future<void> _openInGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(_origin)}'
      '&destination=${Uri.encodeComponent(_destination)}'
      '&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.routeMap,
                style: typo.h3.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: _openInGoogleMaps,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(context.l10n.openMap),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_loading)
                  const _MapPlaceholder(message: 'Loading map…', busy: true)
                else if (_mapUrl != null)
                  Image.network(
                    _mapUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _MapPlaceholder(
                      message: 'Map unavailable',
                      detail: shipment.route,
                      compact: true,
                      onRetry: _resolveMap,
                    ),
                  )
                else
                  _MapPlaceholder(
                    message: _error ?? 'Map unavailable',
                    detail: shipment.route,
                    compact: true,
                    onRetry: _resolveMap,
                    onOpenExternal: _openInGoogleMaps,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _RouteEndpointsBar(
          fromLabel: shipment.fromCity.isNotEmpty
              ? shipment.fromCity
              : shipment.fromCode,
          fromCode: shipment.fromCode,
          toLabel:
              shipment.toCity.isNotEmpty ? shipment.toCity : shipment.toCode,
          toCode: shipment.toCode,
          onOpenFrom: () => ExternalLinks.openMapPlace(
            shipment.fromCity.isNotEmpty
                ? shipment.fromCity
                : _origin,
          ),
          onOpenTo: () => ExternalLinks.openMapPlace(
            shipment.toCity.isNotEmpty ? shipment.toCity : _destination,
          ),
        ),
        if (shipment.flightNumber != null) ...[
          const SizedBox(height: 8),
          Text(
            'Flight ${shipment.flightNumber}',
            style: typo.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _RouteEndpointsBar extends StatelessWidget {
  const _RouteEndpointsBar({
    required this.fromLabel,
    required this.fromCode,
    required this.toLabel,
    required this.toCode,
    required this.onOpenFrom,
    required this.onOpenTo,
  });

  final String fromLabel;
  final String fromCode;
  final String toLabel;
  final String toCode;
  final VoidCallback onOpenFrom;
  final VoidCallback onOpenTo;

  @override
  Widget build(BuildContext context) {
    final fromSub = fromCode.trim().isNotEmpty &&
            fromCode.trim().toUpperCase() != 'XX' &&
            fromCode.trim().toLowerCase() != fromLabel.trim().toLowerCase()
        ? fromCode.trim().toUpperCase()
        : null;
    final toSub = toCode.trim().isNotEmpty &&
            toCode.trim().toUpperCase() != 'XX' &&
            toCode.trim().toLowerCase() != toLabel.trim().toLowerCase()
        ? toCode.trim().toUpperCase()
        : null;

    return Column(
      children: [
        if (fromLabel.trim().isNotEmpty)
          _RouteEndpoint(
            markerColor: AppColors.primary,
            title: context.tr('From'),
            place: fromLabel,
            subtitle: fromSub,
            onTap: onOpenFrom,
          ),
        if (fromLabel.trim().isNotEmpty && toLabel.trim().isNotEmpty)
          const SizedBox(height: 8),
        if (toLabel.trim().isNotEmpty)
          _RouteEndpoint(
            markerColor: AppColors.success,
            title: context.tr('To'),
            place: toLabel,
            subtitle: toSub,
            onTap: onOpenTo,
          ),
      ],
    );
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.markerColor,
    required this.title,
    required this.place,
    required this.onTap,
    this.subtitle,
  });

  final Color markerColor;
  final String title;
  final String place;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: markerColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: markerColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: typo.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: markerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place,
                      style: typo.sm.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: typo.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.openInMaps,
                      style: typo.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({
    required this.message,
    this.detail,
    this.busy = false,
    this.compact = false,
    this.onRetry,
    this.onOpenExternal,
  });

  final String message;
  final String? detail;
  final bool busy;
  final bool compact;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenExternal;

  @override
  Widget build(BuildContext context) {
    final typo = context.typo;
    return ColoredBox(
      color: const Color(0xFFE8EEF9),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.map_outlined,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typo.sm.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typo.caption.copyWith(fontSize: 12),
                    ),
                  ],
                  if (!busy && (onRetry != null || onOpenExternal != null)) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onRetry != null)
                          TextButton(
                            onPressed: onRetry,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(context.tr('Retry')),
                          ),
                        if (onOpenExternal != null)
                          TextButton(
                            onPressed: onOpenExternal,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: const Text('Open Maps'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
