class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    required this.isRead,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      receiverId: map['receiver_id'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      isRead: map['is_read'] as bool? ?? false,
    );
  }
}

class ConversationModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;

  // Derived
  String? otherUserName;
  String? otherUserId;

  ConversationModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
    this.otherUserName,
    this.otherUserId,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      user1Id: map['user1_id'] as String,
      user2Id: map['user2_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageTime: DateTime.parse(
              map['last_message_time'] as String? ??
                  map['created_at'] as String)
          .toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
