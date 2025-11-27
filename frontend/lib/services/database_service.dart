import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/jump.dart';
import '../models/equipment.dart';
import '../models/profile.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'skydive_tracker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Profile table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        license_number TEXT,
        license_type TEXT,
        total_jumps INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Equipment table
    await db.execute('''
      CREATE TABLE equipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        manufacturer TEXT,
        model TEXT,
        serial_number TEXT,
        purchase_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Jumps table
    await db.execute('''
      CREATE TABLE jumps (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        altitude INTEGER NOT NULL,
        checklist_completed INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Jump-Equipment association table
    await db.execute('''
      CREATE TABLE jump_equipment (
        jump_id TEXT NOT NULL,
        equipment_id TEXT NOT NULL,
        PRIMARY KEY (jump_id, equipment_id),
        FOREIGN KEY (jump_id) REFERENCES jumps(id) ON DELETE CASCADE,
        FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for better performance
    await db.execute('CREATE INDEX idx_jumps_date ON jumps(date DESC)');
    await db.execute('CREATE INDEX idx_jumps_location ON jumps(location)');
    await db.execute('CREATE INDEX idx_jump_equipment_jump_id ON jump_equipment(jump_id)');
    await db.execute('CREATE INDEX idx_jump_equipment_equipment_id ON jump_equipment(equipment_id)');
  }

  // Profile methods
  Future<void> insertProfile(Profile profile) async {
    final db = await database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Profile?> getProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('profiles', limit: 1);
    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  // Equipment methods
  Future<String> insertEquipment(Equipment equipment) async {
    final db = await database;
    final equipmentMap = equipment.toMap();
    equipmentMap['created_at'] = DateTime.now().toIso8601String();
    await db.insert(
      'equipment',
      equipmentMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return equipment.id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('equipment');
    return List.generate(maps.length, (i) => Equipment.fromMap(maps[i]));
  }

  Future<Equipment?> getEquipmentById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'equipment',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Equipment.fromMap(maps.first);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    final db = await database;
    await db.update(
      'equipment',
      equipment.toMap(),
      where: 'id = ?',
      whereArgs: [equipment.id],
    );
  }

  Future<void> deleteEquipment(String id) async {
    final db = await database;
    await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
    // Cascade delete will handle jump_equipment associations
  }

  // Jump methods
  Future<String> insertJump(Jump jump) async {
    final db = await database;
    await db.transaction((txn) async {
      // Insert jump
      await txn.insert(
        'jumps',
        jump.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert equipment associations
      if (jump.equipmentIds.isNotEmpty) {
        final batch = txn.batch();
        for (final equipmentId in jump.equipmentIds) {
          batch.insert('jump_equipment', {
            'jump_id': jump.id,
            'equipment_id': equipmentId,
          });
        }
        await batch.commit(noResult: true);
      }
    });
    return jump.id;
  }

  Future<List<Jump>> getAllJumps({String? locationFilter}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    
    if (locationFilter != null && locationFilter.isNotEmpty) {
      maps = await db.query(
        'jumps',
        where: 'location LIKE ?',
        whereArgs: ['%$locationFilter%'],
        orderBy: 'date DESC',
      );
    } else {
      maps = await db.query('jumps', orderBy: 'date DESC');
    }

    final jumps = <Jump>[];
    for (final map in maps) {
      final jump = Jump.fromMap(map);
      // Load equipment IDs
      final equipmentMaps = await db.query(
        'jump_equipment',
        where: 'jump_id = ?',
        whereArgs: [jump.id],
      );
      final equipmentIds = equipmentMaps
          .map((e) => e['equipment_id'] as String)
          .toList();
      jumps.add(jump.copyWith(equipmentIds: equipmentIds));
    }
    
    return jumps;
  }

  Future<Jump?> getJumpById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'jumps',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final jump = Jump.fromMap(maps.first);
    // Load equipment IDs
    final equipmentMaps = await db.query(
      'jump_equipment',
      where: 'jump_id = ?',
      whereArgs: [id],
    );
    final equipmentIds = equipmentMaps
        .map((e) => e['equipment_id'] as String)
        .toList();
    
    return jump.copyWith(equipmentIds: equipmentIds);
  }

  Future<void> updateJump(Jump jump) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update jump
      await txn.update(
        'jumps',
        jump.toMap(),
        where: 'id = ?',
        whereArgs: [jump.id],
      );

      // Delete old equipment associations
      await txn.delete(
        'jump_equipment',
        where: 'jump_id = ?',
        whereArgs: [jump.id],
      );

      // Insert new equipment associations
      if (jump.equipmentIds.isNotEmpty) {
        final batch = txn.batch();
        for (final equipmentId in jump.equipmentIds) {
          batch.insert('jump_equipment', {
            'jump_id': jump.id,
            'equipment_id': equipmentId,
          });
        }
        await batch.commit(noResult: true);
      }
    });
  }

  Future<void> deleteJump(String id) async {
    final db = await database;
    await db.delete('jumps', where: 'id = ?', whereArgs: [id]);
    // Cascade delete will handle jump_equipment associations
  }

  Future<int> getTotalJumps({String? locationFilter}) async {
    final db = await database;
    if (locationFilter != null && locationFilter.isNotEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM jumps WHERE location LIKE ?',
        ['%$locationFilter%'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM jumps');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getDistinctLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT location FROM jumps ORDER BY location',
    );
    return maps.map((m) => m['location'] as String).toList();
  }
}
