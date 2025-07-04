import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:slates_app_wear/data/models/contract/time_requirement_model.dart';
import 'package:slates_app_wear/data/models/pagination_models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/storage_constants.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance =
      OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static Database? _database;
  static const String _databaseName = 'slates_app_offline.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _rosterUsersTable = 'roster_users';
  static const String _guardMovementsTable = 'guard_movements';
  static const String _perimeterChecksTable = 'perimeter_checks';
  static const String _sitesTable = 'sites';
  static const String _pendingSubmissionsTable = 'pending_submissions';
  static const String _cacheMetadataTable = 'cache_metadata';
  static const String _syncStatusTable = 'sync_status';
  static const String _submissionRecordsTable = 'submission_records';

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Initialize SQLite database
  Future<Database> _initializeDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      log('Failed to initialize database: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    await db.transaction((txn) async {
      // Roster Users table
      await txn.execute('''
        CREATE TABLE $_rosterUsersTable (
          id INTEGER PRIMARY KEY,
          guard_id INTEGER NOT NULL,
          time_requirement_data TEXT NOT NULL,
          site_data TEXT NOT NULL,
          initial_shift_date TEXT NOT NULL,
          starts_at TEXT NOT NULL,
          ends_at TEXT NOT NULL,
          status INTEGER NOT NULL,
          created_by INTEGER NOT NULL,
          has_movements INTEGER NOT NULL DEFAULT 0,
          within_perimeter INTEGER NOT NULL DEFAULT 0,
          todays_perimeter_checks INTEGER,
          todays_movements INTEGER,
          status_label TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Guard Movements table
      await txn.execute('''
        CREATE TABLE $_guardMovementsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          roster_user_id INTEGER NOT NULL,
          guard_id INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          accuracy REAL,
          altitude REAL,
          heading REAL,
          speed REAL,
          timestamp TEXT NOT NULL,
          battery_level INTEGER,
          device_id TEXT,
          movement_type TEXT,
          checkpoint_proximity REAL,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0,
          local_id TEXT UNIQUE
        )
      ''');

      // Perimeter Checks table
      await txn.execute('''
        CREATE TABLE $_perimeterChecksTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pass_time TEXT NOT NULL,
          guard_id INTEGER NOT NULL,
          roster_user_id INTEGER NOT NULL,
          site_perimeter_id INTEGER NOT NULL,
          checkpoint_id INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          is_synced INTEGER NOT NULL DEFAULT 0,
          local_id TEXT UNIQUE
        )
      ''');

      // Sites table
      await txn.execute('''
        CREATE TABLE $_sitesTable (
          id INTEGER PRIMARY KEY,
          client_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          physical_address TEXT NOT NULL,
          city TEXT NOT NULL,
          country TEXT NOT NULL,
          status INTEGER NOT NULL,
          created_by_data TEXT NOT NULL,
          perimeters_data TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      // Pending Submissions table
      await txn.execute('''
        CREATE TABLE $_pendingSubmissionsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          submission_data TEXT NOT NULL,
          submission_type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_retry_at TEXT,
          local_id TEXT UNIQUE NOT NULL
        )
      ''');

      // Submission Records table (for caching successful submissions)
      await txn.execute('''
        CREATE TABLE $_submissionRecordsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          request_data TEXT NOT NULL,
          response_data TEXT NOT NULL,
          submission_type TEXT NOT NULL,
          created_at TEXT NOT NULL,
          local_id TEXT UNIQUE NOT NULL
        )
      ''');

      // Cache Metadata table
      await txn.execute('''
        CREATE TABLE $_cacheMetadataTable (
          cache_key TEXT PRIMARY KEY,
          cached_at TEXT NOT NULL,
          expires_at TEXT NOT NULL,
          guard_id INTEGER,
          data_type TEXT NOT NULL
        )
      ''');

      // Sync Status table
      await txn.execute('''
        CREATE TABLE $_syncStatusTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          guard_id INTEGER NOT NULL,
          last_sync_at TEXT NOT NULL,
          pending_movements INTEGER NOT NULL DEFAULT 0,
          pending_perimeter_checks INTEGER NOT NULL DEFAULT 0,
          pending_roster_updates INTEGER NOT NULL DEFAULT 0,
          sync_status TEXT NOT NULL DEFAULT 'pending'
        )
      ''');

      // Create indexes for better performance
      await _createIndexes(txn);
    });

    log('Database tables created successfully');
  }

  /// Create database indexes
  Future<void> _createIndexes(Transaction txn) async {
    // Roster Users indexes
    await txn.execute(
        'CREATE INDEX idx_roster_users_guard_id ON $_rosterUsersTable(guard_id)');
    await txn.execute(
        'CREATE INDEX idx_roster_users_starts_at ON $_rosterUsersTable(starts_at)');
    await txn.execute(
        'CREATE INDEX idx_roster_users_status ON $_rosterUsersTable(status)');

    // Guard Movements indexes
    await txn.execute(
        'CREATE INDEX idx_guard_movements_roster_user_id ON $_guardMovementsTable(roster_user_id)');
    await txn.execute(
        'CREATE INDEX idx_guard_movements_guard_id ON $_guardMovementsTable(guard_id)');
    await txn.execute(
        'CREATE INDEX idx_guard_movements_timestamp ON $_guardMovementsTable(timestamp)');
    await txn.execute(
        'CREATE INDEX idx_guard_movements_synced ON $_guardMovementsTable(is_synced)');

    // Perimeter Checks indexes
    await txn.execute(
        'CREATE INDEX idx_perimeter_checks_roster_user_id ON $_perimeterChecksTable(roster_user_id)');
    await txn.execute(
        'CREATE INDEX idx_perimeter_checks_guard_id ON $_perimeterChecksTable(guard_id)');
    await txn.execute(
        'CREATE INDEX idx_perimeter_checks_pass_time ON $_perimeterChecksTable(pass_time)');
    await txn.execute(
        'CREATE INDEX idx_perimeter_checks_synced ON $_perimeterChecksTable(is_synced)');

    // Pending Submissions indexes
    await txn.execute(
        'CREATE INDEX idx_pending_submissions_type ON $_pendingSubmissionsTable(submission_type)');
    await txn.execute(
        'CREATE INDEX idx_pending_submissions_created_at ON $_pendingSubmissionsTable(created_at)');

    // Submission Records indexes
    await txn.execute(
        'CREATE INDEX idx_submission_records_type ON $_submissionRecordsTable(submission_type)');
    await txn.execute(
        'CREATE INDEX idx_submission_records_created_at ON $_submissionRecordsTable(created_at)');

    // Cache Metadata indexes
    await txn.execute(
        'CREATE INDEX idx_cache_metadata_guard_id ON $_cacheMetadataTable(guard_id)');
    await txn.execute(
        'CREATE INDEX idx_cache_metadata_expires_at ON $_cacheMetadataTable(expires_at)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    log('Upgrading database from version $oldVersion to $newVersion');
  }

  // ====================
  // ROSTER DATA OPERATIONS
  // ====================

  /// Cache roster data for offline access
  Future<void> cacheRosterData(
      int guardId, RosterResponseModel rosterResponse) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final expiresAt = DateTime.now()
          .add(const Duration(hours: AppConstants.cacheExpirationHours))
          .toIso8601String();

      await db.transaction((txn) async {
        // Clear existing roster data for this guard
        await txn.delete(
          _rosterUsersTable,
          where: 'guard_id = ?',
          whereArgs: [guardId],
        );

        // Insert new roster data
        for (final rosterUser in rosterResponse.data) {
          await txn.insert(_rosterUsersTable, {
            'id': rosterUser.id,
            'guard_id': rosterUser.guardId,
            'time_requirement_data':
                jsonEncode(rosterUser.timeRequirement.toJson()),
            'site_data': jsonEncode(rosterUser.site.toJson()),
            'initial_shift_date': rosterUser.initialShiftDate.toIso8601String(),
            'starts_at': rosterUser.startsAt.toIso8601String(),
            'ends_at': rosterUser.endsAt.toIso8601String(),
            'status': rosterUser.status,
            'created_by': rosterUser.createdBy,
            'has_movements': rosterUser.hasMovements ? 1 : 0,
            'within_perimeter': rosterUser.withinPerimeter ? 1 : 0,
            'todays_perimeter_checks': rosterUser.todaysPerimeterChecks,
            'todays_movements': rosterUser.todaysMovements,
            'status_label': rosterUser.statusLabel,
            'created_at': rosterUser.createdAt.toIso8601String(),
            'updated_at': rosterUser.updatedAt.toIso8601String(),
            'cached_at': now,
          });

          // Cache site data separately
          await _cacheSiteData(txn, rosterUser.site, now);
        }

        // Update cache metadata
        await txn.insert(
          _cacheMetadataTable,
          {
            'cache_key':
                StorageConstants.getCacheKey('roster_data_guard_$guardId'),
            'cached_at': now,
            'expires_at': expiresAt,
            'guard_id': guardId,
            'data_type': 'roster_data',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      log('Roster data cached for guard $guardId');
    } catch (e) {
      log('Failed to cache roster data: $e');
      rethrow;
    }
  }

  /// Cache site data
  Future<void> _cacheSiteData(
      Transaction txn, SiteModel site, String cachedAt) async {
    await txn.insert(
      _sitesTable,
      {
        'id': site.id,
        'client_id': site.clientId,
        'name': site.name,
        'physical_address': site.physicalAddress,
        'city': site.city,
        'country': site.country,
        'status': site.status,
        'created_by_data': jsonEncode(site.createdBy.toJson()),
        'perimeters_data':
            jsonEncode(site.perimeters.map((p) => p.toJson()).toList()),
        'created_at': site.createdAt.toIso8601String(),
        'updated_at': site.updatedAt.toIso8601String(),
        'cached_at': cachedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached roster data
  Future<RosterResponseModel?> getCachedRosterData(int guardId) async {
    try {
      final db = await database;

      // Check if cache is still valid
      final cacheKey =
          StorageConstants.getCacheKey('roster_data_guard_$guardId');
      final cacheMetadata = await db.query(
        _cacheMetadataTable,
        where: 'cache_key = ?',
        whereArgs: [cacheKey],
      );

      if (cacheMetadata.isEmpty) {
        return null;
      }

      final expiresAt =
          DateTime.parse(cacheMetadata.first['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        log('Cached roster data expired for guard $guardId');
        await _clearExpiredCache();
        return null;
      }

      // Get roster data
      final rosterData = await db.query(
        _rosterUsersTable,
        where: 'guard_id = ?',
        whereArgs: [guardId],
        orderBy: 'starts_at ASC',
      );

      if (rosterData.isEmpty) {
        return null;
      }

      final rosterUsers = <RosterUserModel>[];
      for (final row in rosterData) {
        final rosterUser = _mapRowToRosterUser(row);
        rosterUsers.add(rosterUser);
      }

      // Create empty pagination data (since this is cached data)
      return RosterResponseModel(
        data: rosterUsers,
        links: PaginationLinksModel(),
        meta: PaginationMetaModel(
          currentPage: 1,
          lastPage: 1,
          links: [],
          path: '',
          perPage: rosterUsers.length,
          total: rosterUsers.length,
        ),
      );
    } catch (e) {
      log('Failed to get cached roster data: $e');
      return null;
    }
  }

  /// Map database row to RosterUser model
  RosterUserModel _mapRowToRosterUser(Map<String, dynamic> row) {
    return RosterUserModel(
      id: row['id'] as int,
      guardId: row['guard_id'] as int,
      timeRequirement: TimeRequirementModel.fromJson(
        jsonDecode(row['time_requirement_data'] as String),
      ),
      site: SiteModel.fromJson(
        jsonDecode(row['site_data'] as String),
      ),
      initialShiftDate: DateTime.parse(row['initial_shift_date'] as String),
      startsAt: DateTime.parse(row['starts_at'] as String),
      endsAt: DateTime.parse(row['ends_at'] as String),
      status: row['status'] as int,
      createdBy: row['created_by'] as int,
      hasMovements: (row['has_movements'] as int) == 1,
      withinPerimeter: (row['within_perimeter'] as int) == 1,
      todaysPerimeterChecks: row['todays_perimeter_checks'] as int?,
      todaysMovements: row['todays_movements'] as int?,
      statusLabel: row['status_label'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  // ====================
  // SUBMISSION RECORDS OPERATIONS
  // ====================

  /// Cache successful submission record
  Future<void> cacheSubmissionRecord(
    ComprehensiveGuardDutyRequestModel request,
    ComprehensiveGuardDutyResponseModel response,
  ) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final localId =
          'submission_record_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(_submissionRecordsTable, {
        'request_data': jsonEncode(request.toJson()),
        'response_data': jsonEncode(response.toJson()),
        'submission_type': 'comprehensive_guard_duty',
        'created_at': now,
        'local_id': localId,
      });

      log('Submission record cached: $localId');
    } catch (e) {
      log('Failed to cache submission record: $e');
      rethrow;
    }
  }

  /// Get submission records
  Future<List<Map<String, dynamic>>> getSubmissionRecords({
    int? limit,
    String? submissionType,
  }) async {
    try {
      final db = await database;

      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (submissionType != null) {
        whereClause = 'submission_type = ?';
        whereArgs.add(submissionType);
      }

      final records = await db.query(
        _submissionRecordsTable,
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
      );

      return records
          .map((row) => {
                'localId': row['local_id'] as String,
                'request': ComprehensiveGuardDutyRequestModel.fromJson(
                  jsonDecode(row['request_data'] as String),
                ),
                'response': ComprehensiveGuardDutyResponseModel.fromJson(
                  jsonDecode(row['response_data'] as String),
                ),
                'submissionType': row['submission_type'] as String,
                'createdAt': DateTime.parse(row['created_at'] as String),
              })
          .toList();
    } catch (e) {
      log('Failed to get submission records: $e');
      return [];
    }
  }

  // ====================
  // GUARD MOVEMENTS OPERATIONS
  // ====================

  /// Store guard movement locally
  Future<String> storeGuardMovement(GuardMovementModel movement) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final localId = 'movement_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(_guardMovementsTable, {
        'roster_user_id': movement.rosterUserId,
        'guard_id': movement.guardId,
        'latitude': movement.latitude,
        'longitude': movement.longitude,
        'accuracy': movement.accuracy,
        'altitude': movement.altitude,
        'heading': movement.heading,
        'speed': movement.speed,
        'timestamp': movement.timestamp.toIso8601String(),
        'battery_level': movement.batteryLevel,
        'device_id': movement.deviceId,
        'movement_type': movement.movementType,
        'checkpoint_proximity': movement.checkpointProximity,
        'notes': movement.notes,
        'created_at': now,
        'updated_at': now,
        'is_synced': 0,
        'local_id': localId,
      });

      log('Guard movement stored locally: $localId');
      return localId;
    } catch (e) {
      log('Failed to store guard movement: $e');
      rethrow;
    }
  }

  /// Get unsynced guard movements
  Future<List<GuardMovementModel>> getUnsyncedGuardMovements(
      {int? guardId, int? limit}) async {
    try {
      final db = await database;

      String whereClause = 'is_synced = 0';
      List<dynamic> whereArgs = [];

      if (guardId != null) {
        whereClause += ' AND guard_id = ?';
        whereArgs.add(guardId);
      }

      final movements = await db.query(
        _guardMovementsTable,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at ASC',
        limit: limit,
      );

      return movements.map((row) => _mapRowToGuardMovement(row)).toList();
    } catch (e) {
      log('Failed to get unsynced guard movements: $e');
      return [];
    }
  }

  /// Map database row to GuardMovement model
  GuardMovementModel _mapRowToGuardMovement(Map<String, dynamic> row) {
    return GuardMovementModel(
      id: row['id'] as int?,
      rosterUserId: row['roster_user_id'] as int,
      guardId: row['guard_id'] as int,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      accuracy: row['accuracy'] as double?,
      altitude: row['altitude'] as double?,
      heading: row['heading'] as double?,
      speed: row['speed'] as double?,
      timestamp: DateTime.parse(row['timestamp'] as String),
      batteryLevel: row['battery_level'] as int?,
      deviceId: row['device_id'] as String?,
      movementType: row['movement_type'] as String?,
      checkpointProximity: row['checkpoint_proximity'] as double?,
      notes: row['notes'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Mark guard movements as synced
  Future<void> markGuardMovementsAsSynced(List<String> localIds) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        for (final localId in localIds) {
          await txn.update(
            _guardMovementsTable,
            {'is_synced': 1, 'updated_at': now},
            where: 'local_id = ?',
            whereArgs: [localId],
          );
        }
      });

      log('Marked ${localIds.length} guard movements as synced');
    } catch (e) {
      log('Failed to mark guard movements as synced: $e');
    }
  }

  // ====================
  // PERIMETER CHECKS OPERATIONS
  // ====================

  /// Store perimeter check locally
  Future<String> storePerimeterCheck(PerimeterCheckModel perimeterCheck) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final localId = 'perimeter_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(_perimeterChecksTable, {
        'pass_time': perimeterCheck.passTime.toIso8601String(),
        'guard_id': perimeterCheck.guardId,
        'roster_user_id': perimeterCheck.rosterUserId,
        'site_perimeter_id': perimeterCheck.sitePerimeterId,
        'checkpoint_id': perimeterCheck.checkpointId,
        'created_at': now,
        'updated_at': now,
        'is_synced': 0,
        'local_id': localId,
      });

      log('Perimeter check stored locally: $localId');
      return localId;
    } catch (e) {
      log('Failed to store perimeter check: $e');
      rethrow;
    }
  }

  /// Get unsynced perimeter checks
  Future<List<PerimeterCheckModel>> getUnsyncedPerimeterChecks(
      {int? guardId, int? limit}) async {
    try {
      final db = await database;

      String whereClause = 'is_synced = 0';
      List<dynamic> whereArgs = [];

      if (guardId != null) {
        whereClause += ' AND guard_id = ?';
        whereArgs.add(guardId);
      }

      final checks = await db.query(
        _perimeterChecksTable,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at ASC',
        limit: limit,
      );

      return checks.map((row) => _mapRowToPerimeterCheck(row)).toList();
    } catch (e) {
      log('Failed to get unsynced perimeter checks: $e');
      return [];
    }
  }

  /// Map database row to PerimeterCheck model
  PerimeterCheckModel _mapRowToPerimeterCheck(Map<String, dynamic> row) {
    return PerimeterCheckModel(
      id: row['id'] as int?,
      passTime: DateTime.parse(row['pass_time'] as String),
      guardId: row['guard_id'] as int,
      rosterUserId: row['roster_user_id'] as int,
      sitePerimeterId: row['site_perimeter_id'] as int,
      checkpointId: row['checkpoint_id'] as int,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Mark perimeter checks as synced
  Future<void> markPerimeterChecksAsSynced(List<String> localIds) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        for (final localId in localIds) {
          await txn.update(
            _perimeterChecksTable,
            {'is_synced': 1, 'updated_at': now},
            where: 'local_id = ?',
            whereArgs: [localId],
          );
        }
      });

      log('Marked ${localIds.length} perimeter checks as synced');
    } catch (e) {
      log('Failed to mark perimeter checks as synced: $e');
    }
  }

  // ====================
  // PENDING SUBMISSIONS OPERATIONS
  // ====================

  /// Cache pending submission for later sync
  Future<void> cachePendingSubmission(
      ComprehensiveGuardDutyRequestModel submission) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      final localId = 'submission_${DateTime.now().millisecondsSinceEpoch}';

      await db.insert(_pendingSubmissionsTable, {
        'submission_data': jsonEncode(submission.toJson()),
        'submission_type': 'comprehensive_guard_duty',
        'created_at': now,
        'retry_count': 0,
        'local_id': localId,
      });

      log('Pending submission cached: $localId');
    } catch (e) {
      log('Failed to cache pending submission: $e');
      rethrow;
    }
  }

  /// Get all pending submissions
  Future<List<ComprehensiveGuardDutyRequestModel>>
      getPendingSubmissions() async {
    try {
      final db = await database;

      final submissions = await db.query(
        _pendingSubmissionsTable,
        orderBy: 'created_at ASC',
      );

      return submissions
          .map((row) => ComprehensiveGuardDutyRequestModel.fromJson(
                jsonDecode(row['submission_data'] as String),
              ))
          .toList();
    } catch (e) {
      log('Failed to get pending submissions: $e');
      return [];
    }
  }

  /// Remove a specific pending submission
  Future<void> removePendingSubmission(String localId) async {
    try {
      final db = await database;

      await db.delete(
        _pendingSubmissionsTable,
        where: 'local_id = ?',
        whereArgs: [localId],
      );

      log('Pending submission removed: $localId');
    } catch (e) {
      log('Failed to remove pending submission: $e');
    }
  }

  /// Clear all pending submissions
  Future<void> clearPendingSubmissions() async {
    try {
      final db = await database;
      await db.delete(_pendingSubmissionsTable);
      log('All pending submissions cleared');
    } catch (e) {
      log('Failed to clear pending submissions: $e');
    }
  }

  /// Get count of pending submissions
  Future<int> getPendingSubmissionsCount() async {
    try {
      final db = await database;
      final result =
          await db.rawQuery('SELECT COUNT(*) FROM $_pendingSubmissionsTable');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      log('Failed to get pending submissions count: $e');
      return 0;
    }
  }

  /// Update retry count for a pending submission
  Future<void> updateSubmissionRetryCount(
      String localId, int retryCount) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      await db.update(
        _pendingSubmissionsTable,
        {
          'retry_count': retryCount,
          'last_retry_at': now,
        },
        where: 'local_id = ?',
        whereArgs: [localId],
      );

      log('Updated retry count for submission $localId: $retryCount');
    } catch (e) {
      log('Failed to update retry count: $e');
    }
  }

  // ====================
  // SYNC STATUS OPERATIONS
  // ====================

  /// Update sync status for a guard
  Future<void> updateSyncStatus({
    required int guardId,
    required DateTime lastSyncAt,
    int pendingMovements = 0,
    int pendingPerimeterChecks = 0,
    int pendingRosterUpdates = 0,
    String syncStatus = 'completed',
  }) async {
    try {
      final db = await database;

      await db.insert(
        _syncStatusTable,
        {
          'guard_id': guardId,
          'last_sync_at': lastSyncAt.toIso8601String(),
          'pending_movements': pendingMovements,
          'pending_perimeter_checks': pendingPerimeterChecks,
          'pending_roster_updates': pendingRosterUpdates,
          'sync_status': syncStatus,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      log('Sync status updated for guard $guardId');
    } catch (e) {
      log('Failed to update sync status: $e');
    }
  }

  /// Get sync status for a guard
  Future<Map<String, dynamic>?> getSyncStatus(int guardId) async {
    try {
      final db = await database;

      final result = await db.query(
        _syncStatusTable,
        where: 'guard_id = ?',
        whereArgs: [guardId],
        orderBy: 'last_sync_at DESC',
        limit: 1,
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'guardId': row['guard_id'] as int,
        'lastSyncAt': DateTime.parse(row['last_sync_at'] as String),
        'pendingMovements': row['pending_movements'] as int,
        'pendingPerimeterChecks': row['pending_perimeter_checks'] as int,
        'pendingRosterUpdates': row['pending_roster_updates'] as int,
        'syncStatus': row['sync_status'] as String,
      };
    } catch (e) {
      log('Failed to get sync status: $e');
      return null;
    }
  }

  // ====================
  // CACHE MANAGEMENT
  // ====================

  /// Clear expired cache entries
  Future<void> _clearExpiredCache() async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      // Get expired cache keys
      final expiredCache = await db.query(
        _cacheMetadataTable,
        where: 'expires_at < ?',
        whereArgs: [now],
      );

      await db.transaction((txn) async {
        for (final cache in expiredCache) {
          final cacheKey = cache['cache_key'] as String;
          final dataType = cache['data_type'] as String;
          final guardId = cache['guard_id'] as int?;

          // Clear specific cache data
          if (dataType == 'roster_data' && guardId != null) {
            await txn.delete(
              _rosterUsersTable,
              where: 'guard_id = ?',
              whereArgs: [guardId],
            );
          }

          // Remove cache metadata
          await txn.delete(
            _cacheMetadataTable,
            where: 'cache_key = ?',
            whereArgs: [cacheKey],
          );
        }
      });

      log('Cleared ${expiredCache.length} expired cache entries');
    } catch (e) {
      log('Failed to clear expired cache: $e');
    }
  }

  /// Clear all cache data
  Future<void> clearAllCache() async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete(_rosterUsersTable);
        await txn.delete(_sitesTable);
        await txn.delete(_cacheMetadataTable);
      });

      log('All cache data cleared');
    } catch (e) {
      log('Failed to clear all cache: $e');
    }
  }

  /// Clear roster cache only
  Future<void> clearRosterCache() async {
    try {
      final db = await database;

      await db.transaction((txn) async {
        await txn.delete(_rosterUsersTable);
        await txn.delete(
          _cacheMetadataTable,
          where: 'data_type = ?',
          whereArgs: ['roster_data'],
        );
      });

      log('Roster cache cleared');
    } catch (e) {
      log('Failed to clear roster cache: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStatistics() async {
    try {
      final db = await database;

      final stats = <String, int>{};

      // Count roster users
      final rosterCount =
          await db.rawQuery('SELECT COUNT(*) FROM $_rosterUsersTable');
      stats['rosterUsers'] = Sqflite.firstIntValue(rosterCount) ?? 0;

      // Count guard movements
      final movementsCount =
          await db.rawQuery('SELECT COUNT(*) FROM $_guardMovementsTable');
      stats['guardMovements'] = Sqflite.firstIntValue(movementsCount) ?? 0;

      // Count unsynced movements
      final unsyncedMovements = await db.rawQuery(
          'SELECT COUNT(*) FROM $_guardMovementsTable WHERE is_synced = 0');
      stats['unsyncedMovements'] =
          Sqflite.firstIntValue(unsyncedMovements) ?? 0;

      // Count perimeter checks
      final checksCount =
          await db.rawQuery('SELECT COUNT(*) FROM $_perimeterChecksTable');
      stats['perimeterChecks'] = Sqflite.firstIntValue(checksCount) ?? 0;

      // Count unsynced checks
      final unsyncedChecks = await db.rawQuery(
          'SELECT COUNT(*) FROM $_perimeterChecksTable WHERE is_synced = 0');
      stats['unsyncedPerimeterChecks'] =
          Sqflite.firstIntValue(unsyncedChecks) ?? 0;

      // Count pending submissions
      final pendingSubmissions =
          await db.rawQuery('SELECT COUNT(*) FROM $_pendingSubmissionsTable');
      stats['pendingSubmissions'] =
          Sqflite.firstIntValue(pendingSubmissions) ?? 0;

      // Count cached sites
      final sitesCount = await db.rawQuery('SELECT COUNT(*) FROM $_sitesTable');
      stats['cachedSites'] = Sqflite.firstIntValue(sitesCount) ?? 0;

      // Count submission records
      final recordsCount =
          await db.rawQuery('SELECT COUNT(*) FROM $_submissionRecordsTable');
      stats['submissionRecords'] = Sqflite.firstIntValue(recordsCount) ?? 0;

      return stats;
    } catch (e) {
      log('Failed to get storage statistics: $e');
      return {};
    }
  }

  /// Clean old data based on retention policies
  Future<void> cleanOldData() async {
    try {
      final db = await database;

      // Clean old movements (keep data for specified days)
      final movementRetentionDate = DateTime.now()
          .subtract(
              const Duration(days: AppConstants.movementDataRetentionDays))
          .toIso8601String();

      await db.delete(
        _guardMovementsTable,
        where: 'created_at < ? AND is_synced = 1',
        whereArgs: [movementRetentionDate],
      );

      // Clean old perimeter checks
      await db.delete(
        _perimeterChecksTable,
        where: 'created_at < ? AND is_synced = 1',
        whereArgs: [movementRetentionDate],
      );

      // Clean old pending submissions (remove very old failed submissions)
      final submissionRetentionDate =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

      await db.delete(
        _pendingSubmissionsTable,
        where: 'created_at < ? AND retry_count > ?',
        whereArgs: [submissionRetentionDate, AppConstants.maxRetryAttempts],
      );

      // Clean old submission records
      final recordRetentionDate =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

      await db.delete(
        _submissionRecordsTable,
        where: 'created_at < ?',
        whereArgs: [recordRetentionDate],
      );

      // Clear expired cache
      await _clearExpiredCache();

      log('Old data cleanup completed');
    } catch (e) {
      log('Failed to clean old data: $e');
    }
  }

  /// Clear all submission records (sync history)
  Future<void> clearSubmissionRecords({String? submissionType}) async {
    try {
      final db = await database;

      if (submissionType != null) {
        // Clear specific submission type
        await db.delete(
          _submissionRecordsTable,
          where: 'submission_type = ?',
          whereArgs: [submissionType],
        );
        log('Submission records cleared for type: $submissionType');
      } else {
        // Clear all submission records
        await db.delete(_submissionRecordsTable);
        log('All submission records cleared');
      }
    } catch (e) {
      log('Failed to clear submission records: $e');
      rethrow;
    }
  }

  /// Clear both pending submissions and submission records (complete sync history cleanup)
  Future<Map<String, int>> clearAllSyncData() async {
    try {
      final db = await database;

      // Get counts before clearing
      final pendingCount = await getPendingSubmissionsCount();
      final recordsResult =
          await db.rawQuery('SELECT COUNT(*) FROM $_submissionRecordsTable');
      final recordsCount = Sqflite.firstIntValue(recordsResult) ?? 0;

      await db.transaction((txn) async {
        // Clear pending submissions
        await txn.delete(_pendingSubmissionsTable);

        // Clear submission records
        await txn.delete(_submissionRecordsTable);

        // Clear sync status (optional - resets sync tracking)
        await txn.delete(_syncStatusTable);
      });

      final result = {
        'pendingSubmissions': pendingCount,
        'submissionRecords': recordsCount,
        'totalCleared': pendingCount + recordsCount,
      };

      log('All sync data cleared: ${result.toString()}');
      return result;
    } catch (e) {
      log('Failed to clear all sync data: $e');
      rethrow;
    }
  }

  /// Get submission records count
  Future<int> getSubmissionRecordsCount({String? submissionType}) async {
    try {
      final db = await database;

      String query = 'SELECT COUNT(*) FROM $_submissionRecordsTable';
      List<dynamic> args = [];

      if (submissionType != null) {
        query += ' WHERE submission_type = ?';
        args.add(submissionType);
      }

      final result = await db.rawQuery(query, args.isNotEmpty ? args : null);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      log('Failed to get submission records count: $e');
      return 0;
    }
  }

  /// Clean old submission records based on retention policy
  Future<int> cleanOldSubmissionRecords({int retentionDays = 30}) async {
    try {
      final db = await database;
      final retentionDate = DateTime.now()
          .subtract(Duration(days: retentionDays))
          .toIso8601String();

      final deletedCount = await db.delete(
        _submissionRecordsTable,
        where: 'created_at < ?',
        whereArgs: [retentionDate],
      );

      log('Cleaned $deletedCount old submission records (older than $retentionDays days)');
      return deletedCount;
    } catch (e) {
      log('Failed to clean old submission records: $e');
      return 0;
    }
  }

  /// Get comprehensive storage usage statistics
  Future<Map<String, dynamic>> getComprehensiveStorageStats() async {
    try {
      final basicStats = await getStorageStatistics();

      // Add additional statistics
      final db = await database;

      // Database file size (approximate)
      final databasePath = db.path;
      int? databaseSize;
      try {
        final file = File(databasePath);
        if (await file.exists()) {
          databaseSize = await file.length();
        }
      } catch (e) {
        log('Could not get database file size: $e');
      }

      // Cache metadata count
      final cacheMetadataResult =
          await db.rawQuery('SELECT COUNT(*) FROM $_cacheMetadataTable');
      final cacheMetadataCount =
          Sqflite.firstIntValue(cacheMetadataResult) ?? 0;

      // Sync status records count
      final syncStatusResult =
          await db.rawQuery('SELECT COUNT(*) FROM $_syncStatusTable');
      final syncStatusCount = Sqflite.firstIntValue(syncStatusResult) ?? 0;

      return {
        ...basicStats,
        'cacheMetadataEntries': cacheMetadataCount,
        'syncStatusRecords': syncStatusCount,
        'databaseSizeBytes': databaseSize,
        'databaseSizeMB': databaseSize != null
            ? (databaseSize / (1024 * 1024)).toStringAsFixed(2)
            : 'Unknown',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Failed to get comprehensive storage stats: $e');
      return await getStorageStatistics(); // Fallback to basic stats
    }
  }

  /// Export sync data for debugging/support purposes
  Future<Map<String, dynamic>> exportSyncDataForDebug() async {
    try {
      final db = await database;

      // Get recent submission records (last 10)
      final recentSubmissions = await getSubmissionRecords(
        limit: 10,
        submissionType: 'comprehensive_guard_duty',
      );

      // Get pending submissions count and details (without sensitive data)
      final pendingCount = await getPendingSubmissionsCount();
      final pendingDetails = await db.query(
        _pendingSubmissionsTable,
        columns: [
          'submission_type',
          'created_at',
          'retry_count',
          'last_retry_at'
        ],
        orderBy: 'created_at DESC',
        limit: 5,
      );

      // Get sync status for all guards
      final syncStatuses = await db.query(
        _syncStatusTable,
        orderBy: 'last_sync_at DESC',
      );

      // Get storage statistics
      final storageStats = await getComprehensiveStorageStats();

      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'recentSubmissions': recentSubmissions
            .map((record) => {
                  'submissionType': record['submissionType'],
                  'createdAt': record['createdAt']?.toIso8601String(),
                  'success': true, // These are successful submissions
                })
            .toList(),
        'pendingSubmissions': {
          'count': pendingCount,
          'details': pendingDetails
              .map((pending) => {
                    'type': pending['submission_type'],
                    'createdAt': pending['created_at'],
                    'retryCount': pending['retry_count'],
                    'lastRetryAt': pending['last_retry_at'],
                  })
              .toList(),
        },
        'syncStatuses': syncStatuses
            .map((status) => {
                  'guardId': status['guard_id'],
                  'lastSyncAt': status['last_sync_at'],
                  'pendingMovements': status['pending_movements'],
                  'pendingPerimeterChecks': status['pending_perimeter_checks'],
                  'pendingRosterUpdates': status['pending_roster_updates'],
                  'syncStatus': status['sync_status'],
                })
            .toList(),
        'storageStatistics': storageStats,
      };
    } catch (e) {
      log('Failed to export sync data for debug: $e');
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      log('Database closed');
    }
  }

  /// Delete database (for testing/reset purposes)
  Future<void> deleteDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      await close();
      await databaseFactory.deleteDatabase(path);

      log('Database deleted');
    } catch (e) {
      log('Failed to delete database: $e');
    }
  }
}
