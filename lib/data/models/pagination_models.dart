class PaginationLinksModel {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  PaginationLinksModel({
    this.first,
    this.last,
    this.prev,
    this.next,
  });

  factory PaginationLinksModel.fromJson(Map<String, dynamic> json) {
    return PaginationLinksModel(
      first: json['first'],
      last: json['last'],
      prev: json['prev'],
      next: json['next'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first': first,
      'last': last,
      'prev': prev,
      'next': next,
    };
  }
}

class PaginationMetaModel {
  final int currentPage;
  final int? from;
  final int lastPage;
  final List<PaginationLinkModel> links;
  final String path;
  final int perPage;
  final int? to;
  final int total;

  PaginationMetaModel({
    required this.currentPage,
    this.from,
    required this.lastPage,
    required this.links,
    required this.path,
    required this.perPage,
    this.to,
    required this.total,
  });

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      currentPage: json['current_page'] ?? 1,
      from: json['from'],
      lastPage: json['last_page'] ?? 1,
      links: (json['links'] as List<dynamic>?)
          ?.map((link) => PaginationLinkModel.fromJson(link))
          .toList() ?? [],
      path: json['path'] ?? '',
      perPage: json['per_page'] ?? 15,
      to: json['to'],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'from': from,
      'last_page': lastPage,
      'links': links.map((link) => link.toJson()).toList(),
      'path': path,
      'per_page': perPage,
      'to': to,
      'total': total,
    };
  }

  bool get hasMorePages => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

class PaginationLinkModel {
  final String? url;
  final String label;
  final bool active;

  PaginationLinkModel({
    this.url,
    required this.label,
    required this.active,
  });

  factory PaginationLinkModel.fromJson(Map<String, dynamic> json) {
    return PaginationLinkModel(
      url: json['url'],
      label: json['label'] ?? '',
      active: json['active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}