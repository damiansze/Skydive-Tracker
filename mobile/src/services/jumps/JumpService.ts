import DatabaseService from '../database/DatabaseService';
import {Jump, JumpCreateInput} from '../../models/Jump';
import {v4 as uuidv4} from 'uuid';

class JumpService {
  async getAllJumps(): Promise<Jump[]> {
    const db = DatabaseService.getDatabase();
    const [results] = await db.executeSql(
      'SELECT * FROM jumps ORDER BY date DESC',
    );
    const rows = results.rows.raw();
    return rows.map(this.mapRowToJump);
  }

  async getJumpById(id: string): Promise<Jump | null> {
    const db = DatabaseService.getDatabase();
    const [results] = await db.executeSql('SELECT * FROM jumps WHERE id = ?', [
      id,
    ]);
    if (results.rows.length === 0) {
      return null;
    }
    return this.mapRowToJump(results.rows.item(0));
  }

  async createJump(input: JumpCreateInput): Promise<Jump> {
    const db = DatabaseService.getDatabase();
    const id = uuidv4();
    const now = new Date().toISOString();

    await db.executeSql(
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
    );

    // Insert equipment associations
    for (const equipmentId of input.equipmentIds) {
      await db.executeSql(
        'INSERT INTO jump_equipment (jump_id, equipment_id) VALUES (?, ?)',
        [id, equipmentId],
      );
    }

    return this.getJumpById(id) as Promise<Jump>;
  }

  async deleteJump(id: string): Promise<void> {
    const db = DatabaseService.getDatabase();
    await db.executeSql('DELETE FROM jumps WHERE id = ?', [id]);
  }

  private mapRowToJump(row: any): Jump {
    return {
      id: row.id,
      date: new Date(row.date),
      location: row.location,
      altitude: row.altitude,
      equipmentIds: [], // Will be loaded separately if needed
      checklistCompleted: row.checklist_completed === 1,
      notes: row.notes || undefined,
    };
  }
}

export default new JumpService();
