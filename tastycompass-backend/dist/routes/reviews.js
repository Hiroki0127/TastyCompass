"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const reviewService_1 = require("../services/reviewService");
const auth_1 = require("../middleware/auth");
const router = express_1.default.Router();
const reviewService = new reviewService_1.ReviewService();
// Get reviews for a specific restaurant
router.get('/restaurant/:restaurantId', async (req, res) => {
    try {
        const { restaurantId } = req.params;
        const { limit = '20', offset = '0' } = req.query;
        const reviewsResponse = reviewService.getReviewsForRestaurant(restaurantId, parseInt(limit), parseInt(offset));
        res.json(reviewsResponse);
    }
    catch (error) {
        console.error('Error getting reviews:', error);
        res.status(500).json({ error: 'Failed to get reviews' });
    }
});
// Get user's reviews
router.get('/user', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const { limit = '20', offset = '0' } = req.query;
        const reviews = reviewService.getUserReviews(userId, parseInt(limit), parseInt(offset));
        res.json({ reviews });
    }
    catch (error) {
        console.error('Error getting user reviews:', error);
        res.status(500).json({ error: 'Failed to get user reviews' });
    }
});
// Get user's review for a specific restaurant
router.get('/restaurant/:restaurantId/user', auth_1.authenticateToken, async (req, res) => {
    try {
        const { restaurantId } = req.params;
        const userId = req.user.id;
        const review = reviewService.getUserReview(userId, restaurantId);
        if (!review) {
            return res.status(404).json({ error: 'Review not found' });
        }
        res.json({ review });
    }
    catch (error) {
        console.error('Error getting user review:', error);
        res.status(500).json({ error: 'Failed to get user review' });
    }
});
// Create a new review
router.post('/', auth_1.authenticateToken, async (req, res) => {
    try {
        const userId = req.user.id;
        const reviewData = req.body;
        const review = await reviewService.createReview(userId, reviewData);
        res.status(201).json({
            review,
            message: 'Review created successfully'
        });
    }
    catch (error) {
        console.error('Error creating review:', error);
        if (error instanceof Error) {
            if (error.message.includes('already reviewed')) {
                return res.status(409).json({ error: error.message });
            }
            if (error.message.includes('must be between') || error.message.includes('at least 10 characters')) {
                return res.status(400).json({ error: error.message });
            }
        }
        res.status(500).json({ error: 'Failed to create review' });
    }
});
// Update a review
router.put('/:reviewId', auth_1.authenticateToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const userId = req.user.id;
        const updateData = req.body;
        const review = await reviewService.updateReview(userId, reviewId, updateData);
        res.json({
            review,
            message: 'Review updated successfully'
        });
    }
    catch (error) {
        console.error('Error updating review:', error);
        if (error instanceof Error) {
            if (error.message.includes('not found')) {
                return res.status(404).json({ error: error.message });
            }
            if (error.message.includes('Unauthorized')) {
                return res.status(403).json({ error: error.message });
            }
            if (error.message.includes('must be between') || error.message.includes('at least 10 characters')) {
                return res.status(400).json({ error: error.message });
            }
        }
        res.status(500).json({ error: 'Failed to update review' });
    }
});
// Delete a review
router.delete('/:reviewId', auth_1.authenticateToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        const userId = req.user.id;
        await reviewService.deleteReview(userId, reviewId);
        res.json({ message: 'Review deleted successfully' });
    }
    catch (error) {
        console.error('Error deleting review:', error);
        if (error instanceof Error) {
            if (error.message.includes('not found')) {
                return res.status(404).json({ error: error.message });
            }
            if (error.message.includes('Unauthorized')) {
                return res.status(403).json({ error: error.message });
            }
        }
        res.status(500).json({ error: 'Failed to delete review' });
    }
});
// Mark a review as helpful
router.post('/:reviewId/helpful', async (req, res) => {
    try {
        const { reviewId } = req.params;
        const helpfulCount = await reviewService.markReviewHelpful(reviewId);
        res.json({ helpfulCount });
    }
    catch (error) {
        console.error('Error marking review helpful:', error);
        if (error instanceof Error && error.message.includes('not found')) {
            return res.status(404).json({ error: error.message });
        }
        res.status(500).json({ error: 'Failed to mark review helpful' });
    }
});
// Report a review
router.post('/:reviewId/report', auth_1.authenticateToken, async (req, res) => {
    try {
        const { reviewId } = req.params;
        await reviewService.reportReview(reviewId);
        res.json({ message: 'Review reported successfully' });
    }
    catch (error) {
        console.error('Error reporting review:', error);
        if (error instanceof Error && error.message.includes('not found')) {
            return res.status(404).json({ error: error.message });
        }
        res.status(500).json({ error: 'Failed to report review' });
    }
});
// Get review statistics for a restaurant
router.get('/restaurant/:restaurantId/stats', async (req, res) => {
    try {
        const { restaurantId } = req.params;
        const stats = reviewService.getReviewStats(restaurantId);
        res.json(stats);
    }
    catch (error) {
        console.error('Error getting review stats:', error);
        res.status(500).json({ error: 'Failed to get review statistics' });
    }
});
exports.default = router;
