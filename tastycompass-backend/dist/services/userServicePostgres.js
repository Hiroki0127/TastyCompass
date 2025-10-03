"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.UserService = void 0;
const connection_1 = __importDefault(require("../database/connection"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
class UserService {
    // Create a new user
    static async createUser(userData) {
        const client = await connection_1.default.connect();
        try {
            // Hash the password
            const saltRounds = 12;
            const passwordHash = await bcryptjs_1.default.hash(userData.password, saltRounds);
            // Generate unique ID
            const id = `user_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            // Insert user into database
            const query = `
        INSERT INTO users (id, email, password_hash, first_name, last_name)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id, email, first_name, last_name, created_at, updated_at
      `;
            const values = [id, userData.email, passwordHash, userData.firstName, userData.lastName];
            const result = await client.query(query, values);
            const user = result.rows[0];
            return {
                id: user.id,
                email: user.email,
                password: passwordHash, // Return hashed password for AuthService
                firstName: user.first_name,
                lastName: user.last_name,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            };
        }
        finally {
            client.release();
        }
    }
    // Find user by ID
    static async findUserById(id) {
        const client = await connection_1.default.connect();
        try {
            const query = 'SELECT * FROM users WHERE id = $1';
            const result = await client.query(query, [id]);
            if (result.rows.length === 0) {
                return null;
            }
            const user = result.rows[0];
            return {
                id: user.id,
                email: user.email,
                password: user.password_hash,
                firstName: user.first_name,
                lastName: user.last_name,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            };
        }
        finally {
            client.release();
        }
    }
    // Find user by email
    static async findUserByEmail(email) {
        const client = await connection_1.default.connect();
        try {
            const query = 'SELECT * FROM users WHERE email = $1';
            const result = await client.query(query, [email]);
            if (result.rows.length === 0) {
                return null;
            }
            const user = result.rows[0];
            return {
                id: user.id,
                email: user.email,
                password: user.password_hash,
                firstName: user.first_name,
                lastName: user.last_name,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            };
        }
        finally {
            client.release();
        }
    }
    // Update user
    static async updateUser(id, updates) {
        const client = await connection_1.default.connect();
        try {
            // Build dynamic query based on provided updates
            const updateFields = [];
            const values = [];
            let paramCount = 1;
            if (updates.firstName !== undefined) {
                updateFields.push(`first_name = $${paramCount++}`);
                values.push(updates.firstName);
            }
            if (updates.lastName !== undefined) {
                updateFields.push(`last_name = $${paramCount++}`);
                values.push(updates.lastName);
            }
            if (updates.email !== undefined) {
                updateFields.push(`email = $${paramCount++}`);
                values.push(updates.email);
            }
            if (updateFields.length === 0) {
                // No updates provided, return current user
                return await this.findUserById(id);
            }
            // Add updated_at field
            updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
            // Add id parameter
            values.push(id);
            const query = `
        UPDATE users 
        SET ${updateFields.join(', ')} 
        WHERE id = $${paramCount}
        RETURNING id, email, first_name, last_name, created_at, updated_at
      `;
            const result = await client.query(query, values);
            if (result.rows.length === 0) {
                return null;
            }
            const user = result.rows[0];
            return {
                id: user.id,
                email: user.email,
                password: '', // Don't return password hash
                firstName: user.first_name,
                lastName: user.last_name,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            };
        }
        finally {
            client.release();
        }
    }
    // Delete user
    static async deleteUser(id) {
        const client = await connection_1.default.connect();
        try {
            const query = 'DELETE FROM users WHERE id = $1';
            const result = await client.query(query, [id]);
            return result.rowCount > 0;
        }
        finally {
            client.release();
        }
    }
    // Get all users (for admin purposes)
    static async getAllUsers() {
        const client = await connection_1.default.connect();
        try {
            const query = 'SELECT id, email, first_name, last_name, created_at, updated_at FROM users ORDER BY created_at DESC';
            const result = await client.query(query);
            return result.rows.map(user => ({
                id: user.id,
                email: user.email,
                password: '', // Don't return password hashes
                firstName: user.first_name,
                lastName: user.last_name,
                createdAt: user.created_at,
                updatedAt: user.updated_at,
            }));
        }
        finally {
            client.release();
        }
    }
}
exports.UserService = UserService;
