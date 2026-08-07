/// Wrapper générique autour du format de pagination Laravel :
/// { "data": [...], "links": {...}, "meta": { "current_page", "last_page", "total", ... } }
class PaginatedResponse<T> {
  final List<T> data;
  final int pageActuelle;
  final int dernierePage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.pageActuelle,
    required this.dernierePage,
    required this.total,
  });

  bool get aPlusDePages => pageActuelle < dernierePage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final items = (json['data'] as List)
        .map((item) => fromJsonItem(item as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>?;

    return PaginatedResponse<T>(
      data: items,
      pageActuelle: meta?['current_page'] as int? ?? 1,
      dernierePage: meta?['last_page'] as int? ?? 1,
      total: meta?['total'] as int? ?? items.length,
    );
  }
}
