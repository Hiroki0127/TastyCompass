import Foundation
import Combine
import SwiftUI

/// Manages favorite restaurants with persistent local storage
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoritePlaces: [Place] = []
    
    private let userDefaults = UserDefaults.standard
    private let favoritesKey = "FavoritePlaces"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// Adds a place to favorites
    /// - Parameter place: Place to add to favorites
    func addToFavorites(_ place: Place) {
        guard !isFavorite(place) else { return }
        
        favoritePlaces.append(place)
        saveFavorites()
        
        print("✅ Added '\(place.name)' to favorites")
    }
    
    /// Removes a place from favorites
    /// - Parameter place: Place to remove from favorites
    func removeFromFavorites(_ place: Place) {
        favoritePlaces.removeAll { $0.fsqId == place.fsqId }
        saveFavorites()
        
        print("✅ Removed '\(place.name)' from favorites")
    }
    
    /// Toggles favorite status for a place
    /// - Parameter place: Place to toggle
    func toggleFavorite(_ place: Place) {
        if isFavorite(place) {
            removeFromFavorites(place)
        } else {
            addToFavorites(place)
        }
    }
    
    /// Checks if a place is in favorites
    /// - Parameter place: Place to check
    /// - Returns: True if place is favorited
    func isFavorite(_ place: Place) -> Bool {
        return favoritePlaces.contains { $0.fsqId == place.fsqId }
    }
    
    /// Gets favorite status for a place ID
    /// - Parameter placeId: Place ID to check
    /// - Returns: True if place is favorited
    func isFavorite(placeId: String) -> Bool {
        return favoritePlaces.contains { $0.fsqId == placeId }
    }
    
    /// Removes all favorites
    func clearAllFavorites() {
        favoritePlaces.removeAll()
        saveFavorites()
        
        print("✅ Cleared all favorites")
    }
    
    /// Gets the count of favorite places
    var favoritesCount: Int {
        return favoritePlaces.count
    }
    
    /// Checks if there are any favorites
    var hasFavorites: Bool {
        return !favoritePlaces.isEmpty
    }
    
    // MARK: - Search and Filter Favorites
    
    /// Searches favorites by name
    /// - Parameter query: Search query
    /// - Returns: Filtered array of favorite places
    func searchFavorites(query: String) -> [Place] {
        guard !query.isEmpty else { return favoritePlaces }
        
        return favoritePlaces.filter { place in
            place.name.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Filters favorites by category
    /// - Parameter categoryName: Category name to filter by
    /// - Returns: Filtered array of favorite places
    func filterFavorites(by categoryName: String) -> [Place] {
        return favoritePlaces.filter { place in
            place.categories.contains { $0.name.localizedCaseInsensitiveContains(categoryName) }
        }
    }
    
    /// Sorts favorites by different criteria
    /// - Parameter sortBy: Sort criteria
    /// - Returns: Sorted array of favorite places
    func sortFavorites(by sortBy: FavoritesSortOption) -> [Place] {
        switch sortBy {
        case .name:
            return favoritePlaces.sorted { $0.name < $1.name }
        case .rating:
            return favoritePlaces.sorted { (place1, place2) in
                let rating1 = place1.rating ?? 0
                let rating2 = place2.rating ?? 0
                return rating1 > rating2
            }
        case .price:
            return favoritePlaces.sorted { (place1, place2) in
                let price1 = place1.price ?? 0
                let price2 = place2.price ?? 0
                return price1 < price2
            }
        case .dateAdded:
            // Since we don't track date added, we'll use the current order
            return favoritePlaces
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads favorites from UserDefaults
    private func loadFavorites() {
        guard let data = userDefaults.data(forKey: favoritesKey) else {
            print("📝 No saved favorites found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            favoritePlaces = try decoder.decode([Place].self, from: data)
            print("✅ Loaded \(favoritePlaces.count) favorites from storage")
        } catch {
            print("❌ Failed to load favorites: \(error.localizedDescription)")
            favoritePlaces = []
        }
    }
    
    /// Saves favorites to UserDefaults
    private func saveFavorites() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favoritePlaces)
            userDefaults.set(data, forKey: favoritesKey)
            print("💾 Saved \(favoritePlaces.count) favorites to storage")
        } catch {
            print("❌ Failed to save favorites: \(error.localizedDescription)")
        }
    }
}

// MARK: - Favorites Sort Options

enum FavoritesSortOption: String, CaseIterable {
    case name = "Name"
    case rating = "Rating"
    case price = "Price"
    case dateAdded = "Date Added"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Favorites Statistics

extension FavoritesManager {
    
    /// Gets statistics about favorites
    var favoritesStats: FavoritesStats {
        let totalCount = favoritePlaces.count
        let averageRating = favoritePlaces.compactMap { $0.rating }.reduce(0, +) / Double(max(totalCount, 1))
        let priceDistribution = getPriceDistribution()
        let topCategories = getTopCategories()
        
        return FavoritesStats(
            totalCount: totalCount,
            averageRating: averageRating,
            priceDistribution: priceDistribution,
            topCategories: topCategories
        )
    }
    
    /// Gets price distribution of favorites
    private func getPriceDistribution() -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        
        for place in favoritePlaces {
            let price = place.price ?? 0
            distribution[price, default: 0] += 1
        }
        
        return distribution
    }
    
    /// Gets top categories from favorites
    private func getTopCategories() -> [(String, Int)] {
        var categoryCount: [String: Int] = [:]
        
        for place in favoritePlaces {
            for category in place.categories {
                categoryCount[category.name, default: 0] += 1
            }
        }
        
        return categoryCount.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
}

// MARK: - Favorites Statistics Model

struct FavoritesStats {
    let totalCount: Int
    let averageRating: Double
    let priceDistribution: [Int: Int]
    let topCategories: [(String, Int)]
    
    var formattedAverageRating: String {
        return String(format: "%.1f", averageRating)
    }
    
    var mostCommonPrice: String {
        guard let maxPrice = priceDistribution.max(by: { $0.value < $1.value })?.key else {
            return "N/A"
        }
        return String(repeating: "$", count: maxPrice)
    }
    
    var topCategory: String {
        return topCategories.first?.0 ?? "N/A"
    }
}
