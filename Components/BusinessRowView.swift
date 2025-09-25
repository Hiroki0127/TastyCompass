import SwiftUI

/// A SwiftUI view that displays a restaurant in a list row
struct BusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    init(
        place: Place,
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self.onTap = onTap
        self.onFavoriteTap = onFavoriteTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Restaurant image
                RestaurantImageView(
                    place: place,
                    size: .medium,
                    cornerRadius: 8
                )
                .frame(width: 80, height: 80)
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 4) {
                    // Name and category
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let category = place.primaryCategory {
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Rating and distance
                    HStack {
                        CompactRatingView(
                            rating: place.rating,
                            reviewCount: place.stats?.totalRatings,
                            isOpen: place.isOpen
                        )
                        
                        Spacer()
                        
                        if let distance = place.distance {
                            Text(place.formattedDistance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Price and status
                    HStack {
                        if let price = place.price {
                            Text(place.priceLevel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(place.isOpen ? .green : .red)
                                .frame(width: 6, height: 6)
                            
                            Text(place.statusText)
                                .font(.caption)
                                .foregroundColor(place.isOpen ? .green : .red)
                        }
                    }
                }
                
                // Favorite button
                Button(action: {
                    favoritesManager.toggleFavorite(place)
                    onFavoriteTap?()
                }) {
                    Image(systemName: favoritesManager.isFavorite(place) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(favoritesManager.isFavorite(place) ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Compact Business Row

/// A more compact version for dense lists
struct CompactBusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    init(
        place: Place,
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self.onTap = onTap
        self.onFavoriteTap = onFavoriteTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Restaurant image
                RestaurantImageView(
                    place: place,
                    size: .thumbnail,
                    cornerRadius: 6
                )
                .frame(width: 60, height: 60)
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let category = place.primaryCategory {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if let rating = place.rating {
                            StarRatingView(
                                rating: rating,
                                starSize: 10,
                                showRating: false
                            )
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let distance = place.distance {
                            Text(place.formattedDistance)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Favorite button
                Button(action: {
                    favoritesManager.toggleFavorite(place)
                    onFavoriteTap?()
                }) {
                    Image(systemName: favoritesManager.isFavorite(place) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(favoritesManager.isFavorite(place) ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Grid Business Card

/// A card-style view for grid layouts
struct BusinessCardView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    init(
        place: Place,
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self.onTap = onTap
        self.onFavoriteTap = onFavoriteTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Restaurant image
                ZStack(alignment: .topTrailing) {
                    RestaurantImageView(
                        place: place,
                        size: .medium,
                        cornerRadius: 8
                    )
                    .frame(height: 120)
                    .clipped()
                    
                    // Favorite button
                    Button(action: {
                        favoritesManager.toggleFavorite(place)
                        onFavoriteTap?()
                    }) {
                        Image(systemName: favoritesManager.isFavorite(place) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(favoritesManager.isFavorite(place) ? .red : .white)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 4) {
                    Text(place.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let category = place.primaryCategory {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        if let rating = place.rating {
                            StarRatingView(
                                rating: rating,
                                starSize: 12,
                                showRating: false
                            )
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let distance = place.distance {
                            Text(place.formattedDistance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        if let price = place.price {
                            Text(place.priceLevel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(place.isOpen ? .green : .red)
                                .frame(width: 6, height: 6)
                            
                            Text(place.statusText)
                                .font(.caption)
                                .foregroundColor(place.isOpen ? .green : .red)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - List Business Row

/// A simple list-style row without card styling
struct ListBusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    init(
        place: Place,
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self.onTap = onTap
        self.onFavoriteTap = onFavoriteTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Restaurant image
                RestaurantImageView(
                    place: place,
                    size: .thumbnail,
                    cornerRadius: 6
                )
                .frame(width: 50, height: 50)
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack {
                        if let rating = place.rating {
                            StarRatingView(
                                rating: rating,
                                starSize: 10,
                                showRating: false
                            )
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let distance = place.distance {
                            Text(place.formattedDistance)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Favorite button
                Button(action: {
                    favoritesManager.toggleFavorite(place)
                    onFavoriteTap?()
                }) {
                    Image(systemName: favoritesManager.isFavorite(place) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(favoritesManager.isFavorite(place) ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Standard business row
        BusinessRowView(
            place: Place(
                fsqId: "test1",
                name: "The Amazing Restaurant",
                categories: [Category(id: 1, name: "Italian", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png"))],
                distance: 500,
                geocodes: Geocodes(main: Coordinate(latitude: 0, longitude: 0), roof: nil),
                location: PlaceLocation(
                    address: "123 Main St",
                    crossStreet: nil,
                    locality: "San Francisco",
                    region: "CA",
                    postcode: "94102",
                    country: "US",
                    formattedAddress: "123 Main St, San Francisco, CA 94102"
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
        
        // Compact business row
        CompactBusinessRowView(
            place: Place(
                fsqId: "test2",
                name: "Quick Bites",
                categories: [Category(id: 2, name: "Fast Food", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png"))],
                distance: 200,
                geocodes: Geocodes(main: Coordinate(latitude: 0, longitude: 0), roof: nil),
                location: PlaceLocation(
                    address: "456 Oak Ave",
                    crossStreet: nil,
                    locality: "San Francisco",
                    region: "CA",
                    postcode: "94103",
                    country: "US",
                    formattedAddress: "456 Oak Ave, San Francisco, CA 94103"
                ),
                popularity: nil,
                price: 1,
                rating: 3.8,
                stats: PlaceStats(totalRatings: 89, totalTips: 12),
                verified: nil,
                hours: PlaceHours(openNow: false, regular: nil),
                photos: nil,
                tel: nil,
                website: nil,
                socialMedia: nil
            )
        )
        
        // Business card
        BusinessCardView(
            place: Place(
                fsqId: "test3",
                name: "Fine Dining Experience",
                categories: [Category(id: 3, name: "Fine Dining", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png"))],
                distance: 1000,
                geocodes: Geocodes(main: Coordinate(latitude: 0, longitude: 0), roof: nil),
                location: PlaceLocation(
                    address: "789 Pine St",
                    crossStreet: nil,
                    locality: "San Francisco",
                    region: "CA",
                    postcode: "94104",
                    country: "US",
                    formattedAddress: "789 Pine St, San Francisco, CA 94104"
                ),
                popularity: nil,
                price: 4,
                rating: 4.9,
                stats: PlaceStats(totalRatings: 234, totalTips: 45),
                verified: nil,
                hours: PlaceHours(openNow: true, regular: nil),
                photos: nil,
                tel: nil,
                website: nil,
                socialMedia: nil
            )
        )
        .frame(width: 200)
    }
    .padding()
}
