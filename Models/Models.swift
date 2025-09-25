import Foundation

// MARK: - Foursquare API Response Models

/// Main response structure for Foursquare Places API
struct FoursquareResponse: Codable {
    let results: [Place]
    let context: Context?
}

/// Individual place/restaurant from Foursquare
struct Place: Codable, Identifiable, Hashable {
    let fsqId: String
    let name: String
    let categories: [Category]
    let distance: Int?
    let geocodes: Geocodes
    let location: PlaceLocation
    let popularity: Double?
    let price: Int?
    let rating: Double?
    let stats: PlaceStats?
    let verified: Bool?
    let hours: PlaceHours?
    let photos: [PlacePhoto]?
    let tel: String?
    let website: String?
    let socialMedia: SocialMedia?
    
    // Computed properties for easier access
    var id: String { fsqId }
    var primaryCategory: Category? { categories.first }
    var formattedDistance: String {
        guard let distance = distance else { return "Unknown distance" }
        let miles = Double(distance) / 1609.34 // Convert meters to miles
        return String(format: "%.1f mi", miles)
    }
    var priceLevel: String {
        guard let price = price else { return "Price not available" }
        return String(repeating: "$", count: price)
    }
    var isOpen: Bool {
        return hours?.openNow ?? false
    }
    var statusText: String {
        return isOpen ? "Open" : "Closed"
    }
    
    enum CodingKeys: String, CodingKey {
        case fsqId = "fsq_id"
        case name, categories, distance, geocodes, location, popularity, price, rating, stats, verified, hours, photos, tel, website
        case socialMedia = "social_media"
    }
}

/// Category information for places
struct Category: Codable, Hashable {
    let id: Int
    let name: String
    let icon: CategoryIcon
    
    var iconURL: String {
        return "\(icon.prefix)64\(icon.suffix)"
    }
}

/// Category icon information
struct CategoryIcon: Codable, Hashable {
    let prefix: String
    let suffix: String
}

/// Geographic coordinates
struct Geocodes: Codable, Hashable {
    let main: Coordinate
    let roof: Coordinate?
}

/// Individual coordinate
struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
}

/// Location information
struct PlaceLocation: Codable, Hashable {
    let address: String?
    let crossStreet: String?
    let locality: String?
    let region: String?
    let postcode: String?
    let country: String?
    let formattedAddress: String?
    
    var displayAddress: String {
        return formattedAddress ?? address ?? "Address not available"
    }
    
    enum CodingKeys: String, CodingKey {
        case address, locality, region, postcode, country
        case crossStreet = "cross_street"
        case formattedAddress = "formatted_address"
    }
}

/// Place statistics
struct PlaceStats: Codable, Hashable {
    let totalRatings: Int?
    let totalTips: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalRatings = "total_ratings"
        case totalTips = "total_tips"
    }
}

/// Operating hours information
struct PlaceHours: Codable, Hashable {
    let openNow: Bool
    let regular: [RegularHours]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case regular
    }
}

/// Regular operating hours
struct RegularHours: Codable, Hashable {
    let close: String
    let day: Int
    let open: String
}

/// Photo information
struct PlacePhoto: Codable, Hashable {
    let id: String
    let createdAt: String
    let prefix: String
    let suffix: String
    let width: Int
    let height: Int
    
    var photoURL: String {
        return "\(prefix)original\(suffix)"
    }
    
    var thumbnailURL: String {
        return "\(prefix)300x300\(suffix)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, prefix, suffix, width, height
        case createdAt = "created_at"
    }
}

/// Social media information
struct SocialMedia: Codable, Hashable {
    let facebookId: String?
    let instagram: String?
    let twitter: String?
    
    enum CodingKeys: String, CodingKey {
        case facebookId = "facebook_id"
        case instagram, twitter
    }
}

/// Context information from API response
struct Context: Codable {
    let geoBounds: GeoBounds?
    
    enum CodingKeys: String, CodingKey {
        case geoBounds = "geo_bounds"
    }
}

/// Geographic bounds
struct GeoBounds: Codable {
    let circle: Circle?
}

/// Circle bounds
struct Circle: Codable {
    let center: Coordinate
    let radius: Int
}

// MARK: - Search Parameters

/// Parameters for restaurant search
struct SearchParameters {
    let query: String?
    let categories: String?
    let near: String?
    let ll: String? // latitude,longitude
    let radius: Int?
    let limit: Int?
    let sort: SortOption?
    let price: String?
    let openNow: Bool?
    
    enum SortOption: String, CaseIterable {
        case distance = "DISTANCE"
        case rating = "RATING"
        case popularity = "POPULARITY"
        
        var displayName: String {
            switch self {
            case .distance: return "Distance"
            case .rating: return "Rating"
            case .popularity: return "Popularity"
            }
        }
    }
    
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let query = query, !query.isEmpty {
            items.append(URLQueryItem(name: "query", value: query))
        }
        if let categories = categories {
            items.append(URLQueryItem(name: "categories", value: categories))
        }
        if let near = near {
            items.append(URLQueryItem(name: "near", value: near))
        }
        if let ll = ll {
            items.append(URLQueryItem(name: "ll", value: ll))
        }
        if let radius = radius {
            items.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        if let limit = limit {
            items.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let sort = sort {
            items.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }
        if let price = price {
            items.append(URLQueryItem(name: "price", value: price))
        }
        if let openNow = openNow {
            items.append(URLQueryItem(name: "open_now", value: String(openNow)))
        }
        
        return items
    }
}

// MARK: - Filter Models

/// Restaurant filter options
struct RestaurantFilter {
    var priceRange: PriceRange = .all
    var minRating: Double = 0.0
    var maxDistance: Double = 25.0 // miles
    var categories: Set<String> = []
    var openNow: Bool = false
    var sortBy: SearchParameters.SortOption = .distance
}

/// Price range options
enum PriceRange: String, CaseIterable {
    case all = "all"
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    
    var displayName: String {
        switch self {
        case .all: return "All Prices"
        case .one: return "$"
        case .two: return "$$"
        case .three: return "$$$"
        case .four: return "$$$$"
        }
    }
    
    var description: String {
        switch self {
        case .all: return "Any price range"
        case .one: return "Budget-friendly"
        case .two: return "Moderate"
        case .three: return "Upscale"
        case .four: return "Fine dining"
        }
    }
}
