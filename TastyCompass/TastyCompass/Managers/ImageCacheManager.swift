import Foundation
import UIKit
import Combine
import SwiftUI

/// Manages image caching with both memory and disk storage
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    // Memory cache using NSCache
    private let memoryCache = NSCache<NSString, UIImage>()
    
    // Disk cache directory
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    // Cache configuration
    private let maxMemoryCacheSize = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize = 200 * 1024 * 1024 // 200MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Set up memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100 // Maximum 100 images in memory
        
        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        // Create cache directory if it doesn't exist
        createCacheDirectoryIfNeeded()
        
        // Clean up old cache files on initialization
        cleanupOldCacheFiles()
        
        print("✅ ImageCacheManager initialized")
    }
    
    // MARK: - Public Methods
    
    /// Loads an image from cache or downloads it
    /// - Parameters:
    ///   - url: Image URL
    ///   - size: Desired image size (optional)
    /// - Returns: Publisher with UIImage
    func loadImage(from url: String, size: ImageSize = .original) -> AnyPublisher<UIImage?, Never> {
        let cacheKey = generateCacheKey(url: url, size: size)
        
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            return Just(cachedImage)
                .eraseToAnyPublisher()
        }
        
        // Check disk cache
        if let diskImage = loadImageFromDisk(key: cacheKey) {
            // Store in memory cache for faster access
            memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
            return Just(diskImage)
                .eraseToAnyPublisher()
        }
        
        // Download image from network
        return downloadImage(from: url, size: size, cacheKey: cacheKey)
    }
    
    /// Preloads images for better performance
    /// - Parameter urls: Array of image URLs to preload
    func preloadImages(urls: [String]) {
        for url in urls {
            loadImage(from: url, size: .thumbnail)
                .sink { _ in }
                .store(in: &cancellables)
        }
    }
    
    /// Clears all cached images
    func clearCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in cacheFiles {
                try fileManager.removeItem(at: file)
            }
            print("✅ Cleared all image cache")
        } catch {
            print("❌ Failed to clear cache: \(error.localizedDescription)")
        }
    }
    
    /// Gets cache size information
    var cacheInfo: CacheInfo {
        let memoryCount = memoryCache.countLimit
        let diskSize = getDiskCacheSize()
        let diskCount = getDiskCacheCount()
        
        return CacheInfo(
            memoryImageCount: memoryCount,
            diskImageCount: diskCount,
            diskCacheSize: diskSize,
            formattedDiskSize: formatBytes(diskSize)
        )
    }
    
    // MARK: - Private Methods
    
    /// Downloads image from network and caches it
    private func downloadImage(from url: String, size: ImageSize, cacheKey: String) -> AnyPublisher<UIImage?, Never> {
        guard let imageURL = URL(string: url) else {
            return Just(nil)
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: imageURL)
            .map(\.data)
            .compactMap { UIImage(data: $0) }
            .handleEvents(receiveOutput: { [weak self] image in
                // Cache the downloaded image
                if let image = image {
                    self?.cacheImage(image, key: cacheKey)
                }
            })
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Caches an image in both memory and disk
    private func cacheImage(_ image: UIImage, key: String) {
        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Store in disk cache
        saveImageToDisk(image, key: key)
    }
    
    /// Saves image to disk cache
    private func saveImageToDisk(_ image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("❌ Failed to save image to disk: \(error.localizedDescription)")
        }
    }
    
    /// Loads image from disk cache
    private func loadImageFromDisk(key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        // Check if file is too old
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modificationDate = attributes[.modificationDate] as? Date,
               Date().timeIntervalSince(modificationDate) > maxCacheAge {
                try fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("❌ Failed to check file age: \(error.localizedDescription)")
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Generates cache key for URL and size
    private func generateCacheKey(url: String, size: ImageSize) -> String {
        let urlHash = url.hash
        return "\(urlHash)_\(size.rawValue)"
    }
    
    /// Creates cache directory if needed
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("❌ Failed to create cache directory: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cleans up old cache files
    private func cleanupOldCacheFiles() {
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in cacheFiles {
                let attributes = try fileManager.attributesOfItem(atPath: file.path)
                if let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date,
                   Date().timeIntervalSince(modificationDate) > maxCacheAge {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("❌ Failed to cleanup old cache files: \(error.localizedDescription)")
        }
    }
    
    /// Gets disk cache size in bytes
    private func getDiskCacheSize() -> Int64 {
        do {
            let cacheFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            return cacheFiles.reduce(0) { total, file in
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: file.path)
                    return total + (attributes[FileAttributeKey.size] as? Int64 ?? 0)
                } catch {
                    return total
                }
            }
        } catch {
            return 0
        }
    }
    
    /// Gets number of files in disk cache
    private func getDiskCacheCount() -> Int {
        do {
            return try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil).count
        } catch {
            return 0
        }
    }
    
    /// Formats bytes into human readable string
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Image Size Options

enum ImageSize: String, CaseIterable {
    case thumbnail = "thumb"
    case medium = "medium"
    case large = "large"
    case original = "original"
    
    var displayName: String {
        switch self {
        case .thumbnail: return "Thumbnail"
        case .medium: return "Medium"
        case .large: return "Large"
        case .original: return "Original"
        }
    }
}

// MARK: - Cache Info Model

struct CacheInfo {
    let memoryImageCount: Int
    let diskImageCount: Int
    let diskCacheSize: Int64
    let formattedDiskSize: String
}

// MARK: - Placeholder Image

extension ImageCacheManager {
    
    /// Gets a placeholder image for restaurants
    static var placeholderImage: UIImage? {
        // Create a simple placeholder image
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Background color
            UIColor.systemGray5.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Icon
            let iconSize: CGFloat = 40
            let iconRect = CGRect(
                x: (size.width - iconSize) / 2,
                y: (size.height - iconSize) / 2,
                width: iconSize,
                height: iconSize
            )
            
            UIColor.systemGray3.setFill()
            context.fill(iconRect)
            
            // Text
            let text = "No Image"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.systemGray2
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: iconRect.maxY + 8,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}
