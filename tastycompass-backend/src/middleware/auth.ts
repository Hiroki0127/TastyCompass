import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/authService';
import { UserService } from '../services/userService';

// Request interface extension is now in src/types/express.d.ts

export const authenticateToken = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    const token = AuthService.extractTokenFromHeader(authHeader);

    // Verify token
    const decoded = AuthService.verifyToken(token);

    // Find user
    const user = await UserService.findUserById(decoded.userId);
    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    // Add user info to request
    (req as any).user = {
      id: user.id,
      email: user.email,
    };

    next();
  } catch (error: any) {
    console.error('Authentication error:', error.message);
    res.status(401).json({ 
      error: 'Authentication failed',
      message: error.message 
    });
  }
};

// Optional authentication middleware (doesn't fail if no token)
export const optionalAuth = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      // No token provided, continue without user
      next();
      return;
    }

    const token = AuthService.extractTokenFromHeader(authHeader);
    const decoded = AuthService.verifyToken(token);

    const user = await UserService.findUserById(decoded.userId);
    if (user) {
      (req as any).user = {
        id: user.id,
        email: user.email,
      };
    }

    next();
  } catch (error) {
    // If token is invalid, continue without user
    next();
  }
};
