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
        notes TEXT
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

    // Indexes
    await db.execute('CREATE INDEX idx_jumps_date ON jumps(date DESC)');
    await db.execute('CREATE INDEX idx_jumps_location ON jumps(location)');
  }

  // Profile methods
  Future<void> insertProfile(Profile profile) async {
    final db = await database;
    await db.insert('profiles', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Profile?> getProfile() async {
    final db = await database;
    final maps = await db.query('profiles', limit: 1);
    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update('profiles', profile.toMap(),
        where: 'id = ?', whereArgs: [profile.id]);
  }

  // Equipment methods
  Future<String> insertEquipment(Equipment equipment) async {
    final db = await database;
    await db.insert('equipment', equipment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return equipment.id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    final db = await database;
    final maps = await db.query('equipment', orderBy: 'name ASC');
    return maps.map((map) => Equipment.fromMap(map)).toList();
  }

  Future<Equipment?> getEquipmentById(String id) async {
    final db = await database;
    final maps = await db.query('equipment', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Equipment.fromMap(maps.first);
  }

  Future<void> updateEquipment(Equipment equipment) async {
    final db = await database;
    await db.update('equipment', equipment.toMap(),
        where: 'id = ?', whereArgs: [equipment.id]);
  }

  Future<void> deleteEquipment(String id) async {
    final db = await database;
    await db.delete('equipment', where: 'id = ?', whereArgs: [id]);
  }

  // Jump methods
  Future<String> insertJump(Jump jump) async {
    final db = await database;
    await db.insert('jumps', jump.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    
    // Insert equipment associations
    for (String equipmentId in jump.equipmentIds) {
      await db.insert('jump_equipment', {
        'jump_id': jump.id,
        'equipment_id': equipmentId,
      });
    }
    
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
    
    List<Jump> jumps = maps.map((map) => Jump.fromMap(map)).toList();
    
    // Load equipment IDs for each jump
    for (int i = 0; i < jumps.length; i++) {
      final equipmentMaps = await db.query(
        'jump_equipment',
        where: 'jump_id = ?',
        whereArgs: [jumps[i].id],
      );
      jumps[i] = jumps[i].copyWith(
        equipmentIds: equipmentMaps.map((e) => e['equipment_id'] as String).toList(),
      );
    }
    
    return jumps;
  }

  Future<Jump?> getJumpById(String id) async {
    final db = await database;
    final maps = await db.query('jumps', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    
    Jump jump = Jump.fromMap(maps.first);
    
    // Load equipment IDs
    final equipmentMaps = await db.query(
      'jump_equipment',
      where: 'jump_id = ?',
      whereArgs: [id],
    );
    jump = jump.copyWith(
      equipmentIds: equipmentMaps.map((e) => e['equipment_id'] as String).toList(),
    );
    
    return jump;
  }

  Future<void> updateJump(Jump jump) async {
    final db = await database;
    await db.update('jumps', jump.toMap(),
        where: 'id = ?', whereArgs: [jump.id]);
    
    // Update equipment associations
    await db.delete('jump_equipment', where: 'jump_id = ?', whereArgs: [jump.id]);
    for (String equipmentId in jump.equipmentIds) {
      await db.insert('jump_equipment', {
        'jump_id': jump.id,
        'equipment_id': equipmentId,
      });
    }
  }

  Future<void> deleteJump(String id) async {
    final db = await database;
    await db.delete('jump_equipment', where: 'jump_id = ?', whereArgs: [id]);
    await db.delete('jumps', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getTotalJumps({String? locationFilter}) async {
    final db = await database;
    if (locationFilter != null && locationFilter.isNotEmpty) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM jumps WHERE location LIKE ?',
        ['%$locationFilter%'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } else {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM jumps');
      return Sqflite.firstIntValue(result) ?? 0;
    }
  }

  Future<List<String>> getDistinctLocations() async {
    final db = await database;
    final maps = await db.rawQuery('SELECT DISTINCT location FROM jumps ORDER BY location');
    return maps.map((map) => map['location'] as String).toList();
  }
}
