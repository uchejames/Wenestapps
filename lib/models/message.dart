class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final String? propertyId;
  final String? attachmentUrl;
  final String messageType;
  final bool isRead;
  final DateTime sentAt;
  final DateTime? updatedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.propertyId,
    this.attachmentUrl,
    this.messageType = 'text',
    this.isRead = false,
    required this.sentAt,
    this.updatedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String? ?? '',
      propertyId: json['property_id']?.toString(),
      attachmentUrl: json['attachment_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] as bool? ?? false,
      sentAt: DateTime.parse(json['sent_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'property_id': propertyId != null ? int.tryParse(propertyId!) : null,
      'attachment_url': attachmentUrl,
      'message_type': messageType,
      'is_read': isRead,
      'sent_at': sentAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter to check if current user is sender
  bool isSentByMe(String currentUserId) {
    return senderId == currentUserId;
  }

  // Backward compatibility - map createdAt to sentAt
  DateTime get createdAt => sentAt;

  // Format time for display
  String get timeDisplay {
    final now = DateTime.now();
    final difference = now.difference(sentAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${sentAt.day}/${sentAt.month}/${sentAt.year}';
    }
  }
}