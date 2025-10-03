"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.optionalAuth = exports.authenticateToken = void 0;
const authService_1 = require("../services/authService");
const userService_1 = require("../services/userService");
// Request interface extension is now in src/types/express.d.ts
const authenticateToken = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        const token = authService_1.AuthService.extractTokenFromHeader(authHeader);
        // Verify token
        const decoded = authService_1.AuthService.verifyToken(token);
        // Find user
        const user = await userService_1.UserService.findUserById(decoded.userId);
        if (!user) {
            res.status(401).json({ error: 'User not found' });
            return;
        }
        // Add user info to request
        req.user = {
            id: user.id,
            email: user.email,
        };
        next();
    }
    catch (error) {
        console.error('Authentication error:', error.message);
        res.status(401).json({
            error: 'Authentication failed',
            message: error.message
        });
    }
};
exports.authenticateToken = authenticateToken;
// Optional authentication middleware (doesn't fail if no token)
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader) {
            // No token provided, continue without user
            next();
            return;
        }
        const token = authService_1.AuthService.extractTokenFromHeader(authHeader);
        const decoded = authService_1.AuthService.verifyToken(token);
        const user = await userService_1.UserService.findUserById(decoded.userId);
        if (user) {
            req.user = {
                id: user.id,
                email: user.email,
            };
        }
        next();
    }
    catch (error) {
        // If token is invalid, continue without user
        next();
    }
};
exports.optionalAuth = optionalAuth;
