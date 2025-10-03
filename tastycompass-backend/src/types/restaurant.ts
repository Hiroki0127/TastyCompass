// Restaurant types for our API
export interface Restaurant {
  id: string;
  name: string;
  address: string;
  rating?: number;
  priceLevel?: number;
  photos?: RestaurantPhoto[];
  phoneNumber?: string;
  website?: string;
  isOpen?: boolean;
  categories: string[];
  location: {
    latitude: number;
    longitude: number;
  };
  distance?: number; // in meters
  reviews?: RestaurantReview[];
}

export interface RestaurantPhoto {
  id: string;
  url: string;
  width?: number;
  height?: number;
}

export interface RestaurantReview {
  id: string;
  author: string;
  rating: number;
  text?: string;
  time: string;
}

// API Request/Response types
export interface RestaurantSearchRequest {
  query?: string;
  location: string; // "latitude,longitude"
  radius?: number; // in meters, default 5000
  type?: string; // "restaurant"
  openNow?: boolean;
  minRating?: number;
  priceLevel?: number;
}

export interface RestaurantSearchResponse {
  restaurants: Restaurant[];
  totalResults: number;
  nextPageToken?: string;
}

export interface RestaurantDetailsRequest {
  placeId: string;
}

export interface RestaurantDetailsResponse {
  restaurant: Restaurant;
}
