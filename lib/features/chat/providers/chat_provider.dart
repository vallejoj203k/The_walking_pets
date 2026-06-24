import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/message_model.dart';

class ChatProvider extends ChangeNotifier {
  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<ConversationModel> get conversations =>
      List.unmodifiable(_conversations);
  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  Future<ConversationModel?> getOrCreateConversation(
      String user1Id, String user2Id) async {
    try {
      // Ensure consistent order
      final sorted = [user1Id, user2Id]..sort();
      final u1 = sorted[0];
      final u2 = sorted[1];

      // Check existing
      final existing = await SupabaseService.client
          .from('conversations')
          .select()
          .or('and(user1_id.eq.$u1,user2_id.eq.$u2),and(user1_id.eq.$u2,user2_id.eq.$u1)')
          .maybeSingle();

      if (existing != null) {
        return ConversationModel.fromMap(existing);
      }

      // Create new
      final data = await SupabaseService.client
          .from('conversations')
          .insert({
            'user1_id': u1,
            'user2_id': u2,
          })
          .select()
          .single();

      return ConversationModel.fromMap(data);
    } catch (e) {
      debugPrint('[ChatProvider] getOrCreateConversation: $e');
      return null;
    }
  }

  Future<void> loadConversations(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('conversations')
          .select()
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .order('last_message_time', ascending: false);

      _conversations =
          (data as List).map((e) => ConversationModel.fromMap(e)).toList();

      // Enrich with other user names
      for (final conv in _conversations) {
        final otherId =
            conv.user1Id == userId ? conv.user2Id : conv.user1Id;
        conv.otherUserId = otherId;
        conv.otherUserName = await _getUserName(otherId);
      }
      _error = null;
    } catch (e) {
      _error = 'Error al cargar conversaciones.';
      debugPrint('[ChatProvider] loadConversations: $e');
    }
    _setLoading(false);
  }

  Future<String?> _getUserName(String userId) async {
    try {
      // Try walker first
      final walker = await SupabaseService.client
          .from('walkers')
          .select('name')
          .eq('user_id', userId)
          .maybeSingle();
      if (walker != null) return walker['name'] as String?;

      // Try owner
      final owner = await SupabaseService.client
          .from('owners')
          .select('name')
          .eq('user_id', userId)
          .maybeSingle();
      if (owner != null) return owner['name'] as String?;
    } catch (e) {
      debugPrint('[ChatProvider] _getUserName: $e');
    }
    return null;
  }

  Stream<List<MessageModel>> messagesStream(String conversationId) {
    return SupabaseService.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((list) =>
            list.map((e) => MessageModel.fromMap(e)).toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await SupabaseService.client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'text': text,
        'created_at': now,
        'is_read': false,
      });

      // Update conversation last message
      await SupabaseService.client
          .from('conversations')
          .update({
            'last_message': text,
            'last_message_time': now,
          })
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('[ChatProvider] sendMessage: $e');
    }
  }

  Future<void> markAsRead(
      String conversationId, String currentUserId) async {
    try {
      await SupabaseService.client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('[ChatProvider] markAsRead: $e');
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
