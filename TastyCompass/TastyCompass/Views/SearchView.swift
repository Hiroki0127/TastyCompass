import SwiftUI
import Combine
import CoreLocation
import Foundation

/// Main view for searching and displaying restaurants
struct SearchView: View {
    @StateObject private var apiService = FoursquareAPIService.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchText = ""
    @State private var restaurants: [Place] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilters = false
    @State private var currentFilter = RestaurantFilter()
    @State private var searchCancellable: AnyCancellable?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter bar
                filterBar
                
                // Content
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if restaurants.isEmpty {
                    emptyStateView
                } else {
                    restaurantListView
                }
            }
            .navigationTitle("Restaurants")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters = true
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView(filter: $currentFilter) {
                    performSearch()
                }
            }
            .onAppear {
                requestLocationPermission()
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search restaurants...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchText) { _ in
                    debounceSearch()
                }
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                    restaurants = []
                    errorMessage = nil
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Price filter
                if currentFilter.priceRange != .all {
                    FilterChip(
                        title: currentFilter.priceRange.displayName,
                        isSelected: true,
                        onTap: {
                            currentFilter.priceRange = .all
                            performSearch()
                        }
                    )
                }
                
                // Rating filter
                if currentFilter.minRating > 0 {
                    FilterChip(
                        title: "\(String(format: "%.1f", currentFilter.minRating))+ stars",
                        isSelected: true,
                        onTap: {
                            currentFilter.minRating = 0
                            performSearch()
                        }
                    )
                }
                
                // Distance filter
                if currentFilter.maxDistance < 25 {
                    FilterChip(
                        title: "\(String(format: "%.1f", currentFilter.maxDistance)) mi",
                        isSelected: true,
                        onTap: {
                            currentFilter.maxDistance = 25
                            performSearch()
                        }
                    )
                }
                
                // Open now filter
                if currentFilter.openNow {
                    FilterChip(
                        title: "Open Now",
                        isSelected: true,
                        onTap: {
                            currentFilter.openNow = false
                            performSearch()
                        }
                    )
                }
                
                // Sort filter
                if currentFilter.sortBy != .distance {
                    FilterChip(
                        title: "Sort: \(currentFilter.sortBy.displayName)",
                        isSelected: true,
                        onTap: {
                            currentFilter.sortBy = .distance
                            performSearch()
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Restaurant List
    
    private var restaurantListView: some View {
        List {
            ForEach(restaurants) { restaurant in
                BusinessRowView(place: restaurant) {
                    // Navigate to restaurant details
                    // This will be implemented when we create BusinessDetailsView
                } onFavoriteTap: {
                    // Favorite action is handled by BusinessRowView
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            performSearch()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Finding restaurants...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Oops! Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                performSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No restaurants found")
                .font(.headline)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if searchText.isEmpty {
                Button("Search Nearby") {
                    searchText = ""
                    performSearch()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Private Methods
    
    private func requestLocationPermission() {
        locationManager.requestPermission { granted in
            if granted {
                performSearch()
            } else {
                errorMessage = "Location permission is required to find nearby restaurants"
            }
        }
    }
    
    private func debounceSearch() {
        searchCancellable?.cancel()
        searchCancellable = Just(searchText)
            .delay(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { _ in
                if !searchText.isEmpty {
                    performSearch()
                }
            }
    }
    
    private func performSearch() {
        isLoading = true
        errorMessage = nil
        
        if let location = locationManager.currentLocation {
            // Search by location
            apiService.searchRestaurants(
                with: currentFilter,
                near: location,
                query: searchText.isEmpty ? nil : searchText
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { places in
                    restaurants = places
                    isLoading = false
                }
            )
            .store(in: &cancellables)
        } else {
            // Fallback to city search
            apiService.searchRestaurants(
                query: searchText.isEmpty ? nil : searchText,
                in: "San Francisco" // Default city
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { places in
                    restaurants = places
                    isLoading = false
                }
            )
            .store(in: &cancellables)
        }
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.orange : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            // Completion will be called in delegate method
        @unknown default:
            completion(false)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
