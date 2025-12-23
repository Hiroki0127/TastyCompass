"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReviewService = void 0;
const userService_1 = require("./userService");
class ReviewService {
    constructor() {
        this.reviews = new Map();
        // Add some sample reviews for testing (async)
        this.addSampleReviews().catch(error => {
            console.log('Failed to add sample reviews:', error.message);
        });
    }
    async addSampleReviews() {
        // Get the current demo user ID from UserService
        const demoUser = await userService_1.UserService.findUserByEmail('demo@tastycompass.com');
        if (!demoUser) {
            console.log('Demo user not found, skipping sample reviews');
            return;
        }
        const sampleReviews = [
            {
                id: 'review_1',
                userId: demoUser.id,
                restaurantId: 'ChIJK08gKtR_j4ARKyo5suJ6o2I',
                rating: 5,
                title: 'Amazing food!',
                content: 'The pasta was incredible and the service was excellent. Highly recommend!',
                createdAt: new Date('2024-09-20'),
                updatedAt: new Date('2024-09-20'),
                helpfulCount: 3,
                isReported: false,
                userName: 'Demo User',
                userAvatar: undefined
            },
            {
                id: 'review_2',
                userId: demoUser.id,
                restaurantId: 'ChIJNy8VmmGAhYARQF84_9twEc4',
                rating: 4,
                title: 'Good experience',
                content: 'Nice atmosphere and decent food. Could be better but overall good.',
                createdAt: new Date('2024-09-18'),
                updatedAt: new Date('2024-09-18'),
                helpfulCount: 1,
                isReported: false,
                userName: 'Demo User',
                userAvatar: undefined
            },
            {
                id: 'review_3',
                userId: demoUser.id,
                restaurantId: 'ChIJE5T3YoqAhYARtxUohSbFVDc',
                rating: 3,
                title: 'Average place',
                content: 'Food was okay but nothing special. Service was slow.',
                createdAt: new Date('2024-09-15'),
                updatedAt: new Date('2024-09-15'),
                helpfulCount: 0,
                isReported: false,
                userName: 'Demo User',
                userAvatar: undefined
            }
        ];
        sampleReviews.forEach(review => {
            this.reviews.set(review.id, review);
        });
    }
    async createReview(userId, reviewData) {
        // Check if user already reviewed this restaurant
        const existingReview = this.getUserReview(userId, reviewData.restaurantId);
        if (existingReview) {
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
        const user = await userService_1.UserService.findUserById(userId);
        if (!user) {
            throw new Error('User not found');
        }
        const review = {
            id: `review_${Date.now()}`,
            userId,
            restaurantId: reviewData.restaurantId,
            rating: reviewData.rating,
            title: reviewData.title?.trim(),
            content: reviewData.content.trim(),
            createdAt: new Date(),
            updatedAt: new Date(),
            helpfulCount: 0,
            isReported: false,
            userName: `${user.firstName} ${user.lastName}`,
            userAvatar: undefined
        };
        this.reviews.set(review.id, review);
        return review;
    }
    async updateReview(userId, reviewId, updateData) {
        const review = this.reviews.get(reviewId);
        if (!review) {
            throw new Error('Review not found');
        }
        if (review.userId !== userId) {
            throw new Error('Unauthorized to update this review');
        }
        // Validate rating if provided
        if (updateData.rating !== undefined && (updateData.rating < 1 || updateData.rating > 5)) {
            throw new Error('Rating must be between 1 and 5');
        }
        // Validate content if provided
        if (updateData.content !== undefined && (!updateData.content || updateData.content.trim().length < 10)) {
            throw new Error('Review content must be at least 10 characters');
        }
        const updatedReview = {
            ...review,
            rating: updateData.rating ?? review.rating,
            title: updateData.title?.trim() ?? review.title,
            content: updateData.content?.trim() ?? review.content,
            updatedAt: new Date()
        };
        this.reviews.set(reviewId, updatedReview);
        return updatedReview;
    }
    async deleteReview(userId, reviewId) {
        const review = this.reviews.get(reviewId);
        if (!review) {
            throw new Error('Review not found');
        }
        if (review.userId !== userId) {
            throw new Error('Unauthorized to delete this review');
        }
        this.reviews.delete(reviewId);
    }
    getUserReview(userId, restaurantId) {
        for (const review of this.reviews.values()) {
            if (review.userId === userId && review.restaurantId === restaurantId) {
                return review;
            }
        }
        return null;
    }
    getReviewsForRestaurant(restaurantId, limit = 20, offset = 0) {
        const restaurantReviews = Array.from(this.reviews.values())
            .filter(review => review.restaurantId === restaurantId && !review.isReported)
            .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
        const total = restaurantReviews.length;
        const paginatedReviews = restaurantReviews.slice(offset, offset + limit);
        const averageRating = restaurantReviews.length > 0
            ? restaurantReviews.reduce((sum, review) => sum + review.rating, 0) / restaurantReviews.length
            : 0;
        return {
            reviews: paginatedReviews,
            total,
            averageRating: Number(averageRating.toFixed(1)),
            totalRatings: total
        };
    }
    getUserReviews(userId, limit = 20, offset = 0) {
        return Array.from(this.reviews.values())
            .filter(review => review.userId === userId)
            .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
            .slice(offset, offset + limit);
    }
    async markReviewHelpful(reviewId) {
        const review = this.reviews.get(reviewId);
        if (!review) {
            throw new Error('Review not found');
        }
        const updatedReview = {
            ...review,
            helpfulCount: review.helpfulCount + 1
        };
        this.reviews.set(reviewId, updatedReview);
        return updatedReview.helpfulCount;
    }
    async reportReview(reviewId) {
        const review = this.reviews.get(reviewId);
        if (!review) {
            throw new Error('Review not found');
        }
        const updatedReview = {
            ...review,
            isReported: true
        };
        this.reviews.set(reviewId, updatedReview);
    }
    getReviewById(reviewId) {
        return this.reviews.get(reviewId) || null;
    }
    getAllReviews() {
        return Array.from(this.reviews.values());
    }
    getReviewStats(restaurantId) {
        const restaurantReviews = Array.from(this.reviews.values())
            .filter(review => review.restaurantId === restaurantId && !review.isReported);
        const totalRatings = restaurantReviews.length;
        const averageRating = totalRatings > 0
            ? restaurantReviews.reduce((sum, review) => sum + review.rating, 0) / totalRatings
            : 0;
        const ratingDistribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
        restaurantReviews.forEach(review => {
            ratingDistribution[review.rating]++;
        });
        return {
            averageRating: Number(averageRating.toFixed(1)),
            totalRatings,
            ratingDistribution
        };
    }
}
exports.ReviewService = ReviewService;
