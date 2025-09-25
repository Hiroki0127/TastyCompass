import SwiftUI

/// A SwiftUI view that displays star ratings
struct StarRatingView: View {
    let rating: Double
    let maxRating: Int
    let starSize: CGFloat
    let showRating: Bool
    let ratingColor: Color
    let emptyStarColor: Color
    
    init(
        rating: Double,
        maxRating: Int = 5,
        starSize: CGFloat = 16,
        showRating: Bool = true,
        ratingColor: Color = .yellow,
        emptyStarColor: Color = .gray.opacity(0.3)
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.showRating = showRating
        self.ratingColor = ratingColor
        self.emptyStarColor = emptyStarColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<maxRating, id: \.self) { index in
                starView(for: index)
            }
            
            if showRating {
                Text(String(format: "%.1f", rating))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }
    
    @ViewBuilder
    private func starView(for index: Int) -> some View {
        let filledAmount = filledAmount(for: index)
        
        if filledAmount >= 1.0 {
            // Fully filled star
            Image(systemName: "star.fill")
                .font(.system(size: starSize))
                .foregroundColor(ratingColor)
        } else if filledAmount > 0.0 {
            // Partially filled star
            ZStack {
                Image(systemName: "star")
                    .font(.system(size: starSize))
                    .foregroundColor(emptyStarColor)
                
                Image(systemName: "star.fill")
                    .font(.system(size: starSize))
                    .foregroundColor(ratingColor)
                    .mask(
                        Rectangle()
                            .frame(width: starSize * filledAmount, height: starSize)
                            .offset(x: -starSize * (1 - filledAmount) / 2)
                    )
            }
        } else {
            // Empty star
            Image(systemName: "star")
                .font(.system(size: starSize))
                .foregroundColor(emptyStarColor)
        }
    }
    
    private func filledAmount(for index: Int) -> Double {
        let starRating = rating - Double(index)
        return max(0, min(1, starRating))
    }
}

// MARK: - Restaurant Rating View

/// Specialized view for restaurant ratings with additional info
struct RestaurantRatingView: View {
    let place: Place
    let showReviewCount: Bool
    let showStatus: Bool
    
    init(
        place: Place,
        showReviewCount: Bool = true,
        showStatus: Bool = true
    ) {
        self.place = place
        self.showReviewCount = showReviewCount
        self.showStatus = showStatus
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Rating stars
            if let rating = place.rating {
                StarRatingView(
                    rating: rating,
                    starSize: 14,
                    showRating: true
                )
            } else {
                Text("No Rating")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Review count
            if showReviewCount, let stats = place.stats, let totalRatings = stats.totalRatings {
                Text("\(totalRatings) reviews")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Open/Closed status
            if showStatus {
                HStack(spacing: 4) {
                    Circle()
                        .fill(place.isOpen ? .green : .red)
                        .frame(width: 6, height: 6)
                    
                    Text(place.statusText)
                        .font(.caption2)
                        .foregroundColor(place.isOpen ? .green : .red)
                }
            }
        }
    }
}

// MARK: - Compact Rating View

/// Compact rating view for list items
struct CompactRatingView: View {
    let rating: Double?
    let reviewCount: Int?
    let isOpen: Bool
    
    init(rating: Double?, reviewCount: Int? = nil, isOpen: Bool = false) {
        self.rating = rating
        self.reviewCount = reviewCount
        self.isOpen = isOpen
    }
    
    var body: some View {
        HStack(spacing: 6) {
            // Rating
            if let rating = rating {
                StarRatingView(
                    rating: rating,
                    starSize: 12,
                    showRating: false
                )
                
                Text(String(format: "%.1f", rating))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No Rating")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Review count
            if let reviewCount = reviewCount {
                Text("(\(reviewCount))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Status indicator
            Circle()
                .fill(isOpen ? .green : .red)
                .frame(width: 4, height: 4)
        }
    }
}

// MARK: - Rating Badge

/// A badge-style rating display
struct RatingBadge: View {
    let rating: Double
    let backgroundColor: Color
    let textColor: Color
    
    init(
        rating: Double,
        backgroundColor: Color = .orange,
        textColor: Color = .white
    ) {
        self.rating = rating
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundColor(textColor)
            
            Text(String(format: "%.1f", rating))
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Rating Summary View

/// A comprehensive rating summary for restaurant details
struct RatingSummaryView: View {
    let place: Place
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main rating
            HStack {
                StarRatingView(
                    rating: place.rating ?? 0,
                    starSize: 20,
                    showRating: true
                )
                
                Spacer()
                
                if let stats = place.stats, let totalRatings = stats.totalRatings {
                    Text("\(totalRatings) reviews")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Price and status
            HStack {
                if let price = place.price {
                    Text(place.priceLevel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(place.isOpen ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(place.statusText)
                        .font(.subheadline)
                        .foregroundColor(place.isOpen ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Basic star rating
        StarRatingView(rating: 4.3)
        
        // Restaurant rating with details
        RestaurantRatingView(
            place: Place(
                fsqId: "test",
                name: "Test Restaurant",
                categories: [],
                distance: nil,
                geocodes: Geocodes(main: Coordinate(latitude: 0, longitude: 0), roof: nil),
                location: PlaceLocation(
                    address: nil,
                    crossStreet: nil,
                    locality: nil,
                    region: nil,
                    postcode: nil,
                    country: nil,
                    formattedAddress: nil
                ),
                popularity: nil,
                price: 2,
                rating: 4.5,
                stats: PlaceStats(totalRatings: 150, totalTips: 25),
                verified: nil,
                hours: PlaceHours(openNow: true, regular: nil),
                photos: nil,
                tel: nil,
                website: nil,
                socialMedia: nil
            )
        )
        
        // Compact rating
        CompactRatingView(rating: 4.2, reviewCount: 89, isOpen: true)
        
        // Rating badge
        RatingBadge(rating: 4.7)
        
        // Rating summary
        RatingSummaryView(
            place: Place(
                fsqId: "test",
                name: "Test Restaurant",
                categories: [],
                distance: nil,
                geocodes: Geocodes(main: Coordinate(latitude: 0, longitude: 0), roof: nil),
                location: PlaceLocation(
                    address: nil,
                    crossStreet: nil,
                    locality: nil,
                    region: nil,
                    postcode: nil,
                    country: nil,
                    formattedAddress: nil
                ),
                popularity: nil,
                price: 3,
                rating: 4.8,
                stats: PlaceStats(totalRatings: 234, totalTips: 45),
                verified: nil,
                hours: PlaceHours(openNow: true, regular: nil),
                photos: nil,
                tel: nil,
                website: nil,
                socialMedia: nil
            )
        )
    }
    .padding()
}
