import Foundation
import Combine
import CoreLocation
import UIKit

/// Service for interacting with Google Places API
class GooglePlacesAPIService: ObservableObject {
    private let session = URLSession.shared
    private let configuration = ConfigurationManager.shared
    
    // MARK: - Public Methods
    
    /// Search for restaurants near a location
    func searchRestaurants(
        with filter: RestaurantFilter,
        near location: CLLocation,
        query: String? = nil
    ) -> AnyPublisher<[Place], Error> {
        // Combine user query with category filters
        var searchKeyword = query
        if !filter.categories.isEmpty {
            // Add category keywords to the search
            let categoryKeywords = filter.categories.joined(separator: " ")
            searchKeyword = searchKeyword.map { "\($0) \(categoryKeywords)" } ?? categoryKeywords
            print("🔍 Searching with keywords: \(searchKeyword ?? "")")
        }
        
        let parameters = GoogleSearchParameters(
            location: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            radius: Int(filter.maxDistance * 1609), // Convert miles to meters
            type: "restaurant",
            keyword: searchKeyword,
            minPrice: filter.priceRange.min,
            maxPrice: filter.priceRange.max,
            openNow: filter.openNow
        )
        
        return searchPlaces(parameters: parameters)
            .map { googlePlaces in
                // Convert Google Places to our Place model and calculate distances
                var places = googlePlaces.map { googlePlace -> Place in
                    var place = googlePlace.toPlace()
                    // Calculate distance from user location
                    let placeLocation = CLLocation(
                        latitude: googlePlace.geometry.location.lat,
                        longitude: googlePlace.geometry.location.lng
                    )
                    let distance = Int(location.distance(from: placeLocation))
                    // Create a new Place with calculated distance
                    return Place(
                        fsqId: place.fsqId,
                        name: place.name,
                        categories: place.categories,
                        distance: distance,
                        geocodes: place.geocodes,
                        location: place.location,
                        popularity: place.popularity,
                        price: place.price,
                        rating: place.rating,
                        stats: place.stats,
                        verified: place.verified,
                        hours: place.hours,
                        photos: place.photos,
                        tel: place.tel,
                        website: place.website,
                        socialMedia: place.socialMedia
                    )
                }
                
                // Apply client-side filtering
                let originalCount = places.count
                
                places = places.filter { place in
                    // Filter by minimum rating
                    if filter.minRating > 0 {
                        guard let rating = place.rating, rating >= filter.minRating else {
                            return false
                        }
                    }
                    
                    // Note: Category filtering is done via keyword search, not client-side
                    // because Google Places API doesn't provide cuisine-specific categories
                    
                    return true
                }
                
                if filter.minRating > 0 {
                    print("⭐ Rating filter: \(filter.minRating)+ stars - Filtered from \(originalCount) to \(places.count) restaurants")
                }
                
                // Apply sorting
                switch filter.sortBy {
                case .distance:
                    places.sort { ($0.distance ?? Int.max) < ($1.distance ?? Int.max) }
                    print("📏 Sorted by: Distance")
                case .rating:
                    places.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
                    print("⭐ Sorted by: Rating")
                case .popularity:
                    places.sort { ($0.stats?.totalRatings ?? 0) > ($1.stats?.totalRatings ?? 0) }
                    print("🔥 Sorted by: Popularity (total ratings)")
                }
                
                return places
            }
            .eraseToAnyPublisher()
    }
    
    /// Search for restaurants in a city
    func searchRestaurants(
        query: String? = nil,
        in city: String
    ) -> AnyPublisher<[Place], Error> {
        // For city search, we'll use a default location (city center)
        // In a real app, you might want to geocode the city first
        let defaultLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco default
        
        let parameters = GoogleSearchParameters(
            location: "\(defaultLocation.coordinate.latitude),\(defaultLocation.coordinate.longitude)",
            radius: 50000, // 50km radius for city search
            type: "restaurant",
            keyword: query,
            minPrice: nil,
            maxPrice: nil,
            openNow: nil
        )
        
        return searchPlaces(parameters: parameters)
            .map { googlePlaces in
                return googlePlaces.map { $0.toPlace() }
            }
            .eraseToAnyPublisher()
    }
    
    /// Get detailed information about a specific place
    func getPlaceDetails(placeId: String) -> AnyPublisher<Place, Error> {
        let url = configuration.googlePlacesURL(for: configuration.googlePlacesDetailsEndpoint)
        
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "fields", value: "place_id,name,formatted_address,formatted_phone_number,website,rating,price_level,photos,opening_hours,reviews,user_ratings_total"),
            URLQueryItem(name: "key", value: configuration.googlePlacesAPIKey)
        ]
        
        guard let finalURL = urlComponents?.url else {
            return Fail(error: GoogleAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Getting place details for: \(placeId)")
        print("📡 Final URL: \(finalURL)")
        
        return makeRequest(url: finalURL.absoluteString, responseType: GooglePlaceDetailsResponse.self)
            .map { response in
                print("📋 Place Details Response: \(response.result.name)")
                print("📸 Photos in response: \(response.result.photos?.count ?? 0)")
                if let photos = response.result.photos {
                    for (index, photo) in photos.enumerated() {
                        print("  Photo \(index + 1): \(photo.photoReference)")
                    }
                }
                // Convert GooglePlaceDetails to our Place model
                let googlePlace = GooglePlace(
                    placeId: response.result.placeId,
                    name: response.result.name,
                    types: response.result.types ?? [],
                    vicinity: response.result.formattedAddress,
                    geometry: GoogleGeometry(
                        location: GoogleLocation(lat: 0, lng: 0), // Will be filled from details if needed
                        viewport: nil
                    ),
                    rating: response.result.rating,
                    priceLevel: response.result.priceLevel,
                    photos: response.result.photos,
                    openingHours: GoogleOpeningHours(openNow: response.result.openingHours?.openNow ?? false),
                    businessStatus: nil,
                    userRatingsTotal: response.result.userRatingsTotal
                )
                
                var place = googlePlace.toPlace()
                // Update with detailed information
                return Place(
                    fsqId: place.fsqId,
                    name: place.name,
                    categories: place.categories,
                    distance: place.distance,
                    geocodes: place.geocodes,
                    location: PlaceLocation(
                        address: response.result.formattedAddress,
                        crossStreet: nil,
                        locality: nil,
                        region: nil,
                        postcode: nil,
                        country: nil,
                        formattedAddress: response.result.formattedAddress
                    ),
                    popularity: place.popularity,
                    price: place.price,
                    rating: place.rating,
                    stats: PlaceStats(totalRatings: response.result.userRatingsTotal ?? 0, totalTips: 0),
                    verified: place.verified,
                    hours: PlaceHours(openNow: response.result.openingHours?.openNow ?? false, regular: nil),
                    photos: place.photos,
                    tel: response.result.formattedPhoneNumber,
                    website: response.result.website,
                    socialMedia: place.socialMedia
                )
            }
            .eraseToAnyPublisher()
    }
    
    /// Get photo URL for a place
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> String {
        return "\(configuration.googlePlacesBaseURL)\(configuration.googlePlacesPhotoEndpoint)?maxwidth=\(maxWidth)&photo_reference=\(photoReference)&key=\(configuration.googlePlacesAPIKey)"
    }
    
    // MARK: - Private Methods
    
    private func searchPlaces(parameters: GoogleSearchParameters) -> AnyPublisher<[GooglePlace], Error> {
        let url = configuration.googlePlacesURL(for: configuration.googlePlacesSearchEndpoint)
        
        var urlComponents = URLComponents(string: url)
        urlComponents?.queryItems = parameters.queryItems + [
            URLQueryItem(name: "key", value: configuration.googlePlacesAPIKey)
        ]
        
        guard let finalURL = urlComponents?.url else {
            return Fail(error: GoogleAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Making Google Places API request to: \(finalURL)")
        print("📋 Parameters: \(parameters.queryItems)")
        print("🔑 Using API Key: \(configuration.googlePlacesAPIKey.prefix(10))...")
        
        return makeRequest(url: finalURL.absoluteString, responseType: GooglePlacesResponse.self)
            .map { response in
                print("📊 Google Places API Response: \(response.results.count) places found")
                return response.results
            }
            .eraseToAnyPublisher()
    }
    
    private func makeRequest<T: Codable>(
        url: String,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let requestURL = URL(string: url) else {
            return Fail(error: GoogleAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📡 Final URL: \(requestURL)")
        
        return session.dataTaskPublisher(for: request)
            .map { data, response in
                print("📡 HTTP Response: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Response headers: \(httpResponse.allHeaderFields)")
                }
                
                // Print the actual response body for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response body: \(responseString)")
                }
                
                return data
            }
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - API Error Types

enum GoogleAPIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
