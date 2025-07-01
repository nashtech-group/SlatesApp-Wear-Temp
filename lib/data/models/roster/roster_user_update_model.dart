class RosterUserUpdateModel {
  final int id;
  final int? status;
  final bool? hasMovements;
  final bool? withinPerimeter;

  RosterUserUpdateModel({
    required this.id,
    this.status,
    this.hasMovements,
    this.withinPerimeter,
  });

  factory RosterUserUpdateModel.fromJson(Map<String, dynamic> json) {
    return RosterUserUpdateModel(
      id: json['id'] ?? 0,
      status: json['status'],
      hasMovements: json['hasMovements'],
      withinPerimeter: json['withinPerimeter'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'id': id};
    
    if (status != null) data['status'] = status;
    if (hasMovements != null) data['hasMovements'] = hasMovements;
    if (withinPerimeter != null) data['withinPerimeter'] = withinPerimeter;
    
    return data;
  }

  RosterUserUpdateModel copyWith({
    int? id,
    int? status,
    bool? hasMovements,
    bool? withinPerimeter,
  }) {
    return RosterUserUpdateModel(
      id: id ?? this.id,
      status: status ?? this.status,
      hasMovements: hasMovements ?? this.hasMovements,
      withinPerimeter: withinPerimeter ?? this.withinPerimeter,
    );
  }
}