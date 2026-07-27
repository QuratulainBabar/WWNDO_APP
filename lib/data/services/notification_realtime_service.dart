import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/app_notification.dart';
import '../models/wallet_role.dart';

typedef AccessTokenProvider = Future<String?> Function();

/// Server-sent events client for live notification updates.
class NotificationRealtimeService {
  NotificationRealtimeService({
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  StreamSubscription<String>? _subscription;
  Timer? _reconnectTimer;
  WalletRole? _role;
  AccessTokenProvider? _tokenProvider;
  bool _disposed = false;
  int _reconnectAttempt = 0;

  final _incomingController = StreamController<AppNotification>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();

  Stream<AppNotification> get onNotification => _incomingController.stream;
  Stream<int> get onUnreadCount => _unreadCountController.stream;

  bool get isConnected => _subscription != null;

  Future<void> connect({
    required WalletRole role,
    required AccessTokenProvider tokenProvider,
  }) async {
    _role = role;
    _tokenProvider = tokenProvider;
    _reconnectAttempt = 0;
    await _openStream();
  }

  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    _role = null;
    _tokenProvider = null;
  }

  Future<void> _openStream() async {
    if (_disposed) return;
    final role = _role;
    final tokenProvider = _tokenProvider;
    if (role == null || tokenProvider == null) return;

    await _subscription?.cancel();
    _subscription = null;

    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      _scheduleReconnect();
      return;
    }

    final uri = Uri.parse(
      '${ApiConfig.apiV1}/notifications/stream?role=${role.queryParam}',
    );
    final request = http.Request('GET', uri);
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Cache-Control'] = 'no-cache';

    try {
      final response = await _http.send(request);
      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            'Notification SSE failed: ${response.statusCode} $uri',
          );
        }
        _scheduleReconnect();
        return;
      }

      _reconnectAttempt = 0;
      var buffer = '';
      _subscription = response.stream
          .transform(utf8.decoder)
          .listen(
        (chunk) {
          buffer += chunk;
          while (true) {
            final boundary = buffer.indexOf('\n\n');
            if (boundary < 0) break;
            final block = buffer.substring(0, boundary);
            buffer = buffer.substring(boundary + 2);
            _handleEventBlock(block);
          }
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification SSE connect error: $e');
      }
      _scheduleReconnect();
    }
  }

  void _handleEventBlock(String block) {
    for (final line in block.split('\n')) {
      if (!line.startsWith('data:')) continue;
      final raw = line.substring(5).trim();
      if (raw.isEmpty) return;

      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return;

        final unread = (decoded['unreadCount'] as num?)?.toInt();
        if (unread != null) {
          _unreadCountController.add(unread);
        }

        final notificationJson = decoded['notification'];
        if (notificationJson is Map<String, dynamic>) {
          final notification = AppNotification.fromJson(
            notificationJson,
            fallbackRole: _role,
          );
          _incomingController.add(notification);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Notification SSE parse error: $e');
        }
      }
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _role == null || _tokenProvider == null) return;
    _subscription?.cancel();
    _subscription = null;

    _reconnectTimer?.cancel();
    final delaySeconds = (1 << _reconnectAttempt.clamp(0, 4)).clamp(1, 16);
    _reconnectAttempt += 1;
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _openStream);
  }

  void dispose() {
    disconnect();
    _incomingController.close();
    _unreadCountController.close();
    _http.close();
  }
}
