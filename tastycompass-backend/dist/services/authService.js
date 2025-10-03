"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthService = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
class AuthService {
    // Hash password
    static async hashPassword(password) {
        const saltRounds = 12;
        return bcryptjs_1.default.hash(password, saltRounds);
    }
    // Verify password
    static async verifyPassword(password, hashedPassword) {
        return bcryptjs_1.default.compare(password, hashedPassword);
    }
    // Generate JWT token
    static generateToken(userId, email) {
        const payload = {
            userId,
            email,
        };
        // Use type assertion to bypass strict typing
        return jsonwebtoken_1.default.sign(payload, JWT_SECRET, { expiresIn: '7d' });
    }
    // Verify JWT token
    static verifyToken(token) {
        try {
            return jsonwebtoken_1.default.verify(token, JWT_SECRET);
        }
        catch (error) {
            throw new Error('Invalid or expired token');
        }
    }
    // Extract token from Authorization header
    static extractTokenFromHeader(authHeader) {
        if (!authHeader) {
            throw new Error('Authorization header is required');
        }
        const parts = authHeader.split(' ');
        if (parts.length !== 2 || parts[0] !== 'Bearer') {
            throw new Error('Invalid authorization header format');
        }
        return parts[1];
    }
    // Create auth result (user without password + token)
    static createAuthResult(user, token) {
        const { password, ...userWithoutPassword } = user;
        return {
            user: userWithoutPassword,
            token,
        };
    }
}
exports.AuthService = AuthService;
