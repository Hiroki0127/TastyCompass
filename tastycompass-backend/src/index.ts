import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { testConnection, initializeDatabase } from './database/connection';
import { UserService } from './services/serviceFactory';
import { AuthService } from './services/authService';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
// Enable PostgreSQL if DATABASE_URL is provided (Railway) or USE_POSTGRES is explicitly set
const USE_POSTGRES = process.env.USE_POSTGRES === 'true' || !!process.env.DATABASE_URL;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // Enable CORS
app.use(morgan('combined')); // Logging
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({ extended: true })); // Parse URL-encoded bodies

// Basic health check route
app.get('/', (req, res) => {
  res.json({
    message: 'TastyCompass API Server',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// Import routes
import restaurantRoutes from './routes/restaurants';
import authRoutes from './routes/auth';
import favoriteRoutes from './routes/favorites';
import reviewRoutes from './routes/reviews';

// API routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Auth routes
app.use('/api/auth', authRoutes);

// Restaurant routes
app.use('/api/restaurants', restaurantRoutes);

// Favorite routes
app.use('/api/favorites', favoriteRoutes);

// Review routes
app.use('/api/reviews', reviewRoutes);

// Initialize demo account for testing
const initializeDemoAccount = async (): Promise<void> => {
  try {
    const demoEmail = 'demo@tastycompass.com';
    const demoPassword = 'demo123';
    
    // Check if demo account already exists
    const existingUser = await UserService.findUserByEmail(demoEmail);
    if (existingUser) {
      console.log('✅ Demo account already exists');
      return;
    }
    
    // Create demo account
    const hashedPassword = await AuthService.hashPassword(demoPassword);
    await UserService.createUser({
      email: demoEmail,
      password: hashedPassword,
      firstName: 'Demo',
      lastName: 'User'
    });
    
    console.log('✅ Demo account created (email: demo@tastycompass.com, password: demo123)');
  } catch (error) {
    console.error('⚠️ Failed to create demo account:', error);
    // Don't throw - demo account is optional
  }
};

// Initialize database and start server
const startServer = async () => {
  if (USE_POSTGRES) {
    try {
      await testConnection();
      await initializeDatabase();
      console.log('💾 Storage: PostgreSQL (persistent)');
    } catch (error) {
      console.error('Failed to initialize database, falling back to in-memory storage');
      console.log('💾 Storage: In-memory (data will reset on restart)');
    }
  } else {
    console.log('💾 Storage: In-memory (data will reset on restart)');
    // Initialize demo account for in-memory storage
    await initializeDemoAccount();
  }

  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📱 API available at: http://localhost:${PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
  });
};

startServer().catch(console.error);

export default app;
