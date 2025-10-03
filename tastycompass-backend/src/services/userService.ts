import { User, CreateUserData, UpdateUserData } from '../types/user';

// In-memory storage for now (we'll replace with database later)
class UserStorage {
  private users: Map<string, User> = new Map();
  private emailIndex: Map<string, string> = new Map();

  create(user: User): void {
    this.users.set(user.id, user);
    this.emailIndex.set(user.email.toLowerCase(), user.id);
  }

  findById(id: string): User | undefined {
    return this.users.get(id);
  }

  findByEmail(email: string): User | undefined {
    const id = this.emailIndex.get(email.toLowerCase());
    return id ? this.users.get(id) : undefined;
  }

  update(id: string, updates: Partial<User>): User | undefined {
    const user = this.users.get(id);
    if (!user) return undefined;

    const updatedUser = { ...user, ...updates, updatedAt: new Date() };
    this.users.set(id, updatedUser);

    // Update email index if email changed
    if (updates.email && updates.email !== user.email) {
      this.emailIndex.delete(user.email.toLowerCase());
      this.emailIndex.set(updates.email.toLowerCase(), id);
    }

    return updatedUser;
  }

  delete(id: string): boolean {
    const user = this.users.get(id);
    if (!user) return false;

    this.users.delete(id);
    this.emailIndex.delete(user.email.toLowerCase());
    return true;
  }

  exists(email: string): boolean {
    return this.emailIndex.has(email.toLowerCase());
  }
}

const userStorage = new UserStorage();

export class UserService {
  // Generate unique ID
  private static generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  // Create new user
  static async createUser(userData: CreateUserData): Promise<User> {
    // Check if user already exists
    if (userStorage.exists(userData.email)) {
      throw new Error('User with this email already exists');
    }

    const user: User = {
      id: this.generateId(),
      email: userData.email,
      password: userData.password, // Will be hashed by AuthService
      firstName: userData.firstName,
      lastName: userData.lastName,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    userStorage.create(user);
    return user;
  }

  // Find user by ID
  static async findUserById(id: string): Promise<User | null> {
    const user = userStorage.findById(id);
    return user || null;
  }

  // Find user by email
  static async findUserByEmail(email: string): Promise<User | null> {
    const user = userStorage.findByEmail(email);
    return user || null;
  }

  // Update user
  static async updateUser(id: string, updates: UpdateUserData): Promise<User | null> {
    const user = userStorage.update(id, updates);
    return user || null;
  }

  // Delete user
  static async deleteUser(id: string): Promise<boolean> {
    return userStorage.delete(id);
  }

  // Check if user exists
  static async userExists(email: string): Promise<boolean> {
    return userStorage.exists(email);
  }

  // Get all users (for debugging)
  static async getAllUsers(): Promise<User[]> {
    return Array.from(userStorage['users'].values());
  }
}
