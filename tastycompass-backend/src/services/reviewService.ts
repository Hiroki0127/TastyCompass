import { Review, CreateReviewRequest, UpdateReviewRequest, ReviewsResponse } from '../types/review';
import { UserService } from './userService';

export class ReviewService {
  private reviews = new Map<string, Review>();

  constructor() {
    // Add some sample reviews for testing (async)
    this.addSampleReviews().catch(error => {
      console.log('Failed to add sample reviews:', error.message);
    });
  }

    private async addSampleReviews() {
        // Get the current demo user ID from UserService
        const demoUser = await UserService.findUserByEmail('demo@tastycompass.com');
        if (!demoUser) {
            console.log('Demo user not found, skipping sample reviews');
            return;
        }

        const sampleReviews: Review[] = [
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

  async createReview(userId: string, reviewData: CreateReviewRequest): Promise<Review> {
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

    const user = await UserService.findUserById(userId);
    if (!user) {
      throw new Error('User not found');
    }

    const review: Review = {
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

  async updateReview(userId: string, reviewId: string, updateData: UpdateReviewRequest): Promise<Review> {
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

    const updatedReview: Review = {
      ...review,
      rating: updateData.rating ?? review.rating,
      title: updateData.title?.trim() ?? review.title,
      content: updateData.content?.trim() ?? review.content,
      updatedAt: new Date()
    };

    this.reviews.set(reviewId, updatedReview);
    return updatedReview;
  }

  async deleteReview(userId: string, reviewId: string): Promise<void> {
    const review = this.reviews.get(reviewId);
    if (!review) {
      throw new Error('Review not found');
    }

    if (review.userId !== userId) {
      throw new Error('Unauthorized to delete this review');
    }

    this.reviews.delete(reviewId);
  }

  getUserReview(userId: string, restaurantId: string): Review | null {
    for (const review of this.reviews.values()) {
      if (review.userId === userId && review.restaurantId === restaurantId) {
        return review;
      }
    }
    return null;
  }

  getReviewsForRestaurant(restaurantId: string, limit: number = 20, offset: number = 0): ReviewsResponse {
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

  getUserReviews(userId: string, limit: number = 20, offset: number = 0): Review[] {
    return Array.from(this.reviews.values())
      .filter(review => review.userId === userId)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(offset, offset + limit);
  }

  async markReviewHelpful(reviewId: string): Promise<number> {
    const review = this.reviews.get(reviewId);
    if (!review) {
      throw new Error('Review not found');
    }

    const updatedReview: Review = {
      ...review,
      helpfulCount: review.helpfulCount + 1
    };

    this.reviews.set(reviewId, updatedReview);
    return updatedReview.helpfulCount;
  }

  async reportReview(reviewId: string): Promise<void> {
    const review = this.reviews.get(reviewId);
    if (!review) {
      throw new Error('Review not found');
    }

    const updatedReview: Review = {
      ...review,
      isReported: true
    };

    this.reviews.set(reviewId, updatedReview);
  }

  getReviewById(reviewId: string): Review | null {
    return this.reviews.get(reviewId) || null;
  }

  getAllReviews(): Review[] {
    return Array.from(this.reviews.values());
  }

  getReviewStats(restaurantId: string): { averageRating: number; totalRatings: number; ratingDistribution: Record<number, number> } {
    const restaurantReviews = Array.from(this.reviews.values())
      .filter(review => review.restaurantId === restaurantId && !review.isReported);

    const totalRatings = restaurantReviews.length;
    const averageRating = totalRatings > 0
      ? restaurantReviews.reduce((sum, review) => sum + review.rating, 0) / totalRatings
      : 0;

    const ratingDistribution: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
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
