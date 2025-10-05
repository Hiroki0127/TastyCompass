import SwiftUI
import Foundation
import Combine

// MARK: - Review Row Component

struct ReviewRowView: View {
    let review: Review
    let onHelpfulTap: (() -> Void)?
    let onReportTap: (() -> Void)?
    
    @State private var isHelpfulPressed = false
    
    init(
        review: Review,
        onHelpfulTap: (() -> Void)? = nil,
        onReportTap: (() -> Void)? = nil
    ) {
        self.review = review
        self.onHelpfulTap = onHelpfulTap
        self.onReportTap = onReportTap
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info and rating
            HStack {
                // User avatar placeholder
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(review.displayName.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        StarRatingView(
                            rating: review.starRating,
                            starSize: 12,
                            showRating: true
                        )
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(review.relativeDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Report button
                if onReportTap != nil {
                    Button(action: {
                        onReportTap?()
                    }) {
                        Image(systemName: "flag")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Review title
            if review.hasTitle {
                Text(review.title!)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            // Review content
            Text(review.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Helpful button
            HStack {
                Button(action: {
                    if !isHelpfulPressed {
                        isHelpfulPressed = true
                        onHelpfulTap?()
                        
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpfulPressed ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.caption)
                            .foregroundColor(isHelpfulPressed ? .blue : .secondary)
                        
                        Text("Helpful (\(review.helpfulCount))")
                            .font(.caption)
                            .foregroundColor(isHelpfulPressed ? .blue : .secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isHelpfulPressed)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Review Form Component

struct ReviewFormView: View {
    let restaurantId: String
    let restaurantName: String
    let existingReview: Review?
    
    @State private var rating: Int = 5
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isSubmitting = false
    
    let onSubmit: (CreateReviewRequest) -> Void
    let onUpdate: (String, UpdateReviewRequest) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastManager: ToastManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(restaurantName)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Rating section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rating")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    rating = star
                                    
                                    // Add haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Spacer()
                            
                            Text("\(rating) out of 5")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (Optional)")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextField("Summarize your experience", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Content section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Review")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .font(.body)
                        
                        Text("\(content.count) characters (minimum 10)")
                            .font(.caption)
                            .foregroundColor(content.count < 10 ? .red : .secondary)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(existingReview != nil ? "Update" : "Submit") {
                        submitReview()
                    }
                    .disabled(!isValidReview || isSubmitting)
                    .opacity(isValidReview ? 1.0 : 0.6)
                }
            }
        }
        .onAppear {
            if let existingReview = existingReview {
                rating = existingReview.rating
                title = existingReview.title ?? ""
                content = existingReview.content
            }
        }
    }
    
    private var isValidReview: Bool {
        return content.count >= 10 && rating >= 1 && rating <= 5
    }
    
    private func submitReview() {
        guard isValidReview else { return }
        
        isSubmitting = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        if let existingReview = existingReview {
            // Update existing review
            let updateRequest = UpdateReviewRequest(
                rating: rating,
                title: title.isEmpty ? nil : title,
                content: content
            )
            onUpdate(existingReview.id, updateRequest)
        } else {
            // Create new review
            let createRequest = CreateReviewRequest(
                restaurantId: restaurantId,
                rating: rating,
                title: title.isEmpty ? nil : title,
                content: content
            )
            onSubmit(createRequest)
        }
        
        // Reset submitting state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isSubmitting = false
        }
    }
}

// MARK: - Reviews List Component

struct ReviewsListView: View {
    let reviews: [Review]
    let isLoading: Bool
    let onLoadMore: (() -> Void)?
    let onHelpfulTap: ((String) -> Void)?
    let onReportTap: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading && reviews.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Loading reviews...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if reviews.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No reviews yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to share your experience!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(reviews) { review in
                        ReviewRowView(
                            review: review,
                            onHelpfulTap: {
                                onHelpfulTap?(review.id)
                            },
                            onReportTap: {
                                onReportTap?(review.id)
                            }
                        )
                    }
                    
                    // Load more button
                    if onLoadMore != nil {
                        Button(action: {
                            onLoadMore?()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Load More Reviews")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                            }
                            .foregroundColor(.blue)
                            .padding()
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Review Stats Component

struct ReviewStatsView: View {
    let averageRating: Double
    let totalRatings: Int
    let ratingDistribution: [String: Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Overall rating
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", averageRating))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    StarRatingView(
                        rating: averageRating,
                        starSize: 16,
                        showRating: false
                    )
                    
                    Text("\(totalRatings) reviews")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(5...1, id: \.self) { rating in
                        HStack(spacing: 8) {
                            Text("\(rating)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                            
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            ProgressView(value: progressForRating(rating))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                                .frame(width: 80)
                            
                            Text("\(ratingDistribution[String(rating)] ?? 0)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func progressForRating(_ rating: Int) -> Double {
        guard totalRatings > 0 else { return 0 }
        let count = ratingDistribution[String(rating)] ?? 0
        return Double(count) / Double(totalRatings)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Review row
        ReviewRowView(
            review: Review(
                id: "1",
                userId: "user1",
                restaurantId: "rest1",
                rating: 5,
                title: "Amazing food!",
                content: "The pasta was incredible and the service was excellent. Highly recommend!",
                createdAt: Date(),
                updatedAt: Date(),
                helpfulCount: 3,
                isReported: false,
                userName: "John Doe"
            )
        )
        
        // Review stats
        ReviewStatsView(
            averageRating: 4.2,
            totalRatings: 15,
            ratingDistribution: [
                "5": 8,
                "4": 4,
                "3": 2,
                "2": 1,
                "1": 0
            ]
        )
    }
    .padding()
}

// MARK: - Google Review Components

struct GoogleReviewRowView: View {
    let review: GoogleReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Author name
                Text(review.author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Review text
            Text(review.text)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(nil)
            
            // Time
            Text(timeAgoString(from: review.time))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct GoogleReviewsListView: View {
    let restaurantId: String
    let restaurantName: String
    
    @State private var reviews: [GoogleReview] = []
    @State private var isLoading = true
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var totalReviews = 0
    @State private var isLoadingMore = false
    
    @EnvironmentObject private var apiService: BackendAPIService
    
    var body: some View {
        VStack {
            if isLoading && reviews.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text("Loading Google reviews...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Google reviews available")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Reviews may not be available for this restaurant.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    // Header with total count
                    HStack {
                        Text("\(totalReviews) Google Reviews")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("Page \(currentPage) of \(totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    ForEach(reviews) { review in
                        GoogleReviewRowView(review: review)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    
                    // Load more button
                    if currentPage < totalPages {
                        Button(action: loadMoreReviews) {
                            HStack {
                                if isLoadingMore {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text(isLoadingMore ? "Loading..." : "Load More Reviews")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Google Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadReviews()
        }
    }
    
    private func loadReviews() {
        isLoading = true
        
        apiService.getGoogleReviews(for: restaurantId, page: 1, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load Google reviews: \(error)")
                    }
                },
                receiveValue: { response in
                    reviews = response.reviews
                    currentPage = response.pagination.currentPage
                    totalPages = response.pagination.totalPages
                    totalReviews = response.totalReviews
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadMoreReviews() {
        guard currentPage < totalPages && !isLoadingMore else { return }
        
        isLoadingMore = true
        let nextPage = currentPage + 1
        
        apiService.getGoogleReviews(for: restaurantId, page: nextPage, limit: 10)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingMore = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load more Google reviews: \(error)")
                    }
                },
                receiveValue: { response in
                    reviews.append(contentsOf: response.reviews)
                    currentPage = response.pagination.currentPage
                    totalPages = response.pagination.totalPages
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

#Preview("Google Review Row View") {
    GoogleReviewRowView(
        review: GoogleReview(
            id: "google_review_1",
            author: "Sarah Johnson",
            rating: 5,
            text: "Amazing food and great service! The pasta was incredible and the atmosphere was perfect for a date night.",
            time: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
    )
    .padding()
}

#Preview("Google Reviews List View") {
    NavigationView {
        GoogleReviewsListView(
            restaurantId: "sample_restaurant_id",
            restaurantName: "Sample Restaurant"
        )
    }
    .environmentObject(BackendAPIService())
}
