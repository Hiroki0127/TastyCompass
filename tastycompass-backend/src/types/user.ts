export interface User {
  id: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  avatarUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateUserData {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
}

export interface UpdateUserData {
  firstName?: string;
  lastName?: string;
  email?: string;
  avatarUrl?: string;
}
