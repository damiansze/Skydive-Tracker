import DatabaseService from '../database/DatabaseService';
import {Equipment, EquipmentType} from '../../models/Equipment';
import {v4 as uuidv4} from 'uuid';

class EquipmentService {
  async getAllEquipment(): Promise<Equipment[]> {
    const db = DatabaseService.getDatabase();
    return new Promise<Equipment[]>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM equipment',
          [],
          (_, results) => {
            const equipment: Equipment[] = [];
            for (let i = 0; i < results.rows.length; i++) {
              equipment.push(this.mapRowToEquipment(results.rows.item(i)));
            }
            resolve(equipment);
          },
          (_, error) => {
            console.error('Error getting equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async getEquipmentById(id: string): Promise<Equipment | null> {
    const db = DatabaseService.getDatabase();
    return new Promise<Equipment | null>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'SELECT * FROM equipment WHERE id = ?',
          [id],
          (_, results) => {
            if (results.rows.length === 0) {
              resolve(null);
              return;
            }
            resolve(this.mapRowToEquipment(results.rows.item(0)));
          },
          (_, error) => {
            console.error('Error getting equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async createEquipment(equipment: Omit<Equipment, 'id'>): Promise<Equipment> {
    const db = DatabaseService.getDatabase();
    const id = uuidv4();

    return new Promise<Equipment>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
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
          () => {
            this.getEquipmentById(id).then(resolve).catch(reject);
          },
          (_, error) => {
            console.error('Error creating equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async updateEquipment(
    id: string,
    updates: Partial<Equipment>,
  ): Promise<Equipment> {
    const db = DatabaseService.getDatabase();
    return new Promise<Equipment>((resolve, reject) => {
      db.transaction(tx => {
        const fields: string[] = [];
        const values: any[] = [];

        if (updates.name !== undefined) {
          fields.push('name = ?');
          values.push(updates.name);
        }
        if (updates.type !== undefined) {
          fields.push('type = ?');
          values.push(updates.type);
        }
        if (updates.manufacturer !== undefined) {
          fields.push('manufacturer = ?');
          values.push(updates.manufacturer || null);
        }
        if (updates.model !== undefined) {
          fields.push('model = ?');
          values.push(updates.model || null);
        }
        if (updates.serialNumber !== undefined) {
          fields.push('serial_number = ?');
          values.push(updates.serialNumber || null);
        }
        if (updates.purchaseDate !== undefined) {
          fields.push('purchase_date = ?');
          values.push(updates.purchaseDate?.toISOString() || null);
        }
        if (updates.notes !== undefined) {
          fields.push('notes = ?');
          values.push(updates.notes || null);
        }

        if (fields.length === 0) {
          this.getEquipmentById(id).then(resolve).catch(reject);
          return;
        }

        values.push(id);
        tx.executeSql(
          `UPDATE equipment SET ${fields.join(', ')} WHERE id = ?`,
          values,
          () => {
            this.getEquipmentById(id).then(resolve).catch(reject);
          },
          (_, error) => {
            console.error('Error updating equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
  }

  async deleteEquipment(id: string): Promise<void> {
    const db = DatabaseService.getDatabase();
    return new Promise<void>((resolve, reject) => {
      db.transaction(tx => {
        tx.executeSql(
          'DELETE FROM equipment WHERE id = ?',
          [id],
          () => resolve(),
          (_, error) => {
            console.error('Error deleting equipment:', error);
            reject(error);
            return false;
          },
        );
      });
    });
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
