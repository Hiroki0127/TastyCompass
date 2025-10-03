"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authService_1 = require("../services/authService");
const userService_1 = require("../services/userService");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Register new user
router.post('/register', async (req, res) => {
    try {
        const { email, password, firstName, lastName } = req.body;
        // Validate input
        if (!email || !password || !firstName || !lastName) {
            return res.status(400).json({
                error: 'Missing required fields',
                message: 'Email, password, first name, and last name are required'
            });
        }
        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                error: 'Invalid email format'
            });
        }
        // Validate password strength
        if (password.length < 6) {
            return res.status(400).json({
                error: 'Password too short',
                message: 'Password must be at least 6 characters long'
            });
        }
        // Check if user already exists
        const existingUser = await userService_1.UserService.findUserByEmail(email);
        if (existingUser) {
            return res.status(409).json({
                error: 'User already exists',
                message: 'A user with this email already exists'
            });
        }
        // Hash password
        const hashedPassword = await authService_1.AuthService.hashPassword(password);
        // Create user
        const user = await userService_1.UserService.createUser({
            email,
            password: hashedPassword,
            firstName,
            lastName,
        });
        // Generate token
        const token = authService_1.AuthService.generateToken(user.id, user.email);
        // Return user (without password) and token
        const authResult = authService_1.AuthService.createAuthResult(user, token);
        res.status(201).json({
            message: 'User registered successfully',
            ...authResult,
        });
    }
    catch (error) {
        console.error('Registration error:', error);
        res.status(500).json({
            error: 'Registration failed',
            message: error.message
        });
    }
});
// Login user
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                error: 'Missing credentials',
                message: 'Email and password are required'
            });
        }
        // Find user
        const user = await userService_1.UserService.findUserByEmail(email);
        if (!user) {
            return res.status(401).json({
                error: 'Invalid credentials',
                message: 'Email or password is incorrect'
            });
        }
        // Verify password
        const isPasswordValid = await authService_1.AuthService.verifyPassword(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({
                error: 'Invalid credentials',
                message: 'Email or password is incorrect'
            });
        }
        // Generate token
        const token = authService_1.AuthService.generateToken(user.id, user.email);
        // Return user (without password) and token
        const authResult = authService_1.AuthService.createAuthResult(user, token);
        res.json({
            message: 'Login successful',
            ...authResult,
        });
    }
    catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            error: 'Login failed',
            message: error.message
        });
    }
});
// Get current user profile
router.get('/me', auth_1.authenticateToken, async (req, res) => {
    try {
        // This will be called after authenticateToken middleware
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        const user = await userService_1.UserService.findUserById(userId);
        if (!user) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        // Return user without password
        const { password, ...userWithoutPassword } = user;
        res.json({ user: userWithoutPassword });
    }
    catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            error: 'Failed to get profile',
            message: error.message
        });
    }
});
// Update user profile
router.put('/me', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        const { firstName, lastName, email } = req.body;
        const updates = {};
        if (firstName)
            updates.firstName = firstName;
        if (lastName)
            updates.lastName = lastName;
        if (email) {
            // Check if email is already taken by another user
            const existingUser = await userService_1.UserService.findUserByEmail(email);
            if (existingUser && existingUser.id !== userId) {
                return res.status(409).json({
                    error: 'Email already taken',
                    message: 'This email is already registered to another account'
                });
            }
            updates.email = email;
        }
        const updatedUser = await userService_1.UserService.updateUser(userId, updates);
        if (!updatedUser) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        // Return user without password
        const { password, ...userWithoutPassword } = updatedUser;
        res.json({
            message: 'Profile updated successfully',
            user: userWithoutPassword
        });
    }
    catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            error: 'Failed to update profile',
            message: error.message
        });
    }
});
exports.default = router;
