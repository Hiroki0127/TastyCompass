import Foundation

// MARK: - Google Places API Response Models

/// Main response structure for Google Places Nearby Search API
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
    let nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        case results, status
        case nextPageToken = "next_page_token"
    }
}

/// Individual place/restaurant from Google Places
struct GooglePlace: Codable, Identifiable, Hashable {
    let placeId: String
    let name: String
    let types: [String]
    let vicinity: String?
    let geometry: GoogleGeometry
    let rating: Double?
    let priceLevel: Int?
    let photos: [GooglePhoto]?
    let openingHours: GoogleOpeningHours?
    let businessStatus: String?
    let userRatingsTotal: Int?
    
    // Computed properties for easier access
    var id: String { placeId }
    var primaryType: String { types.first ?? "restaurant" }
    var formattedDistance: String {
        // Distance will be calculated by the API service
        return "Distance calculated"
    }
    var priceLevelString: String {
        guard let price = priceLevel else { return "Price not available" }
        return String(repeating: "$", count: price)
    }
    var isOpen: Bool {
        return openingHours?.openNow ?? false
    }
    var statusText: String {
        return isOpen ? "Open" : "Closed"
    }
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, types, vicinity, geometry, rating
        case priceLevel = "price_level"
        case photos
        case openingHours = "opening_hours"
        case businessStatus = "business_status"
        case userRatingsTotal = "user_ratings_total"
    }
}

/// Geometry information for Google Places
struct GoogleGeometry: Codable, Hashable {
    let location: GoogleLocation
    let viewport: GoogleViewport?
}

/// Location coordinates
struct GoogleLocation: Codable, Hashable {
    let lat: Double
    let lng: Double
}

/// Viewport bounds
struct GoogleViewport: Codable, Hashable {
    let northeast: GoogleLocation
    let southwest: GoogleLocation
}

/// Photo information
struct GooglePhoto: Codable, Hashable {
    let photoReference: String
    let height: Int
    let width: Int
    
    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case height, width
    }
}

/// Opening hours information
struct GoogleOpeningHours: Codable, Hashable {
    let openNow: Bool
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}

// MARK: - Google Places Details Response Models

/// Response for Google Places Details API
struct GooglePlaceDetailsResponse: Codable {
    let result: GooglePlaceDetails
    let status: String
}

/// Detailed place information
struct GooglePlaceDetails: Codable {
    let placeId: String
    let name: String
    let types: [String]?
    let formattedAddress: String?
    let formattedPhoneNumber: String?
    let website: String?
    let rating: Double?
    let priceLevel: Int?
    let photos: [GooglePhoto]?
    let openingHours: GoogleDetailedOpeningHours?
    let reviews: [GoogleReview]?
    let userRatingsTotal: Int?
    
    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name, types
        case formattedAddress = "formatted_address"
        case formattedPhoneNumber = "formatted_phone_number"
        case website, rating
        case priceLevel = "price_level"
        case photos
        case openingHours = "opening_hours"
        case reviews
        case userRatingsTotal = "user_ratings_total"
    }
}

/// Detailed opening hours
struct GoogleDetailedOpeningHours: Codable {
    let openNow: Bool
    let periods: [GooglePeriod]?
    let weekdayText: [String]?
    
    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case periods
        case weekdayText = "weekday_text"
    }
}

/// Opening period
struct GooglePeriod: Codable {
    let open: GoogleTime
    let close: GoogleTime?
}

/// Time information
struct GoogleTime: Codable {
    let day: Int
    let time: String
}

/// Review information
struct GoogleReview: Codable, Identifiable {
    let id: String
    let author: String
    let rating: Int
    let text: String
    let time: Date
    
    enum CodingKeys: String, CodingKey {
        case id, author, rating, text, time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        rating = try container.decode(Int.self, forKey: .rating)
        text = try container.decode(String.self, forKey: .text)
        
        let timeString = try container.decode(String.self, forKey: .time)
        
        // Try multiple date formats to handle different ISO8601 variants
        var timeDate: Date?
        
        // Try ISO8601 with fractional seconds first
        let iso8601WithFractional = ISO8601DateFormatter()
        iso8601WithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso8601WithFractional.date(from: timeString) {
            timeDate = date
        }
        
        // Try ISO8601 without fractional seconds
        if timeDate == nil {
            let iso8601WithoutFractional = ISO8601DateFormatter()
            iso8601WithoutFractional.formatOptions = [.withInternetDateTime]
            if let date = iso8601WithoutFractional.date(from: timeString) {
                timeDate = date
            }
        }
        
        // Try custom DateFormatter as fallback
        if timeDate == nil {
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            customFormatter.timeZone = TimeZone(abbreviation: "UTC")
            if let date = customFormatter.date(from: timeString) {
                timeDate = date
            }
        }
        
        guard let validDate = timeDate else {
            print("⚠️ Failed to parse date: \(timeString)")
            // Fallback to current date if parsing fails
            time = Date()
            return
        }
        time = validDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(author, forKey: .author)
        try container.encode(rating, forKey: .rating)
        try container.encode(text, forKey: .text)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: time), forKey: .time)
    }
    
    // Convenience initializer for previews and testing
    init(
        id: String,
        author: String,
        rating: Int,
        text: String,
        time: Date = Date()
    ) {
        self.id = id
        self.author = author
        self.rating = rating
        self.text = text
        self.time = time
    }
}

struct GooglePagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let hasNextPage: Bool
    let hasPrevPage: Bool
    let limit: Int
}

struct GoogleReviewsResponse: Codable {
    let reviews: [GoogleReview]
    let totalReviews: Int
    let averageRating: Double
    let totalRatings: Int
    let pagination: GooglePagination
}

// MARK: - Search Parameters

/// Parameters for Google Places search
struct GoogleSearchParameters {
    let location: String
    let radius: Int
    let type: String
    let keyword: String?
    let minPrice: Int?
    let maxPrice: Int?
    let openNow: Bool?
    
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        items.append(URLQueryItem(name: "location", value: location))
        items.append(URLQueryItem(name: "radius", value: String(radius)))
        items.append(URLQueryItem(name: "type", value: type))
        
        if let keyword = keyword {
            items.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        if let minPrice = minPrice {
            items.append(URLQueryItem(name: "minprice", value: String(minPrice)))
        }
        
        if let maxPrice = maxPrice {
            items.append(URLQueryItem(name: "maxprice", value: String(maxPrice)))
        }
        
        if let openNow = openNow {
            items.append(URLQueryItem(name: "opennow", value: String(openNow)))
        }
        
        return items
    }
}

// MARK: - Adapter to convert Google Places to our existing Place model

extension GooglePlace {
    /// Converts GooglePlace to our existing Place model for compatibility
    func toPlace() -> Place {
        // Get API key from configuration
        let apiKey = ConfigurationManager.shared.googlePlacesAPIKey
        
        return Place(
            fsqId: self.placeId,
            name: self.name,
            categories: [Category(id: 0, name: self.primaryType, icon: CategoryIcon(prefix: "", suffix: ""))],
            distance: nil, // Will be calculated separately
            geocodes: Geocodes(
                main: Coordinate(latitude: self.geometry.location.lat, longitude: self.geometry.location.lng),
                roof: nil
            ),
            location: PlaceLocation(
                address: self.vicinity,
                crossStreet: nil,
                locality: nil,
                region: nil,
                postcode: nil,
                country: nil,
                formattedAddress: self.vicinity
            ),
            popularity: nil,
            price: self.priceLevel,
            rating: self.rating,
            stats: PlaceStats(totalRatings: self.userRatingsTotal ?? 0, totalTips: 0),
            verified: nil,
            hours: PlaceHours(openNow: self.isOpen, regular: nil),
            photos: self.photos?.map { photo in
                // Construct proper Google Places photo URL
                let photoURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photo_reference=\(photo.photoReference)&key=\(apiKey)"
                print("📸 Photo URL created: \(photoURL.prefix(100))...")
                return PlacePhoto(
                    id: photo.photoReference,
                    createdAt: "",
                    prefix: photoURL,
                    suffix: "",
                    width: photo.width,
                    height: photo.height
                )
            },
            tel: nil,
            website: nil,
            socialMedia: nil
        )
    }
}

// MARK: - Import existing models for compatibility

// We'll keep the existing Place model and other related models from the original Models.swift
// This allows us to maintain compatibility with the existing UI components
