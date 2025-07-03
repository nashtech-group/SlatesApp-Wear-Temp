import 'package:slates_app_wear/data/models/contract/time_requirement_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';

class RosterUserModel {
  final int id;
  final int guardId;
  final TimeRequirementModel timeRequirement;
  final SiteModel site;
  final DateTime initialShiftDate;
  final DateTime startsAt;
  final DateTime endsAt;
  final int status;
  final int createdBy;
  final bool hasMovements;
  final bool withinPerimeter;
  final int? todaysPerimeterChecks;
  final int? todaysMovements;
  final String statusLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  RosterUserModel({
    required this.id,
    required this.guardId,
    required this.timeRequirement,
    required this.site,
    required this.initialShiftDate,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.createdBy,
    required this.hasMovements,
    required this.withinPerimeter,
    this.todaysPerimeterChecks,
    this.todaysMovements,
    required this.statusLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RosterUserModel.fromJson(Map<String, dynamic> json) {
    return RosterUserModel(
      id: json['id'] ?? 0,
      guardId: json['guardId'] ?? 0,
      timeRequirement: TimeRequirementModel.fromJson(json['timeRequirement'] ?? {}),
      site: SiteModel.fromJson(json['site'] ?? {}),
      initialShiftDate: DateTime.parse(json['initialShiftDate'] ?? DateTime.now().toIso8601String()),
      startsAt: DateTime.parse(json['startsAt'] ?? DateTime.now().toIso8601String()),
      endsAt: DateTime.parse(json['endsAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? -1,
      createdBy: json['createdBy'] ?? 0,
      hasMovements: json['hasMovements'] ?? false,
      withinPerimeter: json['withinPerimeter'] ?? false,
      todaysPerimeterChecks: json['todaysPerimeterChecks'],
      todaysMovements: json['todaysMovements'],
      statusLabel: json['statusLabel'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guardId': guardId,
      'timeRequirement': timeRequirement.toJson(),
      'site': site.toJson(),
      'initialShiftDate': initialShiftDate.toIso8601String(),
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'status': status,
      'createdBy': createdBy,
      'hasMovements': hasMovements,
      'withinPerimeter': withinPerimeter,
      'todaysPerimeterChecks': todaysPerimeterChecks,
      'todaysMovements': todaysMovements,
      'statusLabel': statusLabel,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper getters for status
  bool get isPresent => status == 1;
  bool get isAbsent => status == 0;
  bool get isPending => status == -1;
  bool get isPresentButLeftEarly => status == 2;
  bool get isExpired => status == -2;
  bool get isPresentButLate => status == 3;
  bool get isPresentButLateAndLeftEarly => status == 4;
  
  // Check if currently on duty
  bool get isCurrentlyOnDuty {
    final now = DateTime.now();
    return now.isAfter(startsAt) && now.isBefore(endsAt);
  }

  // Check if duty is upcoming
  bool get isDutyUpcoming {
    final now = DateTime.now();
    return now.isBefore(startsAt);
  }

  // Check if duty has ended
  bool get isDutyEnded {
    final now = DateTime.now();
    return now.isAfter(endsAt);
  }

  // Get status color for UI
  String get statusColor {
    switch (status) {
      case 1: return 'green'; // Present
      case 0: return 'red'; // Absent
      case -1: return 'orange'; // Pending
      case 2: return 'yellow'; // Present but left early
      case -2: return 'gray'; // Expired
      case 3: return 'blue'; // Present but late
      case 4: return 'purple'; // Present but late and left early
      default: return 'gray';
    }
  }

  RosterUserModel copyWith({
    int? id,
    int? guardId,
    TimeRequirementModel? timeRequirement,
    SiteModel? site,
    DateTime? initialShiftDate,
    DateTime? startsAt,
    DateTime? endsAt,
    int? status,
    int? createdBy,
    bool? hasMovements,
    bool? withinPerimeter,
    int? todaysPerimeterChecks,
    int? todaysMovements,
    String? statusLabel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RosterUserModel(
      id: id ?? this.id,
      guardId: guardId ?? this.guardId,
      timeRequirement: timeRequirement ?? this.timeRequirement,
      site: site ?? this.site,
      initialShiftDate: initialShiftDate ?? this.initialShiftDate,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      hasMovements: hasMovements ?? this.hasMovements,
      withinPerimeter: withinPerimeter ?? this.withinPerimeter,
      todaysPerimeterChecks: todaysPerimeterChecks ?? this.todaysPerimeterChecks,
      todaysMovements: todaysMovements ?? this.todaysMovements,
      statusLabel: statusLabel ?? this.statusLabel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
