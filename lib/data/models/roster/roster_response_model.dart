import 'package:slates_app_wear/data/models/pagination_models.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';

class RosterResponseModel {
  final List<RosterUserModel> data;
  final PaginationLinksModel links;
  final PaginationMetaModel meta;

  RosterResponseModel({
    required this.data,
    required this.links,
    required this.meta,
  });

  factory RosterResponseModel.fromJson(Map<String, dynamic> json) {
    return RosterResponseModel(
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => RosterUserModel.fromJson(item))
          .toList() ?? [],
      links: PaginationLinksModel.fromJson(json['links'] ?? {}),
      meta: PaginationMetaModel.fromJson(json['meta'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((item) => item.toJson()).toList(),
      'links': links.toJson(),
      'meta': meta.toJson(),
    };
  }

  bool get hasData => data.isNotEmpty;
  int get totalItems => meta.total;

  RosterResponseModel copyWith({
    List<RosterUserModel>? data,
    PaginationLinksModel? links,
    PaginationMetaModel? meta,
  }) {
    return RosterResponseModel(
      data: data ?? this.data,
      links: links ?? this.links,
      meta: meta ?? this.meta,
    );
  }
}

