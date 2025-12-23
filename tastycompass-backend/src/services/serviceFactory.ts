import { UserService as UserServiceMemory } from './userService';
import { UserService as UserServicePG } from './userServicePostgres';
import { FavoriteService as FavoriteServiceMemory } from './favoriteService';
import { FavoriteService as FavoriteServicePG } from './favoriteServicePostgres';
import { ReviewService as ReviewServiceMemory } from './reviewService';
import { ReviewService as ReviewServicePG } from './reviewServicePostgres';

const USE_POSTGRES = process.env.USE_POSTGRES === 'true';

console.log(`📦 Using ${USE_POSTGRES ? 'PostgreSQL' : 'in-memory'} services`);

// Export the appropriate service classes
export const UserService = USE_POSTGRES ? UserServicePG : UserServiceMemory;
export const FavoriteService = USE_POSTGRES ? FavoriteServicePG : FavoriteServiceMemory;
export const ReviewService = USE_POSTGRES ? ReviewServicePG : ReviewServiceMemory;

