"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FavoriteService = void 0;
const googlePlacesService_1 = require("./googlePlacesService");
// In-memory storage for now (we'll replace with database later)
class FavoriteStorage {
    constructor() {
        this.favorites = new Map();
        this.userFavoritesIndex = new Map(); // userId -> Set of favoriteIds
        this.restaurantFavoritesIndex = new Map(); // restaurantId -> Set of favoriteIds
    }
    create(favorite) {
        this.favorites.set(favorite.id, favorite);
        // Update user index
        if (!this.userFavoritesIndex.has(favorite.userId)) {
            this.userFavoritesIndex.set(favorite.userId, new Set());
        }
        this.userFavoritesIndex.get(favorite.userId).add(favorite.id);
        // Update restaurant index
        if (!this.restaurantFavoritesIndex.has(favorite.restaurantId)) {
            this.restaurantFavoritesIndex.set(favorite.restaurantId, new Set());
        }
        this.restaurantFavoritesIndex.get(favorite.restaurantId).add(favorite.id);
    }
    findById(id) {
        return this.favorites.get(id);
    }
    findByUserId(userId) {
        const favoriteIds = this.userFavoritesIndex.get(userId);
        if (!favoriteIds)
            return [];
        return Array.from(favoriteIds)
            .map(id => this.favorites.get(id))
            .filter((favorite) => favorite !== undefined)
            .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime()); // Most recent first
    }
    findByUserAndRestaurant(userId, restaurantId) {
        const favoriteIds = this.userFavoritesIndex.get(userId);
        if (!favoriteIds)
            return undefined;
        for (const favoriteId of favoriteIds) {
            const favorite = this.favorites.get(favoriteId);
            if (favorite && favorite.restaurantId === restaurantId) {
                return favorite;
            }
        }
        return undefined;
    }
    delete(id) {
        const favorite = this.favorites.get(id);
        if (!favorite)
            return false;
        this.favorites.delete(id);
        // Update user index
        const userFavorites = this.userFavoritesIndex.get(favorite.userId);
        if (userFavorites) {
            userFavorites.delete(id);
            if (userFavorites.size === 0) {
                this.userFavoritesIndex.delete(favorite.userId);
            }
        }
        // Update restaurant index
        const restaurantFavorites = this.restaurantFavoritesIndex.get(favorite.restaurantId);
        if (restaurantFavorites) {
            restaurantFavorites.delete(id);
            if (restaurantFavorites.size === 0) {
                this.restaurantFavoritesIndex.delete(favorite.restaurantId);
            }
        }
        return true;
    }
    exists(userId, restaurantId) {
        return this.findByUserAndRestaurant(userId, restaurantId) !== undefined;
    }
    getCountByUser(userId) {
        const favoriteIds = this.userFavoritesIndex.get(userId);
        return favoriteIds ? favoriteIds.size : 0;
    }
    getAllFavorites() {
        return Array.from(this.favorites.values());
    }
}
const favoriteStorage = new FavoriteStorage();
class FavoriteService {
    // Generate unique ID
    static generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2);
    }
    // Create new favorite
    static async createFavorite(favoriteData) {
        // Check if favorite already exists
        if (favoriteStorage.exists(favoriteData.userId, favoriteData.restaurantId)) {
            throw new Error('Restaurant is already in favorites');
        }
        const favorite = {
            id: this.generateId(),
            userId: favoriteData.userId,
            restaurantId: favoriteData.restaurantId,
            restaurantName: favoriteData.restaurantName,
            restaurantAddress: favoriteData.restaurantAddress,
            restaurantRating: favoriteData.restaurantRating,
            restaurantPriceLevel: favoriteData.restaurantPriceLevel,
            restaurantPhotoUrl: favoriteData.restaurantPhotoUrl,
            createdAt: new Date(),
            updatedAt: new Date(),
        };
        favoriteStorage.create(favorite);
        return favorite;
    }
    // Get user's favorites
    static async getUserFavorites(userId) {
        return favoriteStorage.findByUserId(userId);
    }
    // Get user's favorites with restaurant details
    static async getUserFavoritesWithDetails(userId) {
        const favorites = favoriteStorage.findByUserId(userId);
        const favoritesWithDetails = [];
        for (const favorite of favorites) {
            try {
                // Get restaurant details from Google Places API
                const restaurantDetails = await this.googlePlacesService.getRestaurantDetails(favorite.restaurantId);
                const favoriteWithRestaurant = {
                    ...favorite,
                    restaurant: {
                        id: restaurantDetails.id,
                        name: restaurantDetails.name,
                        address: restaurantDetails.address,
                        rating: restaurantDetails.rating,
                        priceLevel: restaurantDetails.priceLevel,
                        photos: restaurantDetails.photos?.map(photo => ({
                            id: photo.id,
                            url: photo.url,
                        })),
                        location: restaurantDetails.location,
                    },
                };
                favoritesWithDetails.push(favoriteWithRestaurant);
            }
            catch (error) {
                console.error(`Failed to fetch details for restaurant ${favorite.restaurantId}:`, error);
                // Add favorite without restaurant details if API call fails
                favoritesWithDetails.push({
                    ...favorite,
                    restaurant: undefined,
                });
            }
        }
        return favoritesWithDetails;
    }
    // Remove favorite
    static async removeFavorite(userId, restaurantId) {
        const favorite = favoriteStorage.findByUserAndRestaurant(userId, restaurantId);
        if (!favorite) {
            throw new Error('Favorite not found');
        }
        return favoriteStorage.delete(favorite.id);
    }
    // Check if restaurant is favorited by user
    static async isFavorited(userId, restaurantId) {
        return favoriteStorage.exists(userId, restaurantId);
    }
    // Get favorite count for user
    static async getFavoriteCount(userId) {
        return favoriteStorage.getCountByUser(userId);
    }
    // Get all favorites (for debugging)
    static async getAllFavorites() {
        return favoriteStorage.getAllFavorites();
    }
}
exports.FavoriteService = FavoriteService;
FavoriteService.googlePlacesService = new googlePlacesService_1.GooglePlacesService(process.env.GOOGLE_PLACES_API_KEY || '');
