"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewService = void 0;
const connection_1 = __importDefault(require("../database/connection"));
const userServicePostgres_1 = require("./userServicePostgres");
class ReviewService {
    async createReview(userId, reviewData) {
        const client = await connection_1.default.connect();
        try {
            // Check if user already reviewed this restaurant
            const existingReview = await client.query('SELECT * FROM reviews WHERE user_id = $1 AND restaurant_id = $2', [userId, reviewData.restaurantId]);
            if (existingReview.rows.length > 0) {
                throw new Error('User has already reviewed this restaurant');
            }
            // Validate rating
            if (reviewData.rating < 1 || reviewData.rating > 5) {
                throw new Error('Rating must be between 1 and 5');
            }
            // Validate content
            if (!reviewData.content || reviewData.content.trim().length < 10) {
                throw new Error('Review content must be at least 10 characters');
            }
            const user = await userServicePostgres_1.UserService.findUserById(userId);
            if (!user) {
                throw new Error('User not found');
            }
            const reviewId = `review_${Date.now()}`;
            const now = new Date();
            await client.query(`INSERT INTO reviews (id, user_id, restaurant_id, rating, title, content, helpful_count, is_reported, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`, [
                reviewId,
                userId,
                reviewData.restaurantId,
                reviewData.rating,
                reviewData.title?.trim() || null,
                reviewData.content.trim(),
                0,
                false,
                now,
                now
            ]);
            const review = {
                id: reviewId,
                userId,
                restaurantId: reviewData.restaurantId,
                rating: reviewData.rating,
                title: reviewData.title?.trim(),
                content: reviewData.content.trim(),
                createdAt: now,
                updatedAt: now,
                helpfulCount: 0,
                isReported: false,
                userName: `${user.firstName} ${user.lastName}`,
                userAvatar: undefined
            };
            return review;
        }
        finally {
            client.release();
        }
    }
    async updateReview(userId, reviewId, updateData) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query('SELECT * FROM reviews WHERE id = $1', [reviewId]);
            if (result.rows.length === 0) {
                throw new Error('Review not found');
            }
            const review = result.rows[0];
            if (review.user_id !== userId) {
                throw new Error('Unauthorized to update this review');
            }
            // Validate rating if provided
            if (updateData.rating !== undefined && (updateData.rating < 1 || updateData.rating > 5)) {
                throw new Error('Rating must be between 1 and 5');
            }
            // Validate content if provided
            if (updateData.content !== undefined && updateData.content.trim().length < 10) {
                throw new Error('Review content must be at least 10 characters');
            }
            const user = await userServicePostgres_1.UserService.findUserById(userId);
            const updateFields = [];
            const values = [];
            let paramIndex = 1;
            if (updateData.rating !== undefined) {
                updateFields.push(`rating = $${paramIndex++}`);
                values.push(updateData.rating);
            }
            if (updateData.title !== undefined) {
                updateFields.push(`title = $${paramIndex++}`);
                values.push(updateData.title.trim() || null);
            }
            if (updateData.content !== undefined) {
                updateFields.push(`content = $${paramIndex++}`);
                values.push(updateData.content.trim());
            }
            values.push(reviewId);
            await client.query(`UPDATE reviews SET ${updateFields.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = $${paramIndex}`, values);
            const updatedResult = await client.query('SELECT * FROM reviews WHERE id = $1', [reviewId]);
            const updatedRow = updatedResult.rows[0];
            return {
                id: updatedRow.id,
                userId: updatedRow.user_id,
                restaurantId: updatedRow.restaurant_id,
                rating: updatedRow.rating,
                title: updatedRow.title,
                content: updatedRow.content,
                createdAt: updatedRow.created_at,
                updatedAt: updatedRow.updated_at,
                helpfulCount: updatedRow.helpful_count,
                isReported: updatedRow.is_reported,
                userName: user ? `${user.firstName} ${user.lastName}` : 'Unknown User',
                userAvatar: undefined
            };
        }
        finally {
            client.release();
        }
    }
    async deleteReview(userId, reviewId) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query('SELECT * FROM reviews WHERE id = $1', [reviewId]);
            if (result.rows.length === 0) {
                throw new Error('Review not found');
            }
            if (result.rows[0].user_id !== userId) {
                throw new Error('Unauthorized to delete this review');
            }
            await client.query('DELETE FROM reviews WHERE id = $1', [reviewId]);
        }
        finally {
            client.release();
        }
    }
    async getUserReview(userId, restaurantId) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query('SELECT r.*, u.name as user_name FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.user_id = $1 AND r.restaurant_id = $2', [userId, restaurantId]);
            if (result.rows.length === 0) {
                return null;
            }
            const row = result.rows[0];
            return {
                id: row.id,
                userId: row.user_id,
                restaurantId: row.restaurant_id,
                rating: row.rating,
                title: row.title,
                content: row.content,
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                helpfulCount: row.helpful_count,
                isReported: row.is_reported,
                userName: row.user_name,
                userAvatar: undefined
            };
        }
        finally {
            client.release();
        }
    }
    async getReviewsForRestaurant(restaurantId, limit = 10, offset = 0) {
        const client = await connection_1.default.connect();
        try {
            // Get total count
            const countResult = await client.query('SELECT COUNT(*) as total FROM reviews WHERE restaurant_id = $1 AND is_reported = false', [restaurantId]);
            const total = parseInt(countResult.rows[0].total);
            // Get paginated reviews
            const result = await client.query(`SELECT r.*, u.name as user_name 
         FROM reviews r 
         JOIN users u ON r.user_id = u.id 
         WHERE r.restaurant_id = $1 AND r.is_reported = false 
         ORDER BY r.created_at DESC 
         LIMIT $2 OFFSET $3`, [restaurantId, limit, offset]);
            const reviews = result.rows.map(row => ({
                id: row.id,
                userId: row.user_id,
                restaurantId: row.restaurant_id,
                rating: row.rating,
                title: row.title,
                content: row.content,
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                helpfulCount: row.helpful_count,
                isReported: row.is_reported,
                userName: row.user_name,
                userAvatar: undefined
            }));
            // Calculate average rating
            const avgResult = await client.query('SELECT AVG(rating) as avg_rating FROM reviews WHERE restaurant_id = $1 AND is_reported = false', [restaurantId]);
            const averageRating = avgResult.rows[0].avg_rating ? Number(parseFloat(avgResult.rows[0].avg_rating).toFixed(1)) : 0;
            return {
                reviews,
                total,
                averageRating,
                totalRatings: total
            };
        }
        finally {
            client.release();
        }
    }
    async getUserReviews(userId, limit = 20, offset = 0) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query(`SELECT r.*, u.name as user_name 
         FROM reviews r 
         JOIN users u ON r.user_id = u.id 
         WHERE r.user_id = $1 
         ORDER BY r.created_at DESC 
         LIMIT $2 OFFSET $3`, [userId, limit, offset]);
            return result.rows.map(row => ({
                id: row.id,
                userId: row.user_id,
                restaurantId: row.restaurant_id,
                rating: row.rating,
                title: row.title,
                content: row.content,
                createdAt: row.created_at,
                updatedAt: row.updated_at,
                helpfulCount: row.helpful_count,
                isReported: row.is_reported,
                userName: row.user_name,
                userAvatar: undefined
            }));
        }
        finally {
            client.release();
        }
    }
    async markReviewHelpful(reviewId) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query('UPDATE reviews SET helpful_count = helpful_count + 1 WHERE id = $1 RETURNING helpful_count', [reviewId]);
            if (result.rows.length === 0) {
                throw new Error('Review not found');
            }
            return result.rows[0].helpful_count;
        }
        finally {
            client.release();
        }
    }
    async reportReview(reviewId) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query('UPDATE reviews SET is_reported = true WHERE id = $1', [reviewId]);
            if (result.rowCount === 0) {
                throw new Error('Review not found');
            }
        }
        finally {
            client.release();
        }
    }
    async getReviewStats(restaurantId) {
        const client = await connection_1.default.connect();
        try {
            const result = await client.query(`SELECT 
          AVG(rating) as avg_rating,
          COUNT(*) as total,
          SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) as five_star,
          SUM(CASE WHEN rating = 4 THEN 1 ELSE 0 END) as four_star,
          SUM(CASE WHEN rating = 3 THEN 1 ELSE 0 END) as three_star,
          SUM(CASE WHEN rating = 2 THEN 1 ELSE 0 END) as two_star,
          SUM(CASE WHEN rating = 1 THEN 1 ELSE 0 END) as one_star
         FROM reviews 
         WHERE restaurant_id = $1 AND is_reported = false`, [restaurantId]);
            const row = result.rows[0];
            const total = parseInt(row.total);
            const averageRating = row.avg_rating ? Number(parseFloat(row.avg_rating).toFixed(1)) : 0;
            return {
                averageRating,
                totalRatings: total,
                ratingDistribution: {
                    5: parseInt(row.five_star || 0),
                    4: parseInt(row.four_star || 0),
                    3: parseInt(row.three_star || 0),
                    2: parseInt(row.two_star || 0),
                    1: parseInt(row.one_star || 0)
                }
            };
        }
        finally {
            client.release();
        }
    }
}
exports.ReviewService = ReviewService;
