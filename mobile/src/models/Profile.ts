export interface Profile {
  id: string;
  name: string;
  licenseNumber?: string;
  licenseType?: string;
  totalJumps: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface ProfileUpdateInput {
  name?: string;
  licenseNumber?: string;
  licenseType?: string;
}
