import Foundation
import Combine
import CoreLocation

/// Service for communicating with our backend API
class BackendAPIService: ObservableObject {
    static let shared = BackendAPIService()
    
    private let baseURL = "http://localhost:3000/api"
    private let session = URLSession.shared
    
    // Auth token for authenticated requests
    @Published var authToken: String?
    
    init() {}
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let requestBody = [
            "email": email,
            "password": password,
            "firstName": "User",
            "lastName": "Name"
        ]
        
        print("🌐 Signing up user: \(email)")
        
        return makeRequest(url: url, method: "POST", body: requestBody)
            .handleEvents(
                receiveOutput: { data in
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw signup response: \(jsonString)")
                    }
                }
            )
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .handleEvents(
                receiveOutput: { response in
                    print("✅ Sign up successful: \(response.user.email)")
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Sign up failed: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<AuthResponse, Error> {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        let requestBody = [
            "email": email,
            "password": password
        ]
        
        print("🌐 Signing in user: \(email)")
        
        return makeRequest(url: url, method: "POST", body: requestBody)
            .handleEvents(
                receiveOutput: { data in
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("🔍 Raw response: \(jsonString)")
                    }
                }
            )
            .decode(type: AuthResponse.self, decoder: JSONDecoder())
            .handleEvents(
                receiveOutput: { [weak self] response in
                    print("✅ Sign in successful: \(response.user.email)")
                    self?.authToken = response.token
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Sign in failed: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func makeRequest(url: URL, method: String, body: [String: Any], requiresAuth: Bool = false) -> AnyPublisher<Data, Error> {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if required and token is available
        if requiresAuth, let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .mapError { error in
                BackendAPIError.networkError(error)
            }
            .eraseToAnyPublisher()
    }
    
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
        
        // Add price range filter
        if filter.priceRange != .all {
            // For single price level selection, use the min value
            if let priceLevel = filter.priceRange.min {
                urlComponents.queryItems?.append(URLQueryItem(name: "priceLevel", value: "\(priceLevel)"))
            }
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
    
    // MARK: - Authentication
    
    func login(email: String, password: String) -> AnyPublisher<(User, String), Error> {
        let urlString = "\(baseURL)/auth/login"
        guard let url = URL(string: urlString) else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: String] = [
            "email": email,
            "password": password
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🌐 Logging in: \(email)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
                    print("❌ Login HTTP Error: \(statusCode), Body: \(responseBody)")
                    throw BackendAPIError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody]))
                }
                
                do {
                    let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                    
                    guard let userDict = response["user"] as? [String: Any],
                          let token = response["token"] as? String else {
                        throw BackendAPIError.decodingError
                    }
                    
                    let user = User(
                        id: userDict["id"] as? String ?? "",
                        email: userDict["email"] as? String ?? "",
                        firstName: userDict["firstName"] as? String ?? "",
                        lastName: userDict["lastName"] as? String ?? "",
                        createdAt: userDict["createdAt"] as? String ?? "",
                        updatedAt: userDict["updatedAt"] as? String ?? ""
                    )
                    
                    print("✅ Login successful: \(user.email)")
                    return (user, token)
                } catch {
                    print("❌ Failed to decode login response: \(error)")
                    throw BackendAPIError.decodingError
                }
            }
            .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) -> AnyPublisher<(User, String), Error> {
        let urlString = "\(baseURL)/auth/register"
        guard let url = URL(string: urlString) else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: String] = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🌐 Registering: \(email)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
                    print("❌ Register HTTP Error: \(statusCode), Body: \(responseBody)")
                    throw BackendAPIError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody]))
                }
                
                do {
                    let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                    
                    guard let userDict = response["user"] as? [String: Any],
                          let token = response["token"] as? String else {
                        throw BackendAPIError.decodingError
                    }
                    
                    let user = User(
                        id: userDict["id"] as? String ?? "",
                        email: userDict["email"] as? String ?? "",
                        firstName: userDict["firstName"] as? String ?? "",
                        lastName: userDict["lastName"] as? String ?? "",
                        createdAt: userDict["createdAt"] as? String ?? "",
                        updatedAt: userDict["updatedAt"] as? String ?? ""
                    )
                    
                    print("✅ Registration successful: \(user.email)")
                    return (user, token)
                } catch {
                    print("❌ Failed to decode register response: \(error)")
                    throw BackendAPIError.decodingError
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Favorites
    
    func toggleFavorite(for place: Place) -> AnyPublisher<Bool, Error> {
        let urlString = "\(baseURL)/favorites/toggle"
        guard let url = URL(string: urlString) else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody: [String: Any] = [
            "restaurantId": place.fsqId,
            "restaurantName": place.name,
            "restaurantAddress": place.location.displayAddress,
            "restaurantRating": place.rating as Any,
            "restaurantPriceLevel": place.price as Any,
            "restaurantPhotoUrl": place.photos?.first?.photoURL as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        print("🌐 Toggling favorite: \(place.name)")
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
                    print("❌ Toggle favorite HTTP Error: \(statusCode), Body: \(responseBody)")
                    throw BackendAPIError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody]))
                }
                
                do {
                    let response = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                    if let isFavorited = response["isFavorited"] as? Bool {
                        print("✅ Toggle favorite result: \(isFavorited)")
                        return isFavorited
                    } else {
                        throw BackendAPIError.decodingError
                    }
                } catch {
                    print("❌ Failed to decode toggle favorite response: \(error)")
                    return false
                }
            }
            .eraseToAnyPublisher()
    }
    
    func checkFavoriteStatus(restaurantId: String) -> AnyPublisher<Bool, Error> {
        let urlString = "\(baseURL)/favorites/check/\(restaurantId)"
        guard let url = URL(string: urlString) else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Checking favorite status: \(restaurantId)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
                    print("❌ Check favorite status HTTP Error: \(statusCode), Body: \(responseBody)")
                    throw BackendAPIError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody]))
                }
                
                do {
                    let response = try JSONDecoder().decode([String: Bool].self, from: data)
                    let isFavorited = response["isFavorited"] ?? false
                    print("✅ Favorite status: \(isFavorited)")
                    return isFavorited
                } catch {
                    print("❌ Failed to decode favorite status response: \(error)")
                    return false
                }
            }
            .eraseToAnyPublisher()
    }
    
    func getAllFavorites() -> AnyPublisher<[Place], Error> {
        let urlString = "\(baseURL)/favorites"
        guard let url = URL(string: urlString) else {
            return Fail(error: BackendAPIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 Getting all favorites")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let responseBody = String(data: data, encoding: .utf8) ?? "N/A"
                    print("❌ Get favorites HTTP Error: \(statusCode), Body: \(responseBody)")
                    throw BackendAPIError.networkError(NSError(domain: "HTTPError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: responseBody]))
                }
                
                do {
                    let response = try JSONDecoder().decode(BackendFavoritesResponse.self, from: data)
                    let places = response.favorites.map { favorite in
                        self.convertBackendFavoriteToPlace(favorite)
                    }
                    print("✅ Loaded \(places.count) favorites")
                    return places
                } catch {
                    print("❌ Failed to decode favorites response: \(error)")
                    throw BackendAPIError.decodingError
                }
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
                totalRatings: backendRestaurant.totalRatings ?? 0,
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
    
    private func convertBackendFavoriteToPlace(_ backendFavorite: BackendFavorite) -> Place {
        // Create a photo from the photo URL if available
        let photos: [PlacePhoto]?
        if let photoUrl = backendFavorite.restaurantPhotoUrl, !photoUrl.isEmpty {
            photos = [PlacePhoto(
                id: UUID().uuidString,
                createdAt: "",
                prefix: photoUrl,
                suffix: "",
                width: 400,
                height: 400
            )]
        } else {
            photos = nil
        }
        
        return Place(
            fsqId: backendFavorite.restaurantId,
            name: backendFavorite.restaurantName,
            categories: [Category(
                id: Int.random(in: 1...1000),
                name: "Restaurant",
                icon: CategoryIcon(prefix: "", suffix: "")
            )],
            distance: nil,
            geocodes: Geocodes(
                main: Coordinate(latitude: 0, longitude: 0), // Will be updated when we have location data
                roof: nil
            ),
            location: PlaceLocation(
                address: backendFavorite.restaurantAddress,
                crossStreet: "",
                locality: "",
                region: "",
                postcode: "",
                country: "",
                formattedAddress: backendFavorite.restaurantAddress
            ),
            popularity: 0,
            price: backendFavorite.restaurantPriceLevel,
            rating: backendFavorite.restaurantRating,
            stats: nil,
            verified: nil,
            hours: nil,
            photos: photos,
            tel: "",
            website: "",
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
    let totalRatings: Int?
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

struct BackendFavoritesResponse: Codable {
    let favorites: [BackendFavorite]
    let count: Int
}

struct BackendFavorite: Codable {
    let id: String
    let restaurantId: String
    let restaurantName: String
    let restaurantAddress: String
    let restaurantRating: Double?
    let restaurantPriceLevel: Int?
    let restaurantPhotoUrl: String?
    let createdAt: String
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
