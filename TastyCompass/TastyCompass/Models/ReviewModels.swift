import Foundation

// MARK: - Review Models

struct Review: Codable, Identifiable {
    let id: String
    let userId: String
    let restaurantId: String
    let rating: Int // 1-5 stars
    let title: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let helpfulCount: Int
    let isReported: Bool
    
    // User info for display
    let userName: String?
    let userAvatar: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case restaurantId
        case rating
        case title
        case content
        case createdAt
        case updatedAt
        case helpfulCount
        case isReported
        case userName
        case userAvatar
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        restaurantId = try container.decode(String.self, forKey: .restaurantId)
        rating = try container.decode(Int.self, forKey: .rating)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        
        // Decode dates as ISO strings
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        createdAt = formatter.date(from: createdAtString) ?? Date()
        updatedAt = formatter.date(from: updatedAtString) ?? Date()
        
        helpfulCount = try container.decode(Int.self, forKey: .helpfulCount)
        isReported = try container.decode(Bool.self, forKey: .isReported)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        userAvatar = try container.decodeIfPresent(String.self, forKey: .userAvatar)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(restaurantId, forKey: .restaurantId)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(content, forKey: .content)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
        
        try container.encode(helpfulCount, forKey: .helpfulCount)
        try container.encode(isReported, forKey: .isReported)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userAvatar, forKey: .userAvatar)
    }
    
    // Convenience initializer for previews and testing
    init(
        id: String,
        userId: String,
        restaurantId: String,
        rating: Int,
        title: String? = nil,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        helpfulCount: Int = 0,
        isReported: Bool = false,
        userName: String? = nil,
        userAvatar: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.restaurantId = restaurantId
        self.rating = rating
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.helpfulCount = helpfulCount
        self.isReported = isReported
        self.userName = userName
        self.userAvatar = userAvatar
    }
}

// MARK: - Review Request Models

struct CreateReviewRequest: Codable {
    let restaurantId: String
    let rating: Int
    let title: String?
    let content: String
}

struct UpdateReviewRequest: Codable {
    let rating: Int?
    let title: String?
    let content: String?
}

// MARK: - Review Response Models

struct ReviewResponse: Codable {
    let review: Review
    let message: String
}

struct ReviewsResponse: Codable {
    let reviews: [Review]
    let total: Int
    let averageRating: Double
    let totalRatings: Int
}

struct UserReviewsResponse: Codable {
    let reviews: [Review]
}

struct ReviewStats: Codable {
    let averageRating: Double
    let totalRatings: Int
    let ratingDistribution: [String: Int] // "1": count, "2": count, etc.
}

// MARK: - Review Extensions

extension Review {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var hasTitle: Bool {
        return title != nil && !title!.isEmpty
    }
    
    var displayName: String {
        return userName ?? "Anonymous"
    }
    
    var starRating: Double {
        return Double(rating)
    }
}

extension ReviewsResponse {
    var hasReviews: Bool {
        return totalRatings > 0
    }
    
    var ratingText: String {
        if totalRatings == 0 {
            return "No ratings"
        } else if totalRatings == 1 {
            return "\(totalRatings) rating"
        } else {
            return "\(totalRatings) ratings"
        }
    }
}
