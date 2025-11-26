import SQLite from 'react-native-sqlite-storage';

// Enable promise mode
SQLite.enablePromise(true);

class DatabaseService {
  private db: SQLite.SQLiteDatabase | null = null;
  private initialized = false;

  async initialize(): Promise<void> {
    if (this.initialized && this.db) {
      return;
    }

    try {
      this.db = await SQLite.openDatabase({
        name: 'SkydiveTracker.db',
        location: 'default',
      });
      await this.createTables();
      this.initialized = true;
    } catch (error) {
      console.error('Database initialization error:', error);
      throw error;
    }
  }

  private async createTables(): Promise<void> {
    if (!this.db) {
      throw new Error('Database not initialized');
    }

    return new Promise<void>((resolve, reject) => {
      this.db!.transaction(tx => {
        // Profile table
        tx.executeSql(
          `CREATE TABLE IF NOT EXISTS profiles (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            license_number TEXT,
            license_type TEXT,
            total_jumps INTEGER DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          );`,
          [],
          () => {},
          (_, error) => {
            console.error('Error creating profiles table:', error);
            reject(error);
            return false;
          },
        );

        // Equipment table
        tx.executeSql(
          `CREATE TABLE IF NOT EXISTS equipment (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            manufacturer TEXT,
            model TEXT,
            serial_number TEXT,
            purchase_date TEXT,
            notes TEXT
          );`,
          [],
          () => {},
          (_, error) => {
            console.error('Error creating equipment table:', error);
            reject(error);
            return false;
          },
        );

        // Jumps table
        tx.executeSql(
          `CREATE TABLE IF NOT EXISTS jumps (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            location TEXT NOT NULL,
            altitude INTEGER NOT NULL,
            checklist_completed INTEGER DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL
          );`,
          [],
          () => {},
          (_, error) => {
            console.error('Error creating jumps table:', error);
            reject(error);
            return false;
          },
        );

        // Jump-Equipment junction table
        tx.executeSql(
          `CREATE TABLE IF NOT EXISTS jump_equipment (
            jump_id TEXT NOT NULL,
            equipment_id TEXT NOT NULL,
            PRIMARY KEY (jump_id, equipment_id)
          );`,
          [],
          () => {
            resolve();
          },
          (_, error) => {
            console.error('Error creating jump_equipment table:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  getDatabase(): SQLite.SQLiteDatabase {
    if (!this.db) {
      throw new Error('Database not initialized. Call initialize() first.');
    }
    return this.db;
  }

  async close(): Promise<void> {
    if (this.db) {
      await this.db.close();
      this.db = null;
      this.initialized = false;
    }
  }
}

export default new DatabaseService();
