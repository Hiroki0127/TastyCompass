"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.GooglePlacesService = void 0;
const axios_1 = __importDefault(require("axios"));
const GOOGLE_PLACES_BASE_URL = 'https://maps.googleapis.com/maps/api/place';
class GooglePlacesService {
    constructor(apiKey) {
        this.apiKey = apiKey;
    }
    // Search for restaurants using Google Places Nearby Search
    async searchRestaurants(params) {
        const url = `${GOOGLE_PLACES_BASE_URL}/nearbysearch/json`;
        const response = await axios_1.default.get(url, {
            params: {
                location: params.location,
                radius: params.radius || 5000,
                keyword: params.keyword,
                type: params.type || 'restaurant',
                opennow: params.openNow || false,
                key: this.apiKey,
            },
        });
        if (response.data.status !== 'OK') {
            throw new Error(`Google Places API error: ${response.data.status}`);
        }
        return response.data.results.map((place) => this.mapGooglePlaceToRestaurant(place));
    }
    // Get detailed information about a restaurant
    async getRestaurantDetails(placeId) {
        const url = `${GOOGLE_PLACES_BASE_URL}/details/json`;
        const response = await axios_1.default.get(url, {
            params: {
                place_id: placeId,
                fields: 'place_id,name,formatted_address,formatted_phone_number,website,rating,price_level,photos,opening_hours,reviews,user_ratings_total,geometry',
                key: this.apiKey,
            },
        });
        if (response.data.status !== 'OK') {
            throw new Error(`Google Places API error: ${response.data.status}`);
        }
        return this.mapGooglePlaceDetailsToRestaurant(response.data.result);
    }
    // Map Google Places API response to our Restaurant type
    mapGooglePlaceToRestaurant(place) {
        const photos = place.photos?.slice(0, 5).map((photo) => ({
            id: photo.photo_reference,
            url: this.buildPhotoUrl(photo.photo_reference, 400),
            width: photo.width,
            height: photo.height,
        })) || [];
        return {
            id: place.place_id,
            name: place.name,
            address: place.vicinity || place.formatted_address || '',
            rating: place.rating,
            priceLevel: place.price_level,
            photos,
            isOpen: place.opening_hours?.open_now,
            categories: place.types || [],
            location: {
                latitude: place.geometry.location.lat,
                longitude: place.geometry.location.lng,
            },
            totalRatings: place.user_ratings_total || 0,
        };
    }
    // Map Google Places Details API response to our Restaurant type
    mapGooglePlaceDetailsToRestaurant(place) {
        const photos = place.photos?.slice(0, 10).map((photo) => ({
            id: photo.photo_reference,
            url: this.buildPhotoUrl(photo.photo_reference, 800),
            width: photo.width,
            height: photo.height,
        })) || [];
        const reviews = place.reviews?.map((review) => ({
            id: review.author_url || Math.random().toString(),
            author: review.author_name,
            rating: review.rating,
            text: review.text,
            time: new Date(review.time * 1000).toISOString(),
        })) || [];
        return {
            id: place.place_id,
            name: place.name,
            address: place.formatted_address || '',
            rating: place.rating,
            priceLevel: place.price_level,
            photos,
            phoneNumber: place.formatted_phone_number,
            website: place.website,
            isOpen: place.opening_hours?.open_now,
            categories: place.types || [],
            location: {
                latitude: place.geometry.location.lat,
                longitude: place.geometry.location.lng,
            },
            reviews,
        };
    }
    // Build photo URL from Google Places photo reference
    buildPhotoUrl(photoReference, maxWidth = 400) {
        return `${GOOGLE_PLACES_BASE_URL}/photo?maxwidth=${maxWidth}&photo_reference=${photoReference}&key=${this.apiKey}`;
    }
}
exports.GooglePlacesService = GooglePlacesService;
