class PageResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final int currentPageNumberOfElements;
  final bool last;

  PageResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.currentPageNumberOfElements,
    required this.last,
  });

  factory PageResponse.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PageResponse(
      content: (json['content'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      currentPageNumberOfElements: json['currentPageNumberOfElements'],
      last: json['last'],
    );
  }
}