import SwiftUI
import MapKit
import UIKit
import Combine

/// Detailed view for displaying restaurant information
struct BusinessDetailsView: View {
    let place: Place
    @StateObject private var apiService = BackendAPIService.shared
    @EnvironmentObject private var toastManager: ToastManager
    
    @State private var showingShareSheet = false
    @State private var showingMap = false
    @State private var showingPhotoGallery = false
    @State private var selectedPhotoIndex = 0
    @State private var region: MKCoordinateRegion
    @State private var detailedPlace: Place?
    @State private var isLoadingDetails = false
    @State private var isFavorited = false
    @State private var isTogglingFavorite = false
    @State private var refreshID = UUID() // Force view refresh
    
    // Review states
    @State private var reviews: [Review] = []
    @State private var userReview: Review?
    @State private var reviewStats: ReviewStats?
    @State private var isLoadingReviews = false
    @State private var showingReviewForm = false
    @State private var showingAllReviews = false
    
    // Google Reviews
    @State private var showingAllGoogleReviews = false
    
    @State private var cancellables = Set<AnyCancellable>()
    
    // Optional binding to sync with parent view's favorite state
    @Binding var parentFavoriteState: Bool?
    
    // Computed property for the effective favorite state
    private var effectiveFavoriteState: Bool {
        return parentFavoriteState ?? isFavorited
    }
    
    init(place: Place, parentFavoriteState: Binding<Bool?>? = nil) {
        self.place = place
        self._parentFavoriteState = parentFavoriteState ?? .constant(nil)
        self._region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: place.geocodes.main.latitude,
                longitude: place.geocodes.main.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                heroImageView
                
                // Main content
                VStack(alignment: .leading, spacing: 20) {
                    // Header info
                    headerView
                    
                    // Rating and stats
                    ratingStatsView
                    
                    // Contact information
                    contactView
                    
                    // Hours information
                    hoursView
                    
                    // Photos section
                    photosView
                    
                    // Map section
                    mapView
                    
                    // Reviews section
                    reviewsView
                    
                    // Categories
                    categoriesView
                }
                .padding()
            }
        }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    // Share button
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                }
            }
        })
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(isPresented: $showingMap) {
            MapView(region: $region, place: place)
        }
        .fullScreenCover(isPresented: $showingPhotoGallery) {
            PhotoGalleryView(
                photos: detailedPlace?.photos ?? place.photos ?? [],
                selectedIndex: $selectedPhotoIndex
            )
        }
            .onAppear {
                loadPlaceDetails()
                checkFavoriteStatus()
                loadReviews()
            }
       .sheet(isPresented: $showingReviewForm) {
           ReviewFormView(
               restaurantId: place.id,
               restaurantName: place.name,
               existingReview: userReview,
               onSubmit: { request in
                   createReview(request)
               },
               onUpdate: { reviewId, request in
                   updateReview(reviewId, request)
               },
               onCancel: {
                   showingReviewForm = false
               }
           )
       }
        .sheet(isPresented: $showingAllReviews) {
            NavigationView {
                ReviewsListView(
                    reviews: reviews,
                    isLoading: isLoadingReviews,
                    onLoadMore: nil,
                    onHelpfulTap: { reviewId in
                        markReviewHelpful(reviewId)
                    },
                    onReportTap: { reviewId in
                        reportReview(reviewId)
                    }
                )
                .navigationTitle("Reviews")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingAllReviews = false
                        }
                    }
                })
            }
        }
        .sheet(isPresented: $showingAllGoogleReviews) {
            NavigationView {
                GoogleReviewsListView(
                    restaurantId: place.id,
                    restaurantName: place.name
                )
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingAllGoogleReviews = false
                        }
                    }
                })
            }
        }
    }
    
    // MARK: - Hero Image View
    
    private var heroImageView: some View {
        Button {
            // Open photo gallery starting at first photo
            if place.photos?.isEmpty == false {
                selectedPhotoIndex = 0
                showingPhotoGallery = true
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                RestaurantImageView(
                    place: place,
                    size: .large,
                    cornerRadius: 0
                )
                .frame(height: 250)
                .clipped()
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Status badge and photo count
                VStack {
                    HStack {
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            StatusBadge(isOpen: place.isOpen)
                            
                            // Photo count indicator
                            if let photoCount = detailedPlace?.photos?.count ?? place.photos?.count, photoCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.stack")
                                        .font(.caption)
                                    Text("\(photoCount)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(place.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let category = place.primaryCategory {
                        HStack {
                            CategoryIconView(category: category, size: 20)
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(place.location.displayAddress)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Favorite button
                Button {
                    toggleFavorite()
                } label: {
                    ZStack {
                        Image(systemName: effectiveFavoriteState ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(effectiveFavoriteState ? .red : .gray)
                            .scaleEffect(effectiveFavoriteState ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: effectiveFavoriteState)
                            .onAppear {
                                print("❤️ Heart icon appeared - effectiveFavoriteState: \(effectiveFavoriteState)")
                                print("❤️ Heart icon color: \(effectiveFavoriteState ? "RED" : "GRAY")")
                            }
                        
                        if isTogglingFavorite {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.white)
                        }
                    }
                }
                .id(refreshID) // Force view refresh when refreshID changes
                .disabled(isTogglingFavorite)
            }
        }
    }
    
    // MARK: - Rating Stats View
    
    private var ratingStatsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rating (clickable to show reviews)
            if let rating = place.rating {
                Button(action: {
                    print("🔘 Rating button tapped!")
                    print("🔘 Restaurant ID: \(place.id)")
                    print("🔘 Restaurant name: \(place.name)")
                    showingAllGoogleReviews = true
                }) {
                    HStack {
                        StarRatingView(
                            rating: rating,
                            starSize: 20,
                            showRating: true
                        )
                        
                        Spacer()
                        
                        if let stats = place.stats, let totalRatings = stats.totalRatings {
                            Text("\(totalRatings) reviews")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .background(Color.blue.opacity(0.1))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Price and distance
            HStack {
                if let price = place.price {
                    Text(place.priceLevel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                if let distance = place.distance {
                    Text(place.formattedDistance)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Contact View
    
    private var contactView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                if let phone = place.tel {
                    ContactRow(
                        icon: "phone.fill",
                        title: "Phone",
                        value: phone,
                        action: {
                            if let url = URL(string: "tel:\(phone)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let website = place.website {
                    ContactRow(
                        icon: "globe",
                        title: "Website",
                        value: website,
                        action: {
                            if let url = URL(string: website) {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                ContactRow(
                    icon: "location.fill",
                    title: "Address",
                    value: place.location.displayAddress,
                    action: {
                        showingMap = true
                    }
                )
                
                // Directions button
                ContactRow(
                    icon: "map.fill",
                    title: "Directions",
                    value: "Get directions in Maps",
                    action: {
                        openDirections()
                    }
                )
            }
        }
    }
    
    // MARK: - Hours View
    
    private var hoursView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hours")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Circle()
                    .fill(place.isOpen ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(place.statusText)
                    .font(.subheadline)
                    .foregroundColor(place.isOpen ? Color.green : Color.red)
                
                Spacer()
            }
            
            if let hours = place.hours, let regular = hours.regular {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(regular, id: \.day) { dayHours in
                        HStack {
                            Text(dayName(for: dayHours.day))
                                .font(.caption)
                                .frame(width: 60, alignment: .leading)
                            
                            Text("\(dayHours.open) - \(dayHours.close)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                    }
                }
            } else {
                Text("Hours not available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Photos View
    
    private var photosView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photos")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let photos = detailedPlace?.photos ?? place.photos, !photos.isEmpty {
                    Text("(\(photos.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if isLoadingDetails {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading more photos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if let photos = detailedPlace?.photos ?? place.photos, !photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            Button {
                                selectedPhotoIndex = index
                                showingPhotoGallery = true
                            } label: {
                                CachedAsyncImage(
                                    url: photo.photoURL,
                                    size: .medium
                                ) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 140, height: 140)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                } placeholder: {
                                    ZStack {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 140, height: 140)
                                            .cornerRadius(12)
                                        
                                        ProgressView()
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No photos available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Map View
    
    private var mapView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            Button(action: {
                showingMap = true
            }) {
                MapView(region: $region, place: place)
                    .frame(height: 200)
                    .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Reviews View
    
    private var reviewsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with review stats
            if let stats = reviewStats, stats.totalRatings > 0 {
                ReviewStatsView(
                    averageRating: stats.averageRating,
                    totalRatings: stats.totalRatings,
                    ratingDistribution: stats.ratingDistribution
                )
            }
            
            // User review section
            if let userReview = userReview {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Your Review")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Edit") {
                            showingReviewForm = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    ReviewRowView(review: userReview)
                }
            } else {
                // Write review button
                Button(action: {
                    showingReviewForm = true
                }) {
                    HStack {
                        Image(systemName: "star")
                            .foregroundColor(.orange)
                        
                        Text("Write a Review")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Recent reviews section
            if !reviews.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Recent Reviews")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("View All") {
                            showingAllReviews = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    // Show first 2 reviews
                    ForEach(Array(reviews.prefix(2))) { review in
                        ReviewRowView(
                            review: review,
                            onHelpfulTap: {
                                markReviewHelpful(review.id)
                            },
                            onReportTap: {
                                reportReview(review.id)
                            }
                        )
                    }
                }
            } else if isLoadingReviews {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    Text("Loading reviews...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if reviewStats?.totalRatings == 0 {
                VStack(spacing: 8) {
                    Image(systemName: "star.slash")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("No reviews yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to share your experience!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
    
    // MARK: - Categories View
    
    private var categoriesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(place.categories, id: \.id) { category in
                    HStack {
                        CategoryIconView(category: category, size: 16)
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func dayName(for day: Int) -> String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[day]
    }
    
    private func loadPlaceDetails() {
        // Only load details if we don't have many photos yet
        if (place.photos?.count ?? 0) <= 1 {
            print("🔄 Loading detailed photos for: \(place.name)")
            isLoadingDetails = true
            
            apiService.getRestaurantDetails(placeId: place.fsqId)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        isLoadingDetails = false
                        if case .failure(let error) = completion {
                            print("❌ Failed to load place details: \(error)")
                        }
                    },
                    receiveValue: { detailedPlace in
                        self.detailedPlace = detailedPlace
                        print("✅ Loaded \(detailedPlace.photos?.count ?? 0) photos for \(detailedPlace.name)")
                        if let photos = detailedPlace.photos {
                            print("📸 Photo details:")
                            for (index, photo) in photos.enumerated() {
                                print("  \(index + 1): \(photo.photoURL.prefix(80))...")
                            }
                        }
                    }
                )
                .store(in: &cancellables)
        } else {
            print("📸 Already have \(place.photos?.count ?? 0) photos for \(place.name), skipping details fetch")
        }
    }
    
    private var shareText: String {
        var text = "Check out \(place.name)!"
        if let rating = place.rating {
            text += " ⭐ \(String(format: "%.1f", rating))"
        }
        text += "\n\(place.location.displayAddress)"
        return text
    }
    
    private func openDirections() {
        let latitude = place.geocodes.main.latitude
        let longitude = place.geocodes.main.longitude
        let url = URL(string: "maps://?daddr=\(latitude),\(longitude)")!
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to Apple Maps web URL
            let webURL = URL(string: "https://maps.apple.com/?daddr=\(latitude),\(longitude)")!
            UIApplication.shared.open(webURL)
        }
    }
    
    private func checkFavoriteStatus() {
        print("🔍 Checking favorite status for: \(place.name)")
        
        // If parent has favorite state, use it first (optimistic)
        if let parentState = parentFavoriteState {
            self.isFavorited = parentState
            print("✅ Using parent favorite state for \(place.name): \(parentState)")
        }
        
        apiService.checkFavoriteStatus(restaurantId: place.fsqId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to check favorite status: \(error)")
                        // Default to false if check fails
                        self.isFavorited = false
                        if parentFavoriteState != nil {
                            parentFavoriteState = false
                        }
                    }
                },
                receiveValue: { isFavorited in
                    self.isFavorited = isFavorited
                    // Also update parent state if available
                    if parentFavoriteState != nil {
                        parentFavoriteState = isFavorited
                    }
                    print("✅ Favorite status for \(place.name): \(isFavorited)")
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
            print("🔄 Updated parentFavoriteState to: \(isFavorited)")
        }
        
        // Force view refresh
        refreshID = UUID()
        
        print("🔄 Toggling favorite for: \(place.name)")
        print("🔄 Local isFavorited: \(isFavorited)")
        print("🔄 Parent favorite state: \(parentFavoriteState ?? false)")
        print("🔄 Heart should show: \((parentFavoriteState ?? isFavorited) ? "RED" : "GRAY")")
        print("🔄 Refresh ID updated: \(refreshID)")
        
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
                    // Force view refresh
                    self.refreshID = UUID()
                    print("✅ Favorite toggled for \(place.name): \(isFavorited)")
                    print("✅ Refresh ID updated: \(self.refreshID)")
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let isOpen: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(isOpen ? "Open" : "Closed")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Map View

struct MapView: View {
    @Binding var region: MKCoordinateRegion
    let place: Place
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [place]) { place in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: place.geocodes.main.latitude,
                longitude: place.geocodes.main.longitude
            )) {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    Text(place.name)
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: 2)
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ShareSheet>) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareSheet>) {}
}

// MARK: - Photo Gallery View

struct PhotoGalleryView: View {
    let photos: [PlacePhoto]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Photo viewer with swipe
            TabView(selection: $selectedIndex) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    GeometryReader { geometry in
                        CachedAsyncImage(
                            url: photo.photoURL,
                            size: .large
                        ) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        } placeholder: {
                            ZStack {
                                Color.black
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Top overlay with close button and counter
            VStack {
                HStack {
                    // Photo counter
                    Text("\(selectedIndex + 1) of \(photos.count)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                    
                    Spacer()
                    
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - Review Functions Extension

extension BusinessDetailsView {
    
    private func loadReviews() {
        guard apiService.authToken != nil else { return }
        
        isLoadingReviews = true
        
        // Load review stats
        apiService.getReviewStats(for: place.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load review stats: \(error)")
                    }
                    isLoadingReviews = false
                },
                receiveValue: { stats in
                    reviewStats = stats
                }
            )
            .store(in: &cancellables)
        
        // Load reviews
        apiService.getReviews(for: place.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load reviews: \(error)")
                    }
                },
                receiveValue: { response in
                    reviews = response.reviews
                }
            )
            .store(in: &cancellables)
        
        // Load user's review
        apiService.getUserReview(for: place.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to load user review: \(error)")
                    }
                },
                receiveValue: { response in
                    userReview = response?.review
                }
            )
            .store(in: &cancellables)
    }
    
    
    private func createReview(_ request: CreateReviewRequest) {
        apiService.createReview(request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to create review: \(error)")
                        toastManager.show(Toast(message: "Failed to create review", type: .error, duration: 3.0))
                    }
                },
                receiveValue: { response in
                    userReview = response.review
                    showingReviewForm = false
                    toastManager.show(Toast(message: "Review created successfully!", type: .success, duration: 3.0))
                    loadReviews() // Refresh reviews
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateReview(_ reviewId: String, _ request: UpdateReviewRequest) {
        apiService.updateReview(reviewId, request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to update review: \(error)")
                        toastManager.show(Toast(message: "Failed to update review", type: .error, duration: 3.0))
                    }
                },
                receiveValue: { response in
                    userReview = response.review
                    showingReviewForm = false
                    toastManager.show(Toast(message: "Review updated successfully!", type: .success, duration: 3.0))
                    loadReviews() // Refresh reviews
                }
            )
            .store(in: &cancellables)
    }
    
    private func markReviewHelpful(_ reviewId: String) {
        apiService.markReviewHelpful(reviewId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to mark review helpful: \(error)")
                    }
                },
                receiveValue: { _ in
                    // Refresh reviews to update helpful count
                    loadReviews()
                }
            )
            .store(in: &cancellables)
    }
    
    private func reportReview(_ reviewId: String) {
        apiService.reportReview(reviewId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("❌ Failed to report review: \(error)")
                        toastManager.show(Toast(message: "Failed to report review", type: .error, duration: 3.0))
                    }
                },
                receiveValue: { _ in
                    toastManager.show(Toast(message: "Review reported successfully", type: .success, duration: 3.0))
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        BusinessDetailsView(
            place: Place(
                fsqId: "test",
                name: "The Amazing Restaurant",
                categories: [
                    Category(id: 1, name: "Italian", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png")),
                    Category(id: 2, name: "Pizza", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png"))
                ],
                distance: 500,
                geocodes: Geocodes(main: Coordinate(latitude: 37.7749, longitude: -122.4194), roof: nil),
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
                hours: PlaceHours(
                    openNow: true,
                    regular: [
                        RegularHours(close: "22:00", day: 1, open: "11:00"),
                        RegularHours(close: "22:00", day: 2, open: "11:00"),
                        RegularHours(close: "22:00", day: 3, open: "11:00"),
                        RegularHours(close: "22:00", day: 4, open: "11:00"),
                        RegularHours(close: "23:00", day: 5, open: "11:00"),
                        RegularHours(close: "23:00", day: 6, open: "10:00"),
                        RegularHours(close: "21:00", day: 0, open: "10:00")
                    ]
                ),
                photos: nil,
                tel: "+1-555-123-4567",
                website: "https://example.com",
                socialMedia: nil
            )
        )
    }
}
