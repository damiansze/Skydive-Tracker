import DatabaseService from '../database/DatabaseService';
import {Profile, ProfileUpdateInput} from '../../models/Profile';
import {v4 as uuidv4} from 'uuid';

class ProfileService {
  async getProfile(): Promise<Profile | null> {
    const db = DatabaseService.getDatabase();
    const [results] = await db.executeSql('SELECT * FROM profiles LIMIT 1');
    if (results.rows.length === 0) {
      return null;
    }
    return this.mapRowToProfile(results.rows.item(0));
  }

  async createOrUpdateProfile(
    input: ProfileUpdateInput & {name: string},
  ): Promise<Profile> {
    const db = DatabaseService.getDatabase();
    const existing = await this.getProfile();

    if (existing) {
      const now = new Date().toISOString();
      await db.executeSql(
        `UPDATE profiles 
         SET name = ?, license_number = ?, license_type = ?, updated_at = ?
         WHERE id = ?`,
        [
          input.name,
          input.licenseNumber || null,
          input.licenseType || null,
          now,
          existing.id,
        ],
      );
      return this.getProfile() as Promise<Profile>;
    } else {
      const id = uuidv4();
      const now = new Date().toISOString();
      await db.executeSql(
        `INSERT INTO profiles (id, name, license_number, license_type, total_jumps, created_at, updated_at)
         VALUES (?, ?, ?, ?, 0, ?, ?)`,
        [
          id,
          input.name,
          input.licenseNumber || null,
          input.licenseType || null,
          now,
          now,
        ],
      );
      return this.getProfile() as Promise<Profile>;
    }
  }

  private mapRowToProfile(row: any): Profile {
    return {
      id: row.id,
      name: row.name,
      licenseNumber: row.license_number || undefined,
      licenseType: row.license_type || undefined,
      totalJumps: row.total_jumps || 0,
      createdAt: new Date(row.created_at),
      updatedAt: new Date(row.updated_at),
    };
  }
}

export default new ProfileService();
