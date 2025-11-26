export interface Jump {
  id: string;
  date: Date;
  location: string;
  altitude: number; // in feet or meters
  equipmentIds: string[]; // IDs of equipment used
  checklistCompleted: boolean;
  notes?: string;
}

export interface JumpCreateInput {
  date: Date;
  location: string;
  altitude: number;
  equipmentIds: string[];
  checklistCompleted: boolean;
  notes?: string;
}
