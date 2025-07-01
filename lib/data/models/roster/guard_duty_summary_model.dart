class GuardDutySummaryModel {
  final int rosterUsersUpdated;
  final int perimeterChecksCreated;
  final int movementsRecorded;

  GuardDutySummaryModel({
    required this.rosterUsersUpdated,
    required this.perimeterChecksCreated,
    required this.movementsRecorded,
  });

  factory GuardDutySummaryModel.fromJson(Map<String, dynamic> json) {
    return GuardDutySummaryModel(
      rosterUsersUpdated: json['rosterUsersUpdated'] ?? 0,
      perimeterChecksCreated: json['perimeterChecksCreated'] ?? 0,
      movementsRecorded: json['movementsRecorded'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rosterUsersUpdated': rosterUsersUpdated,
      'perimeterChecksCreated': perimeterChecksCreated,
      'movementsRecorded': movementsRecorded,
    };
  }

  int get totalOperations => rosterUsersUpdated + perimeterChecksCreated + movementsRecorded;

  GuardDutySummaryModel copyWith({
    int? rosterUsersUpdated,
    int? perimeterChecksCreated,
    int? movementsRecorded,
  }) {
    return GuardDutySummaryModel(
      rosterUsersUpdated: rosterUsersUpdated ?? this.rosterUsersUpdated,
      perimeterChecksCreated: perimeterChecksCreated ?? this.perimeterChecksCreated,
      movementsRecorded: movementsRecorded ?? this.movementsRecorded,
    );
  }
}