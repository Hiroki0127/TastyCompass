import Foundation

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
    
    // MARK: - Foursquare API Configuration
    
    /// Foursquare API Key (Client ID)
    var foursquareAPIKey: String {
        guard let key = getStringValue(for: "FoursquareAPIKey"),
              key != "YOUR_FOURSQUARE_API_KEY_HERE" else {
            fatalError("❌ Foursquare API Key not configured. Please update Config.plist with your actual API key.")
        }
        return key
    }
    
    /// Foursquare API Secret (Client Secret)
    var foursquareAPISecret: String {
        guard let secret = getStringValue(for: "FoursquareAPISecret"),
              secret != "YOUR_FOURSQUARE_API_SECRET_HERE" else {
            fatalError("❌ Foursquare API Secret not configured. Please update Config.plist with your actual API secret.")
        }
        return secret
    }
    
    /// Foursquare API Base URL
    var foursquareBaseURL: String {
        return getStringValue(for: "FoursquareBaseURL") ?? "https://api.foursquare.com/v3"
    }
    
    /// Foursquare Places Search Endpoint
    var foursquareSearchEndpoint: String {
        return getStringValue(for: "FoursquareSearchEndpoint") ?? "/places/search"
    }
    
    /// Foursquare Place Details Endpoint
    var foursquarePlaceEndpoint: String {
        return getStringValue(for: "FoursquarePlaceEndpoint") ?? "/places"
    }
    
    /// Foursquare Photos Endpoint
    var foursquarePhotoEndpoint: String {
        return getStringValue(for: "FoursquarePhotoEndpoint") ?? "/places"
    }
    
    // MARK: - Helper Methods
    
    /// Constructs full URL for Foursquare API endpoints
    func foursquareURL(for endpoint: String) -> String {
        return "\(foursquareBaseURL)\(endpoint)"
    }
    
    /// Validates that all required configuration is present
    func validateConfiguration() -> Bool {
        let requiredKeys = ["FoursquareAPIKey", "FoursquareAPISecret"]
        
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
