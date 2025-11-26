export interface Equipment {
  id: string;
  name: string;
  type: EquipmentType;
  manufacturer?: string;
  model?: string;
  serialNumber?: string;
  purchaseDate?: Date;
  notes?: string;
}

export enum EquipmentType {
  PARACHUTE = 'parachute',
  HARNESS = 'harness',
  RESERVE = 'reserve',
  ALTIMETER = 'altimeter',
  HELMET = 'helmet',
  GOGGLES = 'goggles',
  OTHER = 'other',
}

export interface ChecklistItem {
  id: string;
  equipmentId: string;
  description: string;
  required: boolean;
}
