"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const googlePlacesService_1 = require("../services/googlePlacesService");
const router = express_1.default.Router();
// Initialize Google Places service
const googlePlacesService = new googlePlacesService_1.GooglePlacesService(process.env.GOOGLE_PLACES_API_KEY || '');
// GET /api/restaurants/search
router.get('/search', async (req, res) => {
    try {
        const { query, location, radius, openNow, minRating, priceLevel, minPrice, maxPrice, } = req.query;
        // Validate required parameters
        if (!location) {
            return res.status(400).json({
                error: 'Location parameter is required (format: "latitude,longitude")'
            });
        }
        // Search for restaurants
        const restaurants = await googlePlacesService.searchRestaurants({
            location: location,
            radius: radius ? parseInt(radius) : 5000,
            keyword: query,
            type: 'restaurant',
            openNow: openNow === 'true',
        });
        // Apply client-side filters
        let filteredRestaurants = restaurants;
        if (minRating) {
            const minRatingNum = parseFloat(minRating);
            filteredRestaurants = filteredRestaurants.filter(r => r.rating && r.rating >= minRatingNum);
        }
        // Handle price filtering - support both single price level and range
        if (priceLevel) {
            const priceLevelNum = parseInt(priceLevel);
            filteredRestaurants = filteredRestaurants.filter(r => r.priceLevel === priceLevelNum);
        }
        else if (minPrice || maxPrice) {
            const minPriceNum = minPrice ? parseInt(minPrice) : 1;
            const maxPriceNum = maxPrice ? parseInt(maxPrice) : 4;
            filteredRestaurants = filteredRestaurants.filter(r => {
                if (!r.priceLevel)
                    return false;
                return r.priceLevel >= minPriceNum && r.priceLevel <= maxPriceNum;
            });
        }
        res.json({
            restaurants: filteredRestaurants,
            totalResults: filteredRestaurants.length,
        });
    }
    catch (error) {
        console.error('Restaurant search error:', error);
        res.status(500).json({
            error: 'Failed to search restaurants',
            message: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// GET /api/restaurants/:id
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        if (!id) {
            return res.status(400).json({
                error: 'Restaurant ID is required'
            });
        }
        // Get restaurant details
        const restaurant = await googlePlacesService.getRestaurantDetails(id);
        res.json({
            restaurant
        });
    }
    catch (error) {
        console.error('Restaurant details error:', error);
        res.status(500).json({
            error: 'Failed to get restaurant details',
            message: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
// GET /api/restaurants/:id/google-reviews
router.get('/:id/google-reviews', async (req, res) => {
    try {
        const { id } = req.params;
        const { page = 1, limit = 10 } = req.query;
        if (!id) {
            return res.status(400).json({
                error: 'Restaurant ID is required'
            });
        }
        // Get restaurant details with Google reviews
        const restaurant = await googlePlacesService.getRestaurantDetails(id);
        const allReviews = restaurant.reviews || [];
        const pageNum = parseInt(page) || 1;
        const limitNum = Math.min(parseInt(limit) || 10, 20); // Max 20 per page
        // Calculate pagination
        const startIndex = (pageNum - 1) * limitNum;
        const endIndex = startIndex + limitNum;
        // Get paginated reviews
        const paginatedReviews = allReviews
            .slice(startIndex, endIndex)
            .map(review => ({
            ...review,
            text: review.text.length > 200 ?
                review.text.substring(0, 200) + '...' :
                review.text
        }));
        const totalPages = Math.ceil(allReviews.length / limitNum);
        res.json({
            reviews: paginatedReviews,
            totalReviews: allReviews.length,
            averageRating: restaurant.rating,
            totalRatings: restaurant.totalRatings || 0,
            pagination: {
                currentPage: pageNum,
                totalPages: totalPages,
                hasNextPage: pageNum < totalPages,
                hasPrevPage: pageNum > 1,
                limit: limitNum
            }
        });
    }
    catch (error) {
        console.error('Google reviews error:', error);
        res.status(500).json({
            error: 'Failed to get Google reviews',
            message: error instanceof Error ? error.message : 'Unknown error'
        });
    }
});
exports.default = router;
