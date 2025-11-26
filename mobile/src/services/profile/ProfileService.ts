import DatabaseService from '../database/DatabaseService';
import {Profile, ProfileUpdateInput} from '../../models/Profile';
import {v4 as uuidv4} from 'uuid';

class ProfileService {
  async getProfile(): Promise<Profile | null> {
    const db = DatabaseService.getDatabase();
    return new Promise<Profile | null>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM profiles LIMIT 1',
          [],
          (_, results) => {
            if (results.rows.length === 0) {
              resolve(null);
              return;
            }
            resolve(this.mapRowToProfile(results.rows.item(0)));
          },
          (_, error) => {
            console.error('Error getting profile:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async createOrUpdateProfile(
    input: ProfileUpdateInput & {name: string},
  ): Promise<Profile> {
    const db = DatabaseService.getDatabase();
    return new Promise<Profile>((resolve, reject) => {
      db.transaction(tx => {
        // Check if profile exists
        tx.executeSql(
          'SELECT * FROM profiles LIMIT 1',
          [],
          async (_, results) => {
            const now = new Date().toISOString();

            if (results.rows.length > 0) {
              // Update existing profile
              const existing = this.mapRowToProfile(results.rows.item(0));
              tx.executeSql(
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
                () => {
                  this.getProfile().then(resolve).catch(reject);
                },
                (_, error) => {
                  console.error('Error updating profile:', error);
                  reject(error);
                  return false;
                },
              );
            } else {
              // Create new profile
              const id = uuidv4();
              tx.executeSql(
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
                () => {
                  this.getProfile().then(resolve).catch(reject);
                },
                (_, error) => {
                  console.error('Error creating profile:', error);
                  reject(error);
                  return false;
                },
              );
            }
          },
          (_, error) => {
            console.error('Error checking profile:', error);
            reject(error);
            return false;
          },
        );
      });
    });
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
