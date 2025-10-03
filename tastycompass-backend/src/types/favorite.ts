export interface Favorite {
  id: string;
  userId: string;
  restaurantId: string;
  restaurantName: string;
  restaurantAddress: string;
  restaurantRating?: number;
  restaurantPriceLevel?: number;
  restaurantPhotoUrl?: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateFavoriteData {
  userId: string;
  restaurantId: string;
  restaurantName: string;
  restaurantAddress: string;
  restaurantRating?: number;
  restaurantPriceLevel?: number;
  restaurantPhotoUrl?: string;
}

export interface FavoriteWithRestaurant extends Favorite {
  restaurant?: {
    id: string;
    name: string;
    address: string;
    rating?: number;
    priceLevel?: number;
    photos?: Array<{
      id: string;
      url: string;
    }>;
    location: {
      latitude: number;
      longitude: number;
    };
  };
}
