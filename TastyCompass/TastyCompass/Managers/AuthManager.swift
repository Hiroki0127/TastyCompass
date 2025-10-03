import Foundation
import Combine

/// Manages user authentication state and JWT token
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    
    private init() {
        loadAuthState()
    }
    
    // MARK: - Authentication Methods
    
    func login(token: String, user: User) {
        // Store token in UserDefaults
        UserDefaults.standard.set(token, forKey: tokenKey)
        
        // Store user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
        
        // Update state
        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.currentUser = user
        }
        
        print("✅ User logged in: \(user.email)")
    }
    
    func logout() {
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        
        // Update state
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
        }
        
        print("✅ User logged out")
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // MARK: - Private Methods
    
    private func loadAuthState() {
        guard let token = UserDefaults.standard.string(forKey: tokenKey),
              let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            isAuthenticated = false
            currentUser = nil
            return
        }
        
        isAuthenticated = true
        currentUser = user
        print("✅ Auth state loaded: \(user.email)")
    }
}

// MARK: - User Model

struct User: Codable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: String
    let updatedAt: String
}
