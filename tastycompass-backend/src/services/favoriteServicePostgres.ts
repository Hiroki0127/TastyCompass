import { Favorite, CreateFavoriteData, FavoriteWithRestaurant } from '../types/favorite';
import { GooglePlacesService } from './googlePlacesService';
import pool from '../database/connection';

export class FavoriteService {
  private static googlePlacesService = new GooglePlacesService(process.env.GOOGLE_PLACES_API_KEY || '');

  // Create a new favorite
  static async createFavorite(favoriteData: CreateFavoriteData): Promise<Favorite> {
    const client = await pool.connect();
    
    try {
      // Generate unique ID
      const id = `fav_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // Use provided data or get restaurant details from Google Places API
      let restaurantName = favoriteData.restaurantName || 'Unknown Restaurant';
      let restaurantAddress = favoriteData.restaurantAddress || '';
      let restaurantPhotoUrl = favoriteData.restaurantPhotoUrl || '';
      
      if (!favoriteData.restaurantName) {
        try {
          const restaurantDetails = await this.googlePlacesService.getRestaurantDetails(favoriteData.restaurantId);
          restaurantName = restaurantDetails.name;
          restaurantAddress = restaurantDetails.address;
          restaurantPhotoUrl = restaurantDetails.photos?.[0]?.url || '';
        } catch (error) {
          console.warn('Failed to fetch restaurant details:', error);
        }
      }
      
      // Insert favorite into database
      const query = `
        INSERT INTO favorites (id, user_id, restaurant_id, restaurant_name, restaurant_address, restaurant_photo_url)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `;
      
      const values = [id, favoriteData.userId, favoriteData.restaurantId, restaurantName, restaurantAddress, restaurantPhotoUrl];
      const result = await client.query(query, values);
      
      const favorite = result.rows[0];
      return {
        id: favorite.id,
        userId: favorite.user_id,
        restaurantId: favorite.restaurant_id,
        restaurantName: favorite.restaurant_name,
        restaurantAddress: favorite.restaurant_address,
        restaurantPhotoUrl: favorite.restaurant_photo_url,
        createdAt: favorite.created_at,
        updatedAt: favorite.created_at, // Use created_at as updated_at for now
      };
    } finally {
      client.release();
    }
  }

  // Get all favorites for a user
  static async getFavoritesByUserId(userId: string): Promise<FavoriteWithRestaurant[]> {
    const client = await pool.connect();
    
    try {
      const query = `
        SELECT id, user_id, restaurant_id, restaurant_name, restaurant_address, restaurant_photo_url, created_at
        FROM favorites 
        WHERE user_id = $1
        ORDER BY created_at DESC
      `;
      
      const result = await client.query(query, [userId]);
      
      return result.rows.map(favorite => ({
        id: favorite.id,
        userId: favorite.user_id,
        restaurantId: favorite.restaurant_id,
        restaurantName: favorite.restaurant_name,
        restaurantAddress: favorite.restaurant_address,
        restaurantPhotoUrl: favorite.restaurant_photo_url,
        createdAt: favorite.created_at,
        updatedAt: favorite.created_at, // Use created_at as updated_at for now
      }));
    } finally {
      client.release();
    }
  }

  // Check if a restaurant is favorited by a user
  static async isRestaurantFavorited(userId: string, restaurantId: string): Promise<boolean> {
    const client = await pool.connect();
    
    try {
      const query = 'SELECT 1 FROM favorites WHERE user_id = $1 AND restaurant_id = $2 LIMIT 1';
      const result = await client.query(query, [userId, restaurantId]);
      
      return result.rows.length > 0;
    } finally {
      client.release();
    }
  }

  // Get favorite by user and restaurant
  static async getFavoriteByUserAndRestaurant(userId: string, restaurantId: string): Promise<Favorite | null> {
    const client = await pool.connect();
    
    try {
      const query = 'SELECT * FROM favorites WHERE user_id = $1 AND restaurant_id = $2';
      const result = await client.query(query, [userId, restaurantId]);
      
      if (result.rows.length === 0) {
        return null;
      }
      
      const favorite = result.rows[0];
      return {
        id: favorite.id,
        userId: favorite.user_id,
        restaurantId: favorite.restaurant_id,
        restaurantName: favorite.restaurant_name,
        restaurantAddress: favorite.restaurant_address,
        restaurantPhotoUrl: favorite.restaurant_photo_url,
        createdAt: favorite.created_at,
        updatedAt: favorite.created_at, // Use created_at as updated_at for now
      };
    } finally {
      client.release();
    }
  }

  // Delete a favorite
  static async deleteFavorite(id: string): Promise<boolean> {
    const client = await pool.connect();
    
    try {
      const query = 'DELETE FROM favorites WHERE id = $1';
      const result = await client.query(query, [id]);
      
      return result.rowCount > 0;
    } finally {
      client.release();
    }
  }

  // Delete favorite by user and restaurant
  static async deleteFavoriteByUserAndRestaurant(userId: string, restaurantId: string): Promise<boolean> {
    const client = await pool.connect();
    
    try {
      const query = 'DELETE FROM favorites WHERE user_id = $1 AND restaurant_id = $2';
      const result = await client.query(query, [userId, restaurantId]);
      
      return result.rowCount > 0;
    } finally {
      client.release();
    }
  }

  // Toggle favorite status (add if not exists, remove if exists)
  static async toggleFavorite(userId: string, restaurantId: string): Promise<{ isFavorited: boolean; favorite?: Favorite }> {
    const client = await pool.connect();
    
    try {
      // Check if favorite already exists
      const existingFavorite = await this.getFavoriteByUserAndRestaurant(userId, restaurantId);
      
      if (existingFavorite) {
        // Remove favorite
        await this.deleteFavorite(existingFavorite.id);
        return { isFavorited: false };
      } else {
        // Add favorite - need to create with minimal data
        const newFavorite = await this.createFavorite({ 
          userId, 
          restaurantId,
          restaurantName: '',
          restaurantAddress: ''
        });
        return { isFavorited: true, favorite: newFavorite };
      }
    } finally {
      client.release();
    }
  }

  // Get favorite count for a user
  static async getFavoriteCount(userId: string): Promise<number> {
    const client = await pool.connect();
    
    try {
      const query = 'SELECT COUNT(*) as count FROM favorites WHERE user_id = $1';
      const result = await client.query(query, [userId]);
      
      return parseInt(result.rows[0].count);
    } finally {
      client.release();
    }
  }

  // Check if restaurant is favorited (alias for isRestaurantFavorited)
  static async isFavorited(userId: string, restaurantId: string): Promise<boolean> {
    return this.isRestaurantFavorited(userId, restaurantId);
  }

  // Remove favorite (alias for deleteFavorite)
  static async removeFavorite(id: string): Promise<boolean>
  static async removeFavorite(userId: string, restaurantId: string): Promise<boolean>
  static async removeFavorite(idOrUserId: string, restaurantId?: string): Promise<boolean> {
    if (restaurantId) {
      // Called with userId and restaurantId
      return this.deleteFavoriteByUserAndRestaurant(idOrUserId, restaurantId);
    } else {
      // Called with just id
      return this.deleteFavorite(idOrUserId);
    }
  }

  // Get user favorites with details (alias for getFavoritesByUserId)
  static async getUserFavoritesWithDetails(userId: string): Promise<FavoriteWithRestaurant[]> {
    return this.getFavoritesByUserId(userId);
  }

  // Get all favorites (for admin purposes)
  static async getAllFavorites(): Promise<FavoriteWithRestaurant[]> {
    const client = await pool.connect();
    
    try {
      const query = `
        SELECT id, user_id, restaurant_id, restaurant_name, restaurant_address, restaurant_photo_url, created_at
        FROM favorites 
        ORDER BY created_at DESC
      `;
      
      const result = await client.query(query);
      
      return result.rows.map(favorite => ({
        id: favorite.id,
        userId: favorite.user_id,
        restaurantId: favorite.restaurant_id,
        restaurantName: favorite.restaurant_name,
        restaurantAddress: favorite.restaurant_address,
        restaurantPhotoUrl: favorite.restaurant_photo_url,
        createdAt: favorite.created_at,
        updatedAt: favorite.created_at, // Use created_at as updated_at for now
      }));
    } finally {
      client.release();
    }
  }
}
