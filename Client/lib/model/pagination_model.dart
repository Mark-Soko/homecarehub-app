class Pagination {
  var currentPage;
  var totalPages;
  var totalItems;

  Pagination({this.currentPage, this.totalPages, this.totalItems});

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: _toInt(json['currentPage']),
      totalPages: _toInt(json['totalPages']),
      totalItems: _toInt(json['total_items']),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['currentPage'] = this.currentPage;
    data['totalPages'] = this.totalPages;
    data['total_items'] = this.totalItems;
    return data;
  }
}
