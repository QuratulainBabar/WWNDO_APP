import '../../core/api/api_client.dart';
import '../../core/config/demo_mode.dart';
import '../models/chat_conversation_preview.dart';
import '../models/chat_message.dart';

class ChatThreadDetail {
  const ChatThreadDetail({
    required this.id,
    required this.name,
    required this.shipmentId,
    required this.messages,
    this.unlocked = true,
  });

  final String id;
  final String name;
  final String shipmentId;
  final List<ChatMessage> messages;
  final bool unlocked;
}

/// Backend chat / conversations API.
class ChatRepository {
  ChatRepository({
    required ApiClient apiClient,
    DemoModeProvider? demoMode,
  })  : _apiClient = apiClient,
        _demoMode = demoMode;

  final ApiClient _apiClient;
  final DemoModeProvider? _demoMode;

  bool get _isDemoMode => _demoMode?.enabled ?? false;

  Future<List<ChatConversationPreview>> listConversations({
    String? threadType,
  }) async {
    if (_isDemoMode) return const [];

    final query = threadType != null && threadType.isNotEmpty
        ? '?threadType=${Uri.encodeQueryComponent(threadType)}'
        : '';
    final data = await _apiClient.get('/chats$query', authenticated: true);
    final list = data['conversations'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(
          (item) => ChatConversationPreview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ChatThreadDetail> getConversation(String id) async {
    if (_isDemoMode) {
      return ChatThreadDetail(
        id: id,
        name: 'Contact',
        shipmentId: '',
        messages: const [],
      );
    }

    final data = await _apiClient.get('/chats/$id', authenticated: true);
    final conversation = data['conversation'];
    final messagesRaw = data['messages'];
    final convMap = conversation is Map
        ? Map<String, dynamic>.from(conversation)
        : <String, dynamic>{};
    final messages = messagesRaw is List
        ? messagesRaw
            .whereType<Map>()
            .map(
              (m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)),
            )
            .toList()
        : const <ChatMessage>[];

    return ChatThreadDetail(
      id: convMap['id'] as String? ?? id,
      name: convMap['name'] as String? ?? 'Contact',
      shipmentId: convMap['shipmentId'] as String? ?? '',
      messages: messages,
      unlocked: _readUnlocked(convMap['unlocked']),
    );
  }

  static bool _readUnlocked(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return true;
  }

  Future<ChatMessage> sendMessage(String conversationId, String text) async {
    if (_isDemoMode) {
      return ChatMessage(
        text: text,
        isMine: true,
        time: 'Just now',
      );
    }

    final data = await _apiClient.post(
      '/chats/$conversationId/messages',
      body: {'text': text},
      authenticated: true,
    );
    return ChatMessage.fromJson(data);
  }

  Future<ChatMessage> sendImage(String conversationId, String filePath) async {
    if (_isDemoMode) {
      return ChatMessage(
        text: '',
        isMine: true,
        time: 'Just now',
        isImage: true,
        imageName: filePath.split('/').last,
        imagePath: filePath,
      );
    }

    final data = await _apiClient.postMultipart(
      '/chats/$conversationId/messages/image',
      files: [
        MultipartFilePart(field: 'image', filePath: filePath),
      ],
      authenticated: true,
    );
    return ChatMessage.fromJson(data);
  }
}
