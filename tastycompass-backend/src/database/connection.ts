import { Pool } from 'pg';
import dotenv from 'dotenv';
import { UserService } from '../services/serviceFactory';
import { AuthService } from '../services/authService';

dotenv.config();

// Parse DATABASE_URL if provided (Railway format: postgresql://user:password@host:port/database)
// Otherwise use individual environment variables
function getDatabaseConfig() {
  const databaseUrl = process.env.DATABASE_URL;
  
  if (databaseUrl) {
    // Parse DATABASE_URL (Railway provides this automatically)
    try {
      const url = new URL(databaseUrl);
      return {
        user: url.username,
        host: url.hostname,
        database: url.pathname.slice(1), // Remove leading '/'
        password: url.password,
        port: parseInt(url.port || '5432'),
        ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
      };
    } catch (error) {
      console.error('❌ Failed to parse DATABASE_URL:', error);
      // Fall through to individual variables
    }
  }
  
  // Fall back to individual environment variables
  return {
    user: process.env.DB_USER || 'postgres',
    host: process.env.DB_HOST || 'localhost',
    database: process.env.DB_NAME || 'tastycompass',
    password: process.env.DB_PASSWORD || 'password',
    port: parseInt(process.env.DB_PORT || '5432'),
  };
}

// Database connection configuration
const pool = new Pool(getDatabaseConfig());

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

// Test database connection
export const testConnection = async (): Promise<void> => {
  try {
    const client = await pool.connect();
    console.log('✅ PostgreSQL database connected successfully');
    client.release();
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    throw error;
  }
};

// Initialize database schema
export const initializeDatabase = async (): Promise<void> => {
  const client = await pool.connect();
  
  try {
    // Create users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id VARCHAR(255) PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        avatar_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Add avatar_url column if it doesn't exist (for existing databases)
    await client.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS avatar_url TEXT
    `);

    // Create favorites table
    await client.query(`
      CREATE TABLE IF NOT EXISTS favorites (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        restaurant_id VARCHAR(255) NOT NULL,
        restaurant_name VARCHAR(255) NOT NULL,
        restaurant_address TEXT,
        restaurant_rating DECIMAL(2,1),
        restaurant_price_level VARCHAR(10),
        restaurant_photo_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, restaurant_id)
      )
    `);

    // Create reviews table
    await client.query(`
      CREATE TABLE IF NOT EXISTS reviews (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        restaurant_id VARCHAR(255) NOT NULL,
        rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
        title VARCHAR(255),
        content TEXT NOT NULL,
        helpful_count INTEGER DEFAULT 0,
        is_reported BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE(user_id, restaurant_id)
      )
    `);

    // Create indexes for better performance
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON favorites(user_id);
      CREATE INDEX IF NOT EXISTS idx_favorites_restaurant_id ON favorites(restaurant_id);
      CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON reviews(user_id);
      CREATE INDEX IF NOT EXISTS idx_reviews_restaurant_id ON reviews(restaurant_id);
      CREATE INDEX IF NOT EXISTS idx_reviews_rating ON reviews(rating);
      CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON reviews(created_at DESC);
    `);

    // Create trigger function for updated_at
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);

    // Create triggers
    await client.query(`
      DROP TRIGGER IF EXISTS update_users_updated_at ON users;
      CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();

      DROP TRIGGER IF EXISTS update_reviews_updated_at ON reviews;
      CREATE TRIGGER update_reviews_updated_at
        BEFORE UPDATE ON reviews
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    `);

    console.log('✅ Database schema initialized successfully');
    
    // Initialize demo account
    await initializeDemoAccount();
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  } finally {
    client.release();
  }
};

export default pool;
