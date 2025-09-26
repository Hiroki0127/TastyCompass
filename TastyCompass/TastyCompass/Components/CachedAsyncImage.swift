import SwiftUI
import Combine
import Foundation

/// A SwiftUI view that loads and caches images asynchronously
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: String
    private let size: ImageSize
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder
    
    @StateObject private var imageLoader = ImageLoader()
    @State private var image: UIImage?
    
    init(
        url: String,
        size: ImageSize = .original,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.size = size
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        imageLoader.loadImage(from: url, size: size) { loadedImage in
            self.image = loadedImage
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    
    /// Simple initializer with default placeholder
    init(url: String, size: ImageSize = .original) {
        self.init(
            url: url,
            size: size,
            content: { $0 },
            placeholder: { ProgressView() }
        )
    }
}

extension CachedAsyncImage where Placeholder == ProgressView<EmptyView, EmptyView> {
    
    /// Initializer with custom content and default placeholder
    init(
        url: String,
        size: ImageSize = .original,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            size: size,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

// MARK: - Image Loader

@MainActor
class ImageLoader: ObservableObject {
    private let cacheManager = ImageCacheManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadImage(from url: String, size: ImageSize, completion: @escaping (UIImage?) -> Void) {
        cacheManager.loadImage(from: url, size: size)
            .sink { image in
                completion(image)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Restaurant Image View

/// Specialized view for restaurant images with fallback
struct RestaurantImageView: View {
    let place: Place
    let size: ImageSize
    let cornerRadius: CGFloat
    
    init(
        place: Place,
        size: ImageSize = .medium,
        cornerRadius: CGFloat = 8
    ) {
        self.place = place
        self.size = size
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        CachedAsyncImage(
            url: imageURL,
            size: size
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .cornerRadius(cornerRadius)
        } placeholder: {
            RestaurantPlaceholderView(cornerRadius: cornerRadius)
        }
    }
    
    private var imageURL: String {
        // Try to get the first photo from the place
        if let firstPhoto = place.photos?.first {
            return firstPhoto.photoURL
        }
        
        // Fallback to a default restaurant image URL
        // You can replace this with a default image service
        return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop"
    }
}

// MARK: - Restaurant Placeholder View

struct RestaurantPlaceholderView: View {
    let cornerRadius: CGFloat
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.1))
            
            // Icon
            VStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
                
                Text("No Image")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .aspectRatio(4/3, contentMode: .fit)
    }
}

// MARK: - Category Icon View

/// View for displaying category icons
struct CategoryIconView: View {
    let category: Category
    let size: CGFloat
    
    init(category: Category, size: CGFloat = 24) {
        self.category = category
        self.size = size
    }
    
    var body: some View {
        CachedAsyncImage(
            url: category.iconURL,
            size: .thumbnail
        ) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } placeholder: {
            Image(systemName: "fork.knife")
                .font(.system(size: size * 0.6))
                .foregroundColor(.gray)
                .frame(width: size, height: size)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(size * 0.2)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Restaurant image example
        RestaurantImageView(
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
                price: nil,
                rating: nil,
                stats: nil,
                verified: nil,
                hours: nil,
                photos: nil,
                tel: nil,
                website: nil,
                socialMedia: nil
            ),
            size: .medium
        )
        .frame(height: 200)
        
        // Category icon example
        HStack {
            CategoryIconView(category: Category(id: 1, name: "Restaurant", icon: CategoryIcon(prefix: "https://ss3.4sqi.net/img/categories_v2/food/", suffix: ".png")), size: 32)
            
            Text("Restaurant")
                .font(.caption)
        }
    }
    .padding()
}
