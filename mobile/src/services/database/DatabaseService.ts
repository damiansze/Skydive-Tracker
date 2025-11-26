import SQLite from 'react-native-sqlite-storage';

SQLite.DEBUG(true);
SQLite.enablePromise(true);

class DatabaseService {
  private db: SQLite.SQLiteDatabase | null = null;

  async initialize(): Promise<void> {
    try {
      this.db = await SQLite.openDatabase({
        name: 'SkydiveTracker.db',
        location: 'default',
      });
      await this.createTables();
    } catch (error) {
      console.error('Database initialization error:', error);
      throw error;
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) {
      throw new Error('Database not initialized');
    }

    // Profile table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        license_number TEXT,
        license_type TEXT,
        total_jumps INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    `);

    // Equipment table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS equipment (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        manufacturer TEXT,
        model TEXT,
        serial_number TEXT,
        purchase_date TEXT,
        notes TEXT
      );
    `);

    // Jumps table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS jumps (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        altitude INTEGER NOT NULL,
        checklist_completed INTEGER DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      );
    `);

    // Jump-Equipment junction table
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS jump_equipment (
        jump_id TEXT NOT NULL,
        equipment_id TEXT NOT NULL,
        PRIMARY KEY (jump_id, equipment_id),
        FOREIGN KEY (jump_id) REFERENCES jumps(id) ON DELETE CASCADE,
        FOREIGN KEY (equipment_id) REFERENCES equipment(id) ON DELETE CASCADE
      );
    `);
  }

  getDatabase(): SQLite.SQLiteDatabase {
    if (!this.db) {
      throw new Error('Database not initialized');
    }
    return this.db;
  }

  async close(): Promise<void> {
    if (this.db) {
      await this.db.close();
      this.db = null;
    }
  }
}

export default new DatabaseService();
