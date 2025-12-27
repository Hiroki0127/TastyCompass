import SwiftUI
import Combine
import Foundation

/// Manager for handling user authentication
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?
    
    private let apiService = BackendAPIService.shared
    private let userDefaults = UserDefaults.standard
    
    // Key for storing auth token
    private let authTokenKey = "auth_token"
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for existing auth token on init
        loadStoredAuthToken()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return apiService.signUp(email: email, password: password)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.handleAuthSuccess(token: response.token, user: response.user)
            })
            .map { _ in true }
            .eraseToAnyPublisher()
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<Bool, Error> {
        return apiService.signIn(email: email, password: password)
            .handleEvents(receiveOutput: { [weak self] response in
                self?.handleAuthSuccess(token: response.token, user: response.user)
            })
            .map { _ in true }
            .eraseToAnyPublisher()
    }
    
    func signOut() {
        // Clear stored token
        userDefaults.removeObject(forKey: authTokenKey)
        
        // Reset state
        authToken = nil
        currentUser = nil
        isAuthenticated = false
        
        // Clear token from BackendAPIService
        BackendAPIService.shared.authToken = nil
        
        print("✅ User signed out")
    }
    
    func updateCurrentUser(_ user: User) {
        currentUser = user
        print("✅ Current user updated")
    }
    
    // MARK: - Token Management
    
    private func handleAuthSuccess(token: String, user: User) {
        // Store token
        userDefaults.set(token, forKey: authTokenKey)
        
        // Update state
        authToken = token
        currentUser = user
        isAuthenticated = true
        
        // Update BackendAPIService with the token
        BackendAPIService.shared.authToken = token
        
        print("✅ Authentication successful for user: \(user.email)")
    }
    
    private func loadStoredAuthToken() {
        if let token = userDefaults.string(forKey: authTokenKey) {
            authToken = token
            // Update BackendAPIService with the stored token
            BackendAPIService.shared.authToken = token
            // TODO: Validate token with server
            isAuthenticated = true
            print("✅ Loaded stored auth token")
        }
    }
    
    // MARK: - Helper Methods
    
    func getAuthHeader() -> [String: String] {
        guard let token = authToken else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
    
    var hasValidToken: Bool {
        return authToken != nil && !authToken!.isEmpty
    }
}

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let avatarUrl: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case avatarUrl
        case createdAt
        case updatedAt
    }
}

// MARK: - Auth Response Models

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
}