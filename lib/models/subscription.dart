// ============= subscription.dart =============
class Subscription {
  final String id;
  final String agencyId;
  final String planType; // basic, premium, enterprise
  final num amount;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // active, expired, cancelled
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.agencyId,
    required this.planType,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    required this.createdAt,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      planType: json['plan_type'] as String,
      amount: json['amount'] as num,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agency_id': agencyId,
      'plan_type': planType,
      'amount': amount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
