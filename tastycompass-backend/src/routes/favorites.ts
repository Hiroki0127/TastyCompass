import { Router, Request, Response } from 'express';
import { FavoriteService } from '../services/serviceFactory';
import { authenticateToken, optionalAuth } from '../middleware/auth';

const router = Router();

// Get user's favorites (requires authentication)
router.get('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    // Get favorites with restaurant details
    const favorites = await FavoriteService.getUserFavoritesWithDetails(userId);

    res.json({
      message: 'Favorites retrieved successfully',
      favorites,
      count: favorites.length,
    });
  } catch (error: any) {
    console.error('Get favorites error:', error);
    res.status(500).json({ 
      error: 'Failed to get favorites',
      message: error.message 
    });
  }
});

// Get user's favorite count (requires authentication)
router.get('/count', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    const count = await FavoriteService.getFavoriteCount(userId);

    res.json({
      count,
    });
  } catch (error: any) {
    console.error('Get favorite count error:', error);
    res.status(500).json({ 
      error: 'Failed to get favorite count',
      message: error.message 
    });
  }
});

// Check if restaurant is favorited (optional auth - returns false if not authenticated)
router.get('/check/:restaurantId', optionalAuth, async (req: Request, res: Response) => {
  try {
    const { restaurantId } = req.params;
    const userId = (req as any).user?.id;

    if (!userId) {
      // User not authenticated, return false
      return res.json({
        isFavorited: false,
      });
    }

    const isFavorited = await FavoriteService.isFavorited(userId, restaurantId);

    res.json({
      isFavorited,
    });
  } catch (error: any) {
    console.error('Check favorite error:', error);
    res.status(500).json({ 
      error: 'Failed to check favorite status',
      message: error.message 
    });
  }
});

// Add restaurant to favorites (requires authentication)
router.post('/', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    const { 
      restaurantId, 
      restaurantName, 
      restaurantAddress, 
      restaurantRating, 
      restaurantPriceLevel, 
      restaurantPhotoUrl 
    } = req.body;

    // Validate required fields
    if (!restaurantId || !restaurantName || !restaurantAddress) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        message: 'restaurantId, restaurantName, and restaurantAddress are required'
      });
    }

    // Create favorite
    const favorite = await FavoriteService.createFavorite({
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
  } catch (error: any) {
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
router.delete('/:restaurantId', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
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
    const removed = await FavoriteService.removeFavorite(userId, restaurantId);

    if (!removed) {
      return res.status(404).json({ 
        error: 'Favorite not found' 
      });
    }

    res.json({
      message: 'Restaurant removed from favorites',
    });
  } catch (error: any) {
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
router.post('/toggle', authenticateToken, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).user?.id;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Not authenticated' 
      });
    }

    const { 
      restaurantId, 
      restaurantName, 
      restaurantAddress, 
      restaurantRating, 
      restaurantPriceLevel, 
      restaurantPhotoUrl 
    } = req.body;

    // Validate required fields
    if (!restaurantId || !restaurantName || !restaurantAddress) {
      return res.status(400).json({ 
        error: 'Missing required fields',
        message: 'restaurantId, restaurantName, and restaurantAddress are required'
      });
    }

    // Check if already favorited
    const isFavorited = await FavoriteService.isFavorited(userId, restaurantId);

    if (isFavorited) {
      // Remove from favorites
      await FavoriteService.removeFavorite(userId, restaurantId);
      res.json({
        message: 'Restaurant removed from favorites',
        isFavorited: false,
      });
    } else {
      // Add to favorites
      const favorite = await FavoriteService.createFavorite({
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
  } catch (error: any) {
    console.error('Toggle favorite error:', error);
    res.status(500).json({ 
      error: 'Failed to toggle favorite',
      message: error.message 
    });
  }
});

export default router;
