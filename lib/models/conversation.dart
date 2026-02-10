class Conversation {
  final String id;
  final String? propertyId;
  final String initiatorId;
  final String receiverId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    this.propertyId,
    required this.initiatorId,
    required this.receiverId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String? ?? (throw const FormatException('Missing required field: id')),
      propertyId: json['property_id']?.toString(),
      initiatorId: json['initiator_id'] as String? ?? (throw const FormatException('Missing required field: initiator_id')),
      receiverId: json['receiver_id'] as String? ?? (throw const FormatException('Missing required field: receiver_id')),
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'property_id': propertyId,
      'initiator_id': initiatorId,
      'receiver_id': receiverId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Optional: helper to get the other participant
  String getOtherUserId(String currentUserId) {
    return currentUserId == initiatorId ? receiverId : initiatorId;
  }
}