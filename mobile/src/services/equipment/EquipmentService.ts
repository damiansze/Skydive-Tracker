import DatabaseService from '../database/DatabaseService';
import {Equipment, EquipmentType} from '../../models/Equipment';
import {v4 as uuidv4} from 'uuid';

class EquipmentService {
  async getAllEquipment(): Promise<Equipment[]> {
    const db = DatabaseService.getDatabase();
    const [results] = await db.executeSql('SELECT * FROM equipment');
    return results.rows.raw().map(this.mapRowToEquipment);
  }

  async getEquipmentById(id: string): Promise<Equipment | null> {
    const db = DatabaseService.getDatabase();
    const [results] = await db.executeSql(
      'SELECT * FROM equipment WHERE id = ?',
      [id],
    );
    if (results.rows.length === 0) {
      return null;
    }
    return this.mapRowToEquipment(results.rows.item(0));
  }

  async createEquipment(equipment: Omit<Equipment, 'id'>): Promise<Equipment> {
    const db = DatabaseService.getDatabase();
    const id = uuidv4();

    await db.executeSql(
      `INSERT INTO equipment (id, name, type, manufacturer, model, serial_number, purchase_date, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        id,
        equipment.name,
        equipment.type,
        equipment.manufacturer || null,
        equipment.model || null,
        equipment.serialNumber || null,
        equipment.purchaseDate?.toISOString() || null,
        equipment.notes || null,
      ],
    );

    return this.getEquipmentById(id) as Promise<Equipment>;
  }

  async updateEquipment(
    id: string,
    updates: Partial<Equipment>,
  ): Promise<Equipment> {
    const db = DatabaseService.getDatabase();
    // Implementation for update
    return this.getEquipmentById(id) as Promise<Equipment>;
  }

  async deleteEquipment(id: string): Promise<void> {
    const db = DatabaseService.getDatabase();
    await db.executeSql('DELETE FROM equipment WHERE id = ?', [id]);
  }

  private mapRowToEquipment(row: any): Equipment {
    return {
      id: row.id,
      name: row.name,
      type: row.type as EquipmentType,
      manufacturer: row.manufacturer || undefined,
      model: row.model || undefined,
      serialNumber: row.serial_number || undefined,
      purchaseDate: row.purchase_date ? new Date(row.purchase_date) : undefined,
      notes: row.notes || undefined,
    };
  }
}

export default new EquipmentService();
