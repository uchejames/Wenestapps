// ============= report.dart =============
class Report {
  final String id;
  final String reporterId;
  final String reportedType; // property, user, review
  final String reportedId;
  final String reason;
  final String? description;
  final String status; // pending, reviewed, resolved
  final DateTime createdAt;

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedType,
    required this.reportedId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedType: json['reported_type'] as String,
      reportedId: json['reported_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'reported_type': reportedType,
      'reported_id': reportedId,
      'reason': reason,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

