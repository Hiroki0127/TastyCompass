"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const serviceFactory_1 = require("../services/serviceFactory");
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
// Get user's favorites (requires authentication)
router.get('/', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        // Get favorites with restaurant details
        const favorites = await serviceFactory_1.FavoriteService.getUserFavoritesWithDetails(userId);
        res.json({
            message: 'Favorites retrieved successfully',
            favorites,
            count: favorites.length,
        });
    }
    catch (error) {
        console.error('Get favorites error:', error);
        res.status(500).json({
            error: 'Failed to get favorites',
            message: error.message
        });
    }
});
// Get user's favorite count (requires authentication)
router.get('/count', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        const count = await serviceFactory_1.FavoriteService.getFavoriteCount(userId);
        res.json({
            count,
        });
    }
    catch (error) {
        console.error('Get favorite count error:', error);
        res.status(500).json({
            error: 'Failed to get favorite count',
            message: error.message
        });
    }
});
// Check if restaurant is favorited (optional auth - returns false if not authenticated)
router.get('/check/:restaurantId', auth_1.optionalAuth, async (req, res) => {
    try {
        const { restaurantId } = req.params;
        const userId = req.user?.id;
        if (!userId) {
            // User not authenticated, return false
            return res.json({
                isFavorited: false,
            });
        }
        const isFavorited = await serviceFactory_1.FavoriteService.isFavorited(userId, restaurantId);
        res.json({
            isFavorited,
        });
    }
    catch (error) {
        console.error('Check favorite error:', error);
        res.status(500).json({
            error: 'Failed to check favorite status',
            message: error.message
        });
    }
});
// Add restaurant to favorites (requires authentication)
router.post('/', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        const { restaurantId, restaurantName, restaurantAddress, restaurantRating, restaurantPriceLevel, restaurantPhotoUrl } = req.body;
        // Validate required fields
        if (!restaurantId || !restaurantName || !restaurantAddress) {
            return res.status(400).json({
                error: 'Missing required fields',
                message: 'restaurantId, restaurantName, and restaurantAddress are required'
            });
        }
        // Create favorite
        const favorite = await serviceFactory_1.FavoriteService.createFavorite({
            userId,
            restaurantId,
            restaurantName,
            restaurantAddress,
            restaurantRating,
            restaurantPriceLevel,
            restaurantPhotoUrl,
        });
        res.status(201).json({
            message: 'Restaurant added to favorites',
            favorite,
        });
    }
    catch (error) {
        console.error('Add favorite error:', error);
        if (error.message === 'Restaurant is already in favorites') {
            return res.status(409).json({
                error: 'Already favorited',
                message: error.message
            });
        }
        res.status(500).json({
            error: 'Failed to add favorite',
            message: error.message
        });
    }
});
// Remove restaurant from favorites (requires authentication)
router.delete('/:restaurantId', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        const { restaurantId } = req.params;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        if (!restaurantId) {
            return res.status(400).json({
                error: 'Missing restaurant ID'
            });
        }
        // Remove favorite
        const removed = await serviceFactory_1.FavoriteService.removeFavorite(userId, restaurantId);
        if (!removed) {
            return res.status(404).json({
                error: 'Favorite not found'
            });
        }
        res.json({
            message: 'Restaurant removed from favorites',
        });
    }
    catch (error) {
        console.error('Remove favorite error:', error);
        if (error.message === 'Favorite not found') {
            return res.status(404).json({
                error: 'Favorite not found',
                message: error.message
            });
        }
        res.status(500).json({
            error: 'Failed to remove favorite',
            message: error.message
        });
    }
});
// Toggle favorite status (requires authentication)
router.post('/toggle', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({
                error: 'Not authenticated'
            });
        }
        const { restaurantId, restaurantName, restaurantAddress, restaurantRating, restaurantPriceLevel, restaurantPhotoUrl } = req.body;
        // Validate required fields
        if (!restaurantId || !restaurantName || !restaurantAddress) {
            return res.status(400).json({
                error: 'Missing required fields',
                message: 'restaurantId, restaurantName, and restaurantAddress are required'
            });
        }
        // Check if already favorited
        const isFavorited = await serviceFactory_1.FavoriteService.isFavorited(userId, restaurantId);
        if (isFavorited) {
            // Remove from favorites
            await serviceFactory_1.FavoriteService.removeFavorite(userId, restaurantId);
            res.json({
                message: 'Restaurant removed from favorites',
                isFavorited: false,
            });
        }
        else {
            // Add to favorites
            const favorite = await serviceFactory_1.FavoriteService.createFavorite({
                userId,
                restaurantId,
                restaurantName,
                restaurantAddress,
                restaurantRating,
                restaurantPriceLevel,
                restaurantPhotoUrl,
            });
            res.status(201).json({
                message: 'Restaurant added to favorites',
                isFavorited: true,
                favorite,
            });
        }
    }
    catch (error) {
        console.error('Toggle favorite error:', error);
        res.status(500).json({
            error: 'Failed to toggle favorite',
            message: error.message
        });
    }
});
exports.default = router;
