import Foundation
import Combine
import CoreLocation
import UIKit

/// Service for interacting with Foursquare Places API
class FoursquareAPIService: ObservableObject {
    static let shared = FoursquareAPIService()
    
    private let configuration = ConfigurationManager.shared
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Validate configuration on initialization
        guard configuration.validateConfiguration() else {
            fatalError("❌ Foursquare API configuration is invalid")
        }
    }
    
    // MARK: - Search Restaurants
    
    /// Searches for restaurants near a location
    /// - Parameters:
    ///   - query: Search term (optional)
    ///   - location: CLLocation for nearby search
    ///   - radius: Search radius in meters (default: 5000m = ~3 miles)
    ///   - limit: Maximum number of results (default: 20)
    ///   - sortBy: Sort option (default: distance)
    /// - Returns: Publisher with array of places
    func searchRestaurants(
        query: String? = nil,
        near location: CLLocation,
        radius: Int = 5000,
        limit: Int = 20,
        sortBy: SearchParameters.SortOption = .distance
    ) -> AnyPublisher<[Place], Error> {
        
        let parameters = SearchParameters(
            query: query,
            categories: "13000", // Food category in Foursquare
            near: nil,
            ll: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            radius: radius,
            limit: limit,
            sort: sortBy,
            price: nil,
            openNow: nil
        )
        
        return searchPlaces(parameters: parameters)
    }
    
    /// Searches for restaurants by city name
    /// - Parameters:
    ///   - query: Search term (optional)
    ///   - city: City name for search
    ///   - limit: Maximum number of results (default: 20)
    /// - Returns: Publisher with array of places
    func searchRestaurants(
        query: String? = nil,
        in city: String,
        limit: Int = 20
    ) -> AnyPublisher<[Place], Error> {
        
        let parameters = SearchParameters(
            query: query,
            categories: "13000", // Food category
            near: city,
            ll: nil,
            radius: nil,
            limit: limit,
            sort: .popularity,
            price: nil,
            openNow: nil
        )
        
        return searchPlaces(parameters: parameters)
    }
    
    /// Searches for restaurants with advanced filters
    /// - Parameters:
    ///   - filter: RestaurantFilter with all filter options
    ///   - location: CLLocation for nearby search
    ///   - query: Optional search term
    /// - Returns: Publisher with array of places
    func searchRestaurants(
        with filter: RestaurantFilter,
        near location: CLLocation,
        query: String? = nil
    ) -> AnyPublisher<[Place], Error> {
        
        let radius = Int(filter.maxDistance * 1609.34) // Convert miles to meters
        
        let parameters = SearchParameters(
            query: query,
            categories: filter.categories.isEmpty ? "13000" : filter.categories.joined(separator: ","),
            near: nil,
            ll: "\(location.coordinate.latitude),\(location.coordinate.longitude)",
            radius: radius,
            limit: 50,
            sort: filter.sortBy,
            price: filter.priceRange == .all ? nil : filter.priceRange.rawValue,
            openNow: filter.openNow
        )
        
        return searchPlaces(parameters: parameters)
            .map { places in
                // Apply additional filters that aren't supported by API
                return places.filter { place in
                    // Filter by minimum rating
                    if let rating = place.rating, rating < filter.minRating {
                        return false
                    }
                    return true
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Get Place Details
    
    /// Gets detailed information for a specific place
    /// - Parameter placeId: Foursquare place ID
    /// - Returns: Publisher with place details
    func getPlaceDetails(placeId: String) -> AnyPublisher<Place, Error> {
        let url = configuration.foursquareURL(for: "\(configuration.foursquarePlaceEndpoint)/\(placeId)")
        
        return makeRequest(url: url, responseType: Place.self)
    }
    
    /// Gets photos for a specific place
    /// - Parameter placeId: Foursquare place ID
    /// - Returns: Publisher with array of photos
    func getPlacePhotos(placeId: String) -> AnyPublisher<[PlacePhoto], Error> {
        let url = configuration.foursquareURL(for: "\(configuration.foursquarePhotoEndpoint)/\(placeId)/photos")
        
        struct PhotosResponse: Codable {
            let photos: [PlacePhoto]
        }
        
        return makeRequest(url: url, responseType: PhotosResponse.self)
            .map { $0.photos }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// Performs a places search with given parameters
    private func searchPlaces(parameters: SearchParameters) -> AnyPublisher<[Place], Error> {
        let url = configuration.foursquareURL(for: configuration.foursquareSearchEndpoint)
        
        return makeRequest(url: url, parameters: parameters, responseType: FoursquareResponse.self)
            .map { $0.results }
            .eraseToAnyPublisher()
    }
    
    /// Makes a generic API request
    private func makeRequest<T: Codable>(
        url: String,
        parameters: SearchParameters? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        
        guard var urlComponents = URLComponents(string: url) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        // Add query parameters if provided
        if let parameters = parameters {
            urlComponents.queryItems = parameters.queryItems
        }
        
        guard let finalURL = urlComponents.url else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.foursquareAPIKey, forHTTPHeaderField: "Authorization")
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: responseType, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Makes a simple API request without parameters
    private func makeRequest<T: Codable>(
        url: String,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        return makeRequest(url: url, parameters: nil, responseType: responseType)
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case networkError(Error)
    case unauthorized
    case rateLimited
    case serverError(Int)
    
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
        case .unauthorized:
            return "API key is invalid or expired"
        case .rateLimited:
            return "API rate limit exceeded"
        case .serverError(let code):
            return "Server error: \(code)"
        }
    }
}

// MARK: - Location Helper

extension FoursquareAPIService {
    
    /// Gets user's current location for search
    /// - Returns: Publisher with current location
    func getCurrentLocation() -> AnyPublisher<CLLocation, Error> {
        return Future<CLLocation, Error> { promise in
            let locationManager = CLLocationManager()
            
            // Request location permission
            locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.startUpdatingLocation()
                
                // Get location with timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    locationManager.stopUpdatingLocation()
                    if let location = locationManager.location {
                        promise(.success(location))
                    } else {
                        promise(.failure(APIError.networkError(NSError(domain: "LocationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get current location"]))))
                    }
                }
            } else {
                promise(.failure(APIError.networkError(NSError(domain: "LocationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Location services are disabled"]))))
            }
        }
        .eraseToAnyPublisher()
    }
}
