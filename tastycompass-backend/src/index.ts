import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { testConnection, initializeDatabase } from './database/connection';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const USE_POSTGRES = process.env.USE_POSTGRES === 'true';

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
  }

  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📱 API available at: http://localhost:${PORT}`);
    console.log(`🔍 Health check: http://localhost:${PORT}/api/health`);
  });
};

startServer().catch(console.error);

export default app;
