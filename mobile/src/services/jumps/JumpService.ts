import DatabaseService from '../database/DatabaseService';
import {Jump, JumpCreateInput} from '../../models/Jump';
import {v4 as uuidv4} from 'uuid';

class JumpService {
  async getAllJumps(): Promise<Jump[]> {
    const db = DatabaseService.getDatabase();
    return new Promise<Jump[]>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM jumps ORDER BY date DESC',
          [],
          (_, results) => {
            const jumps: Jump[] = [];
            for (let i = 0; i < results.rows.length; i++) {
              jumps.push(this.mapRowToJump(results.rows.item(i)));
            }
            resolve(jumps);
          },
          (_, error) => {
            console.error('Error getting jumps:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async getJumpById(id: string): Promise<Jump | null> {
    const db = DatabaseService.getDatabase();
    return new Promise<Jump | null>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM jumps WHERE id = ?',
          [id],
          (_, results) => {
            if (results.rows.length === 0) {
              resolve(null);
              return;
            }
            const jump = this.mapRowToJump(results.rows.item(0));
            // Load equipment IDs
            tx.executeSql(
              'SELECT equipment_id FROM jump_equipment WHERE jump_id = ?',
              [id],
              (_, eqResults) => {
                jump.equipmentIds = [];
                for (let i = 0; i < eqResults.rows.length; i++) {
                  jump.equipmentIds.push(eqResults.rows.item(i).equipment_id);
                }
                resolve(jump);
              },
              (_, error) => {
                console.error('Error loading equipment:', error);
                resolve(jump); // Return jump without equipment
                return false;
              },
            );
          },
          (_, error) => {
            console.error('Error getting jump:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async createJump(input: JumpCreateInput): Promise<Jump> {
    const db = DatabaseService.getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    return new Promise<Jump>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          `INSERT INTO jumps (id, date, location, altitude, checklist_completed, notes, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          [
            id,
            input.date.toISOString(),
            input.location,
            input.altitude,
            input.checklistCompleted ? 1 : 0,
            input.notes || null,
            now,
          ],
          () => {
            // Insert equipment associations
            if (input.equipmentIds.length > 0) {
              let completed = 0;
              input.equipmentIds.forEach(equipmentId => {
                tx.executeSql(
                  'INSERT INTO jump_equipment (jump_id, equipment_id) VALUES (?, ?)',
                  [id, equipmentId],
                  () => {
                    completed++;
                    if (completed === input.equipmentIds.length) {
                      this.getJumpById(id).then(resolve).catch(reject);
                    }
                  },
                  (_, error) => {
                    console.error('Error inserting equipment:', error);
                    completed++;
                    if (completed === input.equipmentIds.length) {
                      this.getJumpById(id).then(resolve).catch(reject);
                    }
                    return false;
                  },
                );
              });
            } else {
              this.getJumpById(id).then(resolve).catch(reject);
            }
          },
          (_, error) => {
            console.error('Error creating jump:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async deleteJump(id: string): Promise<void> {
    const db = DatabaseService.getDatabase();
    return new Promise<void>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'DELETE FROM jump_equipment WHERE jump_id = ?',
          [id],
          () => {
            tx.executeSql(
              'DELETE FROM jumps WHERE id = ?',
              [id],
              () => resolve(),
              (_, error) => {
                console.error('Error deleting jump:', error);
                reject(error);
                return false;
              },
            );
          },
          (_, error) => {
            console.error('Error deleting jump equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  private mapRowToJump(row: any): Jump {
    return {
      id: row.id,
      date: new Date(row.date),
      location: row.location,
      altitude: row.altitude,
      equipmentIds: [],
      checklistCompleted: row.checklist_completed === 1,
      notes: row.notes || undefined,
    };
  }
}

export default new JumpService();
