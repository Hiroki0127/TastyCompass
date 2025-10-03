"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserService = void 0;
// In-memory storage for now (we'll replace with database later)
class UserStorage {
    constructor() {
        this.users = new Map();
        this.emailIndex = new Map();
    }
    create(user) {
        this.users.set(user.id, user);
        this.emailIndex.set(user.email.toLowerCase(), user.id);
    }
    findById(id) {
        return this.users.get(id);
    }
    findByEmail(email) {
        const id = this.emailIndex.get(email.toLowerCase());
        return id ? this.users.get(id) : undefined;
    }
    update(id, updates) {
        const user = this.users.get(id);
        if (!user)
            return undefined;
        const updatedUser = { ...user, ...updates, updatedAt: new Date() };
        this.users.set(id, updatedUser);
        // Update email index if email changed
        if (updates.email && updates.email !== user.email) {
            this.emailIndex.delete(user.email.toLowerCase());
            this.emailIndex.set(updates.email.toLowerCase(), id);
        }
        return updatedUser;
    }
    delete(id) {
        const user = this.users.get(id);
        if (!user)
            return false;
        this.users.delete(id);
        this.emailIndex.delete(user.email.toLowerCase());
        return true;
    }
    exists(email) {
        return this.emailIndex.has(email.toLowerCase());
    }
}
const userStorage = new UserStorage();
class UserService {
    // Generate unique ID
    static generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }
    // Create new user
    static async createUser(userData) {
        // Check if user already exists
        if (userStorage.exists(userData.email)) {
            throw new Error('User with this email already exists');
        }
        const user = {
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
    static async findUserById(id) {
        const user = userStorage.findById(id);
        return user || null;
    }
    // Find user by email
    static async findUserByEmail(email) {
        const user = userStorage.findByEmail(email);
        return user || null;
    }
    // Update user
    static async updateUser(id, updates) {
        const user = userStorage.update(id, updates);
        return user || null;
    }
    // Delete user
    static async deleteUser(id) {
        return userStorage.delete(id);
    }
    // Check if user exists
    static async userExists(email) {
        return userStorage.exists(email);
    }
    // Get all users (for debugging)
    static async getAllUsers() {
        return Array.from(userStorage['users'].values());
    }
}
exports.UserService = UserService;
