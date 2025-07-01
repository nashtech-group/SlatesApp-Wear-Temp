import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_update_model.dart';
import 'package:slates_app_wear/data/models/site/perimeter_check_model.dart';

class ComprehensiveGuardDutyRequestModel {
  final List<RosterUserUpdateModel>? updates;
  final List<PerimeterCheckModel>? perimeterChecks;
  final List<GuardMovementModel>? movements;

  ComprehensiveGuardDutyRequestModel({
    this.updates,
    this.perimeterChecks,
    this.movements,
  });

  factory ComprehensiveGuardDutyRequestModel.fromJson(Map<String, dynamic> json) {
    return ComprehensiveGuardDutyRequestModel(
      updates: (json['updates'] as List<dynamic>?)
          ?.map((update) => RosterUserUpdateModel.fromJson(update))
          .toList(),
      perimeterChecks: (json['perimeterChecks'] as List<dynamic>?)
          ?.map((check) => PerimeterCheckModel.fromJson(check))
          .toList(),
      movements: (json['movements'] as List<dynamic>?)
          ?.map((movement) => GuardMovementModel.fromJson(movement))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    if (updates != null && updates!.isNotEmpty) {
      data['updates'] = updates!.map((update) => update.toJson()).toList();
    }
    
    if (perimeterChecks != null && perimeterChecks!.isNotEmpty) {
      data['perimeterChecks'] = perimeterChecks!.map((check) => check.toJson()).toList();
    }
    
    if (movements != null && movements!.isNotEmpty) {
      data['movements'] = movements!.map((movement) => movement.toJson()).toList();
    }
    
    return data;
  }

  bool get hasUpdates => updates != null && updates!.isNotEmpty;
  bool get hasPerimeterChecks => perimeterChecks != null && perimeterChecks!.isNotEmpty;
  bool get hasMovements => movements != null && movements!.isNotEmpty;
  bool get hasAnyData => hasUpdates || hasPerimeterChecks || hasMovements;

  ComprehensiveGuardDutyRequestModel copyWith({
    List<RosterUserUpdateModel>? updates,
    List<PerimeterCheckModel>? perimeterChecks,
    List<GuardMovementModel>? movements,
  }) {
    return ComprehensiveGuardDutyRequestModel(
      updates: updates ?? this.updates,
      perimeterChecks: perimeterChecks ?? this.perimeterChecks,
      movements: movements ?? this.movements,
    );
  }
}
