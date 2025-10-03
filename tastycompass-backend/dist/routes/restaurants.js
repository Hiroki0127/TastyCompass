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
        const { query, location, radius, openNow, minRating, priceLevel, } = req.query;
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
        if (priceLevel) {
            const priceLevelNum = parseInt(priceLevel);
            filteredRestaurants = filteredRestaurants.filter(r => r.priceLevel === priceLevelNum);
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
exports.default = router;
