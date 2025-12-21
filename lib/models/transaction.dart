// ============= transaction.dart =============
class Transaction {
  final String id;
  final String userId;
  final String type; // payment, refund, commission
  final num amount;
  final String currency;
  final String status; // pending, completed, failed
  final String? reference;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'NGN',
    this.status = 'pending',
    this.reference,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      amount: json['amount'] as num,
      currency: json['currency'] as String? ?? 'NGN',
      status: json['status'] as String? ?? 'pending',
      reference: json['reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'status': status,
      'reference': reference,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
