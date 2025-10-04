export interface Review {
  id: string;
  userId: string;
  restaurantId: string;
  rating: number; // 1-5 stars
  title?: string;
  content: string;
  createdAt: Date;
  updatedAt: Date;
  helpfulCount: number;
  isReported: boolean;
  
  // User info for display
  userName?: string;
  userAvatar?: string;
}

export interface CreateReviewRequest {
  restaurantId: string;
  rating: number;
  title?: string;
  content: string;
}

export interface UpdateReviewRequest {
  rating?: number;
  title?: string;
  content?: string;
}

export interface ReviewResponse {
  review: Review;
  message: string;
}

export interface ReviewsResponse {
  reviews: Review[];
  total: number;
  averageRating: number;
  totalRatings: number;
}
