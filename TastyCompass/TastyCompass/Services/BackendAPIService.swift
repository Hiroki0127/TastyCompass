import Foundation
import Combine
import CoreLocation

/// Service for communicating with our backend API
class BackendAPIService: ObservableObject {
    static let shared = BackendAPIService()
    
    private let baseURL = "http://localhost:3000/api"
    private let session = URLSession.shared
    
    init() {}
    
    // MARK: - Restaurant Search
    
    func searchRestaurants(
        with filter: RestaurantFilter,
        near location: CLLocation,
        query: String? = nil
    ) -> AnyPublisher<[Place], Error> {
        var urlComponents = URLComponents(string: "\(baseURL)/restaurants/search")!
        
        // Required parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "location", value: "\(location.coordinate.latitude),\(location.coordinate.longitude)"),
            URLQueryItem(name: "radius", value: "\(Int(filter.maxDistance * 1609))") // Convert miles to meters
        ]
        
        // Optional parameters
        if let query = query, !query.isEmpty {
            urlComponents.queryItems?.append(URLQueryItem(name: "query", value: query))
        }
        
        if !filter.categories.isEmpty {
            let categoryKeywords = filter.categories.joined(separator: " ")
            let combinedQuery = query.map { "\($0) \(categoryKeywords)" } ?? categoryKeywords
            urlComponents.queryItems?.append(URLQueryItem(name: "query", value: combinedQuery))
        }
        
        if filter.openNow {
            urlComponents.queryItems?.append(URLQueryItem(name: "openNow", value: "true"))
        }
        
        if filter.minRating > 0 {
            urlComponents.queryItems?.append(URLQueryItem(name: "minRating", value: "\(filter.minRating)"))
        }
        
        guard let url = urlComponents.url else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Backend API Request: \(url)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: BackendRestaurantSearchResponse.self, decoder: JSONDecoder())
            .map { response in
                print("✅ Backend API Response: \(response.restaurants.count) restaurants")
                
                // Convert backend restaurants to our Place model
                var places = response.restaurants.map { backendRestaurant in
                    self.convertBackendRestaurantToPlace(backendRestaurant, userLocation: location)
                }
                
                // Apply client-side sorting since backend doesn't handle it yet
                switch filter.sortBy {
                case .distance:
                    places.sort { ($0.distance ?? Int.max) < ($1.distance ?? Int.max) }
                    print("📏 Sorted by: Distance")
                case .rating:
                    places.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
                    print("⭐ Sorted by: Rating")
                case .popularity:
                    places.sort { ($0.stats?.totalRatings ?? 0) > ($1.stats?.totalRatings ?? 0) }
                    print("🔥 Sorted by: Popularity")
                }
                
                return places
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Restaurant Details
    
    func getRestaurantDetails(placeId: String) -> AnyPublisher<Place, Error> {
        let url = URL(string: "\(baseURL)/restaurants/\(placeId)")!
        
        print("🌐 Backend API Details Request: \(url)")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: BackendRestaurantDetailsResponse.self, decoder: JSONDecoder())
            .map { response in
                print("✅ Backend API Details Response: \(response.restaurant.name)")
                
                // Convert backend restaurant to our Place model
                return self.convertBackendRestaurantToPlace(response.restaurant, userLocation: nil)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func convertBackendRestaurantToPlace(_ backendRestaurant: BackendRestaurant, userLocation: CLLocation?) -> Place {
        // Convert photos
        let photos = backendRestaurant.photos?.map { backendPhoto in
            PlacePhoto(
                id: backendPhoto.id,
                createdAt: "",
                prefix: backendPhoto.url,
                suffix: "",
                width: backendPhoto.width ?? 0,
                height: backendPhoto.height ?? 0
            )
        }
        
        // Calculate distance if user location is provided
        var distance: Int?
        if let userLocation = userLocation {
            let restaurantLocation = CLLocation(
                latitude: backendRestaurant.location.latitude,
                longitude: backendRestaurant.location.longitude
            )
            distance = Int(userLocation.distance(from: restaurantLocation))
        }
        
        // Reviews not implemented yet
        // let reviews: [PlaceReview]? = nil
        
        return Place(
            fsqId: backendRestaurant.id,
            name: backendRestaurant.name,
            categories: backendRestaurant.categories.map { categoryName in
                Category(
                    id: Int.random(in: 1...1000),
                    name: categoryName,
                    icon: CategoryIcon(prefix: "", suffix: "")
                )
            },
            distance: distance,
            geocodes: Geocodes(
                main: Coordinate(
                    latitude: backendRestaurant.location.latitude,
                    longitude: backendRestaurant.location.longitude
                ),
                roof: nil
            ),
            location: PlaceLocation(
                address: backendRestaurant.address,
                crossStreet: "",
                locality: "",
                region: "",
                postcode: "",
                country: "",
                formattedAddress: backendRestaurant.address
            ),
            popularity: 0,
            price: backendRestaurant.priceLevel,
            rating: backendRestaurant.rating,
            stats: PlaceStats(
                totalRatings: backendRestaurant.reviews?.count ?? 0,
                totalTips: 0
            ),
            verified: false,
            hours: nil,
            photos: photos,
            tel: backendRestaurant.phoneNumber ?? "",
            website: backendRestaurant.website ?? "",
            socialMedia: nil
        )
    }
}

// MARK: - Backend API Models

struct BackendRestaurantSearchResponse: Codable {
    let restaurants: [BackendRestaurant]
    let totalResults: Int
}

struct BackendRestaurantDetailsResponse: Codable {
    let restaurant: BackendRestaurant
}

struct BackendRestaurant: Codable {
    let id: String
    let name: String
    let address: String
    let rating: Double?
    let priceLevel: Int?
    let photos: [BackendPhoto]?
    let phoneNumber: String?
    let website: String?
    let isOpen: Bool?
    let categories: [String]
    let location: BackendLocation
    let reviews: [BackendReview]?
}

struct BackendPhoto: Codable {
    let id: String
    let url: String
    let width: Int?
    let height: Int?
}

struct BackendLocation: Codable {
    let latitude: Double
    let longitude: Double
}

struct BackendReview: Codable {
    let id: String
    let author: String
    let rating: Int
    let text: String?
    let time: String
}

// MARK: - Backend API Error

enum BackendAPIError: Error, LocalizedError {
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
