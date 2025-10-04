import express from 'express';
import { GooglePlacesService } from '../services/googlePlacesService';
import { RestaurantSearchRequest, RestaurantDetailsRequest } from '../types/restaurant';

const router = express.Router();

// Initialize Google Places service
const googlePlacesService = new GooglePlacesService(process.env.GOOGLE_PLACES_API_KEY || '');

// GET /api/restaurants/search
router.get('/search', async (req, res) => {
  try {
    const {
      query,
      location,
      radius,
      openNow,
      minRating,
      priceLevel,
      minPrice,
      maxPrice,
    } = req.query;

    // Validate required parameters
    if (!location) {
      return res.status(400).json({
        error: 'Location parameter is required (format: "latitude,longitude")'
      });
    }

    // Search for restaurants
    const restaurants = await googlePlacesService.searchRestaurants({
      location: location as string,
      radius: radius ? parseInt(radius as string) : 5000,
      keyword: query as string,
      type: 'restaurant',
      openNow: openNow === 'true',
    });

    // Apply client-side filters
    let filteredRestaurants = restaurants;

    if (minRating) {
      const minRatingNum = parseFloat(minRating as string);
      filteredRestaurants = filteredRestaurants.filter(r => r.rating && r.rating >= minRatingNum);
    }

    // Handle price filtering - support both single price level and range
    if (priceLevel) {
      const priceLevelNum = parseInt(priceLevel as string);
      filteredRestaurants = filteredRestaurants.filter(r => r.priceLevel === priceLevelNum);
    } else if (minPrice || maxPrice) {
      const minPriceNum = minPrice ? parseInt(minPrice as string) : 1;
      const maxPriceNum = maxPrice ? parseInt(maxPrice as string) : 4;
      filteredRestaurants = filteredRestaurants.filter(r => {
        if (!r.priceLevel) return false;
        return r.priceLevel >= minPriceNum && r.priceLevel <= maxPriceNum;
      });
    }

    res.json({
      restaurants: filteredRestaurants,
      totalResults: filteredRestaurants.length,
    });

  } catch (error) {
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

  } catch (error) {
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

    if (!id) {
      return res.status(400).json({
        error: 'Restaurant ID is required'
      });
    }

    // Get restaurant details with Google reviews
    const restaurant = await googlePlacesService.getRestaurantDetails(id);

    res.json({
      reviews: restaurant.reviews || [],
      totalReviews: restaurant.reviews?.length || 0,
      averageRating: restaurant.rating,
      totalRatings: restaurant.totalRatings || 0
    });

  } catch (error) {
    console.error('Google reviews error:', error);
    res.status(500).json({
      error: 'Failed to get Google reviews',
      message: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default router;
