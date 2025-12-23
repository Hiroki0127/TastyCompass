import Foundation
import UIKit

/// Manages application configuration and API credentials
class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private let configFileName = "Config"
    private var configData: [String: Any] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    /// Loads configuration from Config.plist file
    private func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: configFileName, ofType: "plist"),
              let plistData = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            print("⚠️ Warning: Could not load Config.plist file")
            return
        }
        
        configData = plistData
        print("✅ Configuration loaded successfully")
    }
    
    /// Retrieves a string value from configuration
    private func getStringValue(for key: String) -> String? {
        return configData[key] as? String
    }
    
    // MARK: - Google Places API Configuration
    
    /// Google Places API Key
    var googlePlacesAPIKey: String {
        guard let key = getStringValue(for: "GooglePlacesAPIKey"),
              key != "YOUR_GOOGLE_PLACES_API_KEY_HERE" else {
            fatalError("❌ Google Places API Key not configured. Please update Config.plist with your actual API key.")
        }
        return key
    }
    
    /// Google Places API Base URL
    var googlePlacesBaseURL: String {
        return getStringValue(for: "GooglePlacesBaseURL") ?? "https://maps.googleapis.com/maps/api/place"
    }
    
    /// Google Places Search Endpoint
    var googlePlacesSearchEndpoint: String {
        return getStringValue(for: "GooglePlacesSearchEndpoint") ?? "/nearbysearch/json"
    }
    
    /// Google Places Details Endpoint
    var googlePlacesDetailsEndpoint: String {
        return getStringValue(for: "GooglePlacesDetailsEndpoint") ?? "/details/json"
    }
    
    /// Google Places Photo Endpoint
    var googlePlacesPhotoEndpoint: String {
        return getStringValue(for: "GooglePlacesPhotoEndpoint") ?? "/photo"
    }
    
    // MARK: - Backend API Configuration
    
    /// Backend API Base URL
    var backendAPIURL: String {
        return getStringValue(for: "BackendAPIURL") ?? "http://localhost:3000/api"
    }
    
    // MARK: - Helper Methods
    
    /// Constructs full URL for Google Places API endpoints
    func googlePlacesURL(for endpoint: String) -> String {
        return "\(googlePlacesBaseURL)\(endpoint)"
    }
    
    /// Validates that all required configuration is present
    func validateConfiguration() -> Bool {
        let requiredKeys = ["GooglePlacesAPIKey"]
        
        for key in requiredKeys {
            guard let value = getStringValue(for: key),
                  !value.isEmpty,
                  !value.contains("YOUR_") else {
                print("❌ Missing or invalid configuration for key: \(key)")
                return false
            }
        }
        
        print("✅ All configuration validated successfully")
        return true
    }
}
