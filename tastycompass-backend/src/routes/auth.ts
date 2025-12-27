import { Router, Request, Response } from 'express';
import { AuthService, LoginCredentials, RegisterData } from '../services/authService';
import { UserService } from '../services/serviceFactory';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// Register new user
router.post('/register', async (req: Request, res: Response) => {
  try {
    const { email, password, firstName, lastName }: RegisterData = req.body;

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
    const existingUser = await UserService.findUserByEmail(email);
    if (existingUser) {
      return res.status(409).json({ 
        error: 'User already exists',
        message: 'A user with this email already exists'
      });
    }

    // Create user (UserService will hash the password)
    const user = await UserService.createUser({
      email,
      password,
      firstName,
      lastName,
    });

    // Generate token
    const token = AuthService.generateToken(user.id, user.email);

    // Return user (without password) and token
    const authResult = AuthService.createAuthResult(user, token);

    res.status(201).json({
      message: 'User registered successfully',
      ...authResult,
    });
  } catch (error: any) {
    console.error('Registration error:', error);
    res.status(500).json({ 
      error: 'Registration failed',
      message: error.message 
    });
  }
});

// Login user
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { email, password }: LoginCredentials = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Missing credentials',
        message: 'Email and password are required'
      });
    }

    // Find user
    const user = await UserService.findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ 
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      });
    }

    // Verify password
    const isPasswordValid = await AuthService.verifyPassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ 
        error: 'Invalid credentials',
        message: 'Email or password is incorrect'
      });
    }

    // Generate token
    const token = AuthService.generateToken(user.id, user.email);

    // Return user (without password) and token
    const authResult = AuthService.createAuthResult(user, token);

    res.json({
      message: 'Login successful',
      ...authResult,
    });
  } catch (error: any) {
    console.error('Login error:', error);
    res.status(500).json({ 
      error: 'Login failed',
      message: error.message 
    });
  }
});

// Get current user profile
router.get('/me', authenticateToken, async (req: Request, res: Response) => {
  try {
    // This will be called after authenticateToken middleware
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    const user = await UserService.findUserById(userId);
    if (!user) {
      return res.status(404).json({ 
        error: 'User not found' 
      });
    }

    // Return user without password
    const { password, ...userWithoutPassword } = user;
    res.json({ user: userWithoutPassword });
  } catch (error: any) {
    console.error('Get profile error:', error);
    res.status(500).json({ 
      error: 'Failed to get profile',
      message: error.message 
    });
  }
});

// Update user profile
router.put('/me', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    const { firstName, lastName, email, avatarUrl } = req.body;
    const updates: any = {};

    if (firstName) updates.firstName = firstName;
    if (lastName) updates.lastName = lastName;
    if (avatarUrl !== undefined) updates.avatarUrl = avatarUrl;
    if (email) {
      // Check if email is already taken by another user
      const existingUser = await UserService.findUserByEmail(email);
      if (existingUser && existingUser.id !== userId) {
        return res.status(409).json({ 
          error: 'Email already taken',
          message: 'This email is already registered to another account'
        });
      }
      updates.email = email;
    }

    const updatedUser = await UserService.updateUser(userId, updates);
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
  } catch (error: any) {
    console.error('Update profile error:', error);
    res.status(500).json({ 
      error: 'Failed to update profile',
      message: error.message 
    });
  }
});

export default router;
