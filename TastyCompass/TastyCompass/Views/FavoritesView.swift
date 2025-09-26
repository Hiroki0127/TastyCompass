import SwiftUI
import Combine
import Foundation

/// View for displaying and managing favorite restaurants
struct FavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var searchText = ""
    @State private var sortOption: FavoritesSortOption = .name
    @State private var showingClearAlert = false
    @State private var selectedPlace: Place?
    
    private var filteredFavorites: [Place] {
        let searchResults = searchText.isEmpty ? 
            favoritesManager.favoritePlaces : 
            favoritesManager.searchFavorites(query: searchText)
        
        return favoritesManager.sortFavorites(by: sortOption)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if favoritesManager.hasFavorites {
                    // Search and sort controls
                    controlsView
                    
                    // Favorites list
                    favoritesListView
                } else {
                    // Empty state
                    emptyStateView
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if favoritesManager.hasFavorites {
                        Menu {
                            Button("Sort by Name") {
                                sortOption = .name
                            }
                            Button("Sort by Rating") {
                                sortOption = .rating
                            }
                            Button("Sort by Price") {
                                sortOption = .price
                            }
                            Button("Sort by Date Added") {
                                sortOption = .dateAdded
                            }
                            
                            Divider()
                            
                            Button("Clear All Favorites", role: .destructive) {
                                showingClearAlert = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Clear All Favorites", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    favoritesManager.clearAllFavorites()
                }
            } message: {
                Text("This will remove all \(favoritesManager.favoritesCount) favorite restaurants. This action cannot be undone.")
            }
            .sheet(item: $selectedPlace) { place in
                // This will be implemented when we create BusinessDetailsView
                Text("Restaurant Details for \(place.name)")
                    .padding()
            }
        }
    }
    
    // MARK: - Controls View
    
    private var controlsView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search favorites...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Sort and stats
            HStack {
                // Sort picker
                Picker("Sort by", selection: $sortOption) {
                    ForEach(FavoritesSortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Stats
                Text("\(filteredFavorites.count) favorites")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Favorites List
    
    private var favoritesListView: some View {
        List {
            ForEach(filteredFavorites) { place in
                BusinessRowView(place: place) {
                    selectedPlace = place
                } onFavoriteTap: {
                    // Favorite action is handled by BusinessRowView
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteFavorites)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start exploring restaurants and tap the heart icon to add them to your favorites")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Explore Restaurants") {
                // This would navigate to the search tab
                // Implementation depends on your navigation structure
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Private Methods
    
    private func deleteFavorites(offsets: IndexSet) {
        for index in offsets {
            let place = filteredFavorites[index]
            favoritesManager.removeFromFavorites(place)
        }
    }
}

// MARK: - Favorites Stats View

/// A view showing statistics about favorites
struct FavoritesStatsView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Favorites")
                .font(.headline)
            
            let stats = favoritesManager.favoritesStats
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(stats.totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(stats.formattedAverageRating)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Avg Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(stats.mostCommonPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Most Common")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !stats.topCategories.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top Categories")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(stats.topCategories.prefix(3)), id: \.0) { category, count in
                        HStack {
                            Text(category)
                                .font(.caption)
                            Spacer()
                            Text("\(count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Favorites Grid View

/// A grid layout for favorites
struct FavoritesGridView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var searchText = ""
    @State private var sortOption: FavoritesSortOption = .name
    @State private var selectedPlace: Place?
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredFavorites: [Place] {
        let searchResults = searchText.isEmpty ? 
            favoritesManager.favoritePlaces : 
            favoritesManager.searchFavorites(query: searchText)
        
        return favoritesManager.sortFavorites(by: sortOption)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if favoritesManager.hasFavorites {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search favorites...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredFavorites) { place in
                                BusinessCardView(place: place) {
                                    selectedPlace = place
                                } onFavoriteTap: {
                                    // Favorite action is handled by BusinessCardView
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "heart")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        Text("No Favorites Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start exploring restaurants and tap the heart icon to add them to your favorites")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedPlace) { place in
                // This will be implemented when we create BusinessDetailsView
                Text("Restaurant Details for \(place.name)")
                    .padding()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesView()
}

#Preview("Grid View") {
    FavoritesGridView()
}

#Preview("Stats View") {
    FavoritesStatsView()
        .padding()
}
