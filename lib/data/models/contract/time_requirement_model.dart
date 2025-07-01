import 'package:slates_app_wear/data/models/contract/contract_guard_requirement_model.dart';
import 'package:slates_app_wear/data/models/contract/contract_model.dart';
import 'package:slates_app_wear/data/models/guard/guard_position_model.dart';

class TimeRequirementModel {
  final int id;
  final String dayOfTheWeek;
  final ContractModel contract;
  final GuardPositionModel guardPosition;
  final ContractGuardRequirementModel contractGuardRequirement;
  final String startTime;
  final String endTime;

  TimeRequirementModel({
    required this.id,
    required this.dayOfTheWeek,
    required this.contract,
    required this.guardPosition,
    required this.contractGuardRequirement,
    required this.startTime,
    required this.endTime,
  });

  factory TimeRequirementModel.fromJson(Map<String, dynamic> json) {
    return TimeRequirementModel(
      id: json['id'] ?? 0,
      dayOfTheWeek: json['dayOfTheWeek'] ?? '',
      contract: ContractModel.fromJson(json['contract'] ?? {}),
      guardPosition: GuardPositionModel.fromJson(json['guardPosition'] ?? {}),
      contractGuardRequirement: ContractGuardRequirementModel.fromJson(json['contractGuardRequirement'] ?? {}),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dayOfTheWeek': dayOfTheWeek,
      'contract': contract.toJson(),
      'guardPosition': guardPosition.toJson(),
      'contractGuardRequirement': contractGuardRequirement.toJson(),
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  // Helper to get shift duration
  Duration get shiftDuration {
    final start = DateTime.parse('2000-01-01 $startTime');
    final end = DateTime.parse('2000-01-01 $endTime');
    return end.difference(start);
  }

  String get formattedShiftTime => '$startTime - $endTime';

  TimeRequirementModel copyWith({
    int? id,
    String? dayOfTheWeek,
    ContractModel? contract,
    GuardPositionModel? guardPosition,
    ContractGuardRequirementModel? contractGuardRequirement,
    String? startTime,
    String? endTime,
  }) {
    return TimeRequirementModel(
      id: id ?? this.id,
      dayOfTheWeek: dayOfTheWeek ?? this.dayOfTheWeek,
      contract: contract ?? this.contract,
      guardPosition: guardPosition ?? this.guardPosition,
      contractGuardRequirement: contractGuardRequirement ?? this.contractGuardRequirement,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}