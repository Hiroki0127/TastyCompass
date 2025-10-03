import SwiftUI
import Foundation
import Combine

/// A SwiftUI view that displays a restaurant in a list row
struct BusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var apiService = BackendAPIService.shared
    @EnvironmentObject private var toastManager: ToastManager
    @State private var isFavorited = false
    @State private var isTogglingFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Optional binding to sync with parent view's favorite state
    @Binding var parentFavoriteState: Bool?
    
    init(
        place: Place,
        parentFavoriteState: Binding<Bool?> = .constant(nil),
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self._parentFavoriteState = parentFavoriteState
        self.onTap = onTap
        self.onFavoriteTap = onFavoriteTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Restaurant image - smaller size
                RestaurantImageView(
                    place: place,
                    size: .thumbnail,
                    cornerRadius: 8
                )
                .frame(width: 60, height: 60)
                .clipped()
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 6) {
                    // Name and category
                    VStack(alignment: .leading, spacing: 2) {
                        Text(place.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let category = place.primaryCategory {
                            Text(category.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    // Rating and distance
                    HStack(spacing: 8) {
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
                    HStack(spacing: 8) {
                        if let price = place.price {
                            Text(place.priceLevel)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(place.isOpen ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text(place.statusText)
                                .font(.caption2)
                                .foregroundColor(place.isOpen ? Color.green : Color.red)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Favorite button
                Button {
                    toggleFavorite()
                    onFavoriteTap?()
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorited ? .red : .gray)
                        .scaleEffect(isFavorited ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isFavorited)
                }
                .disabled(isTogglingFavorite)
                .buttonStyle(PlainButtonStyle())
                .overlay {
                    if isTogglingFavorite {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        // If parent has favorite state, use it first (optimistic)
        if let parentState = parentFavoriteState {
            self.isFavorited = parentState
        }
        
        apiService.checkFavoriteStatus(restaurantId: place.fsqId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to check favorite status: \(error)")
                        // Default to false if check fails
                        self.isFavorited = false
                    }
                },
                receiveValue: { isFavorited in
                    self.isFavorited = isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    private func toggleFavorite() {
        guard !isTogglingFavorite else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Optimistic UI update - immediately toggle the heart
        let previousState = isFavorited
        isFavorited.toggle()
        isTogglingFavorite = true
        
        // Also update parent state if available
        if parentFavoriteState != nil {
            parentFavoriteState = isFavorited
        }
        
        apiService.toggleFavorite(for: place)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isTogglingFavorite = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to toggle favorite: \(error)")
                        // Add error haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                        // Show error toast
                        toastManager.show(Toast(message: "Failed to update favorites", type: .error, duration: 3.0))
                        // Revert optimistic update on failure
                        self.isFavorited = previousState
                        if parentFavoriteState != nil {
                            parentFavoriteState = previousState
                        }
                    }
                },
                receiveValue: { isFavorited in
                    // Add success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Show success toast
                    let message = isFavorited ? "Added to favorites" : "Removed from favorites"
                    toastManager.show(Toast(message: message, type: .success, duration: 2.0))
                    
                    // Update with actual server response
                    self.isFavorited = isFavorited
                    if parentFavoriteState != nil {
                        parentFavoriteState = isFavorited
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Compact Business Row

/// A more compact version for dense lists
struct CompactBusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var apiService = BackendAPIService.shared
    @EnvironmentObject private var toastManager: ToastManager
    @State private var isFavorited = false
    @State private var isTogglingFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Optional binding to sync with parent view's favorite state
    @Binding var parentFavoriteState: Bool?
    
    init(
        place: Place,
        parentFavoriteState: Binding<Bool?> = .constant(nil),
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self._parentFavoriteState = parentFavoriteState
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
                    toggleFavorite()
                    onFavoriteTap?()
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        // If parent has favorite state, use it first (optimistic)
        if let parentState = parentFavoriteState {
            self.isFavorited = parentState
        }
        
        apiService.checkFavoriteStatus(restaurantId: place.fsqId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to check favorite status: \(error)")
                        self.isFavorited = false
                    }
                },
                receiveValue: { isFavorited in
                    self.isFavorited = isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    private func toggleFavorite() {
        guard !isTogglingFavorite else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Optimistic UI update - immediately toggle the heart
        let previousState = isFavorited
        isFavorited.toggle()
        isTogglingFavorite = true
        
        // Also update parent state if available
        if parentFavoriteState != nil {
            parentFavoriteState = isFavorited
        }
        
        apiService.toggleFavorite(for: place)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isTogglingFavorite = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to toggle favorite: \(error)")
                        // Add error haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                        // Show error toast
                        toastManager.show(Toast(message: "Failed to update favorites", type: .error, duration: 3.0))
                        // Revert optimistic update on failure
                        self.isFavorited = previousState
                        if parentFavoriteState != nil {
                            parentFavoriteState = previousState
                        }
                    }
                },
                receiveValue: { isFavorited in
                    // Add success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Show success toast
                    let message = isFavorited ? "Added to favorites" : "Removed from favorites"
                    toastManager.show(Toast(message: message, type: .success, duration: 2.0))
                    
                    // Update with actual server response
                    self.isFavorited = isFavorited
                    if parentFavoriteState != nil {
                        parentFavoriteState = isFavorited
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Grid Business Card

/// A card-style view for grid layouts
struct BusinessCardView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var apiService = BackendAPIService.shared
    @EnvironmentObject private var toastManager: ToastManager
    @State private var isFavorited = false
    @State private var isTogglingFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Optional binding to sync with parent view's favorite state
    @Binding var parentFavoriteState: Bool?
    
    init(
        place: Place,
        parentFavoriteState: Binding<Bool?> = .constant(nil),
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self._parentFavoriteState = parentFavoriteState
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
                        toggleFavorite()
                        onFavoriteTap?()
                    }) {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isFavorited ? .red : .white)
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
                                .fill(place.isOpen ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            
                            Text(place.statusText)
                                .font(.caption)
                                .foregroundColor(place.isOpen ? Color.green : Color.red)
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
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        // If parent has favorite state, use it first (optimistic)
        if let parentState = parentFavoriteState {
            self.isFavorited = parentState
        }
        
        apiService.checkFavoriteStatus(restaurantId: place.fsqId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to check favorite status: \(error)")
                        self.isFavorited = false
                    }
                },
                receiveValue: { isFavorited in
                    self.isFavorited = isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    private func toggleFavorite() {
        guard !isTogglingFavorite else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Optimistic UI update - immediately toggle the heart
        let previousState = isFavorited
        isFavorited.toggle()
        isTogglingFavorite = true
        
        // Also update parent state if available
        if parentFavoriteState != nil {
            parentFavoriteState = isFavorited
        }
        
        apiService.toggleFavorite(for: place)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isTogglingFavorite = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to toggle favorite: \(error)")
                        // Add error haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                        // Show error toast
                        toastManager.show(Toast(message: "Failed to update favorites", type: .error, duration: 3.0))
                        // Revert optimistic update on failure
                        self.isFavorited = previousState
                        if parentFavoriteState != nil {
                            parentFavoriteState = previousState
                        }
                    }
                },
                receiveValue: { isFavorited in
                    // Add success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Show success toast
                    let message = isFavorited ? "Added to favorites" : "Removed from favorites"
                    toastManager.show(Toast(message: message, type: .success, duration: 2.0))
                    
                    // Update with actual server response
                    self.isFavorited = isFavorited
                    if parentFavoriteState != nil {
                        parentFavoriteState = isFavorited
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - List Business Row

/// A simple list-style row without card styling
struct ListBusinessRowView: View {
    let place: Place
    let onTap: (() -> Void)?
    let onFavoriteTap: (() -> Void)?
    
    @StateObject private var apiService = BackendAPIService.shared
    @EnvironmentObject private var toastManager: ToastManager
    @State private var isFavorited = false
    @State private var isTogglingFavorite = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // Optional binding to sync with parent view's favorite state
    @Binding var parentFavoriteState: Bool?
    
    init(
        place: Place,
        parentFavoriteState: Binding<Bool?> = .constant(nil),
        onTap: (() -> Void)? = nil,
        onFavoriteTap: (() -> Void)? = nil
    ) {
        self.place = place
        self._parentFavoriteState = parentFavoriteState
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
                    toggleFavorite()
                    onFavoriteTap?()
                }) {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorited ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() {
        // If parent has favorite state, use it first (optimistic)
        if let parentState = parentFavoriteState {
            self.isFavorited = parentState
        }
        
        apiService.checkFavoriteStatus(restaurantId: place.fsqId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to check favorite status: \(error)")
                        self.isFavorited = false
                    }
                },
                receiveValue: { isFavorited in
                    self.isFavorited = isFavorited
                }
            )
            .store(in: &cancellables)
    }
    
    private func toggleFavorite() {
        guard !isTogglingFavorite else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Optimistic UI update - immediately toggle the heart
        let previousState = isFavorited
        isFavorited.toggle()
        isTogglingFavorite = true
        
        // Also update parent state if available
        if parentFavoriteState != nil {
            parentFavoriteState = isFavorited
        }
        
        apiService.toggleFavorite(for: place)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isTogglingFavorite = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to toggle favorite: \(error)")
                        // Add error haptic feedback
                        let notificationFeedback = UINotificationFeedbackGenerator()
                        notificationFeedback.notificationOccurred(.error)
                        // Show error toast
                        toastManager.show(Toast(message: "Failed to update favorites", type: .error, duration: 3.0))
                        // Revert optimistic update on failure
                        self.isFavorited = previousState
                        if parentFavoriteState != nil {
                            parentFavoriteState = previousState
                        }
                    }
                },
                receiveValue: { isFavorited in
                    // Add success haptic feedback
                    let notificationFeedback = UINotificationFeedbackGenerator()
                    notificationFeedback.notificationOccurred(.success)
                    
                    // Show success toast
                    let message = isFavorited ? "Added to favorites" : "Removed from favorites"
                    toastManager.show(Toast(message: message, type: .success, duration: 2.0))
                    
                    // Update with actual server response
                    self.isFavorited = isFavorited
                    if parentFavoriteState != nil {
                        parentFavoriteState = isFavorited
                    }
                }
            )
            .store(in: &cancellables)
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
