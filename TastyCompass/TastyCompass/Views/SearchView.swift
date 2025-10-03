import SwiftUI
import Combine
import CoreLocation
import Foundation

/// Main view for searching and displaying restaurants
struct SearchView: View {
    @StateObject private var apiService = BackendAPIService()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var locationManager = LocationManager()
    
    @State private var searchText = ""
    @State private var restaurants: [Place] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilters = false
    @State private var currentFilter = RestaurantFilter()
    @State private var searchCancellable: AnyCancellable?
    @State private var selectedRestaurant: Place?
    
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
            .sheet(item: $selectedRestaurant) { restaurant in
                BusinessDetailsView(place: restaurant)
            }
            .onAppear {
                // Just check location status, don't auto-search
                checkLocationStatus()
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
                    selectedRestaurant = restaurant
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
            Image(systemName: message.contains("Location") || message.contains("location") ? "location.slash" : "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(message.contains("Location") || message.contains("location") ? "Location Access Needed" : "Oops! Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                if message.contains("denied") || message.contains("permission") {
                    Button("Open Settings") {
                        locationManager.openSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Search San Francisco Instead") {
                        errorMessage = nil
                        performSearch()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Try Again") {
                        errorMessage = nil
                        requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
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
            
            if searchText.isEmpty && restaurants.isEmpty {
                Button {
                    requestLocationPermission()
                    // Wait a bit for location to be acquired
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        performSearch()
                    }
                } label: {
                    Label("Search Nearby", systemImage: "location.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Private Methods
    
    private func checkLocationStatus() {
        // Just check if we need to request permission, but don't auto-search
        if locationManager.authorizationStatus == .notDetermined {
            print("📍 Location permission not determined yet")
        } else if locationManager.authorizationStatus == .denied || locationManager.authorizationStatus == .restricted {
            print("📍 Location permission denied or restricted")
        } else {
            // Permission granted, start updating location in background
            print("📍 Location permission already granted")
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestPermission { granted in
            if !granted {
                errorMessage = locationManager.locationError ?? "Location permission is required to find nearby restaurants"
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
        
        print("🔍 Starting search...")
        print("📍 Current location: \(locationManager.currentLocation?.description ?? "No location")")
        print("🔑 API Key configured: \(!ConfigurationManager.shared.googlePlacesAPIKey.isEmpty)")
        
        if let location = locationManager.currentLocation {
            print("📍 Using location-based search")
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
                        print("❌ Location search failed: \(error)")
                        errorMessage = "Location search failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { places in
                    print("✅ Found \(places.count) restaurants")
                    restaurants = places
                    isLoading = false
                }
            )
            .store(in: &cancellables)
        } else {
            print("🏙️ Using city-based search (San Francisco)")
            // Fallback to city search - create a San Francisco location
            let sanFranciscoLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
            apiService.searchRestaurants(
                with: currentFilter,
                near: sanFranciscoLocation,
                query: searchText.isEmpty ? nil : searchText
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ City search failed: \(error)")
                        errorMessage = "City search failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { places in
                    print("✅ Found \(places.count) restaurants in San Francisco")
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
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationError: String?
    
    private var permissionCompletion: ((Bool) -> Void)?
    
    override init() {
        self.authorizationStatus = CLLocationManager.authorizationStatus()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Good balance of accuracy and battery
        locationManager.distanceFilter = 100 // Update every 100 meters
        
        // Start updating location if already authorized
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        permissionCompletion = completion
        
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            completion(true)
        case .denied, .restricted:
            locationError = "Location access denied. Please enable location services in Settings."
            completion(false)
        case .notDetermined:
            print("📍 Requesting location permission...")
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            completion(false)
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Only update if the location is recent and accurate
        let age = abs(location.timestamp.timeIntervalSinceNow)
        if age < 15 && location.horizontalAccuracy >= 0 {
            currentLocation = location
            locationError = nil
            print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
        locationError = error.localizedDescription
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // iOS 14+ delegate method
        let status = manager.authorizationStatus
        print("📍 Authorization status changed: \(status.rawValue)")
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            permissionCompletion?(true)
            permissionCompletion = nil
        case .denied, .restricted:
            locationError = "Location access denied. Please enable location services in Settings."
            permissionCompletion?(false)
            permissionCompletion = nil
        case .notDetermined:
            break
        @unknown default:
            permissionCompletion?(false)
            permissionCompletion = nil
        }
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}
