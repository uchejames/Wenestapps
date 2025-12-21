// ============= saved_search.dart =============
class SavedSearch {
  final String id;
  final String userId;
  final String searchName;
  final Map<String, dynamic> searchCriteria;
  final DateTime createdAt;

  SavedSearch({
    required this.id,
    required this.userId,
    required this.searchName,
    required this.searchCriteria,
    required this.createdAt,
  });

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      searchName: json['search_name'] as String,
      searchCriteria: json['search_criteria'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'search_name': searchName,
      'search_criteria': searchCriteria,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
