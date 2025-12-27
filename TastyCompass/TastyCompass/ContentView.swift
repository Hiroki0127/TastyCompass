import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                AuthView()
                    .environmentObject(authManager)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .accentColor(.orange)
    }
}

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var apiService = BackendAPIService.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingSignOutAlert = false
    @State private var favoritesCount: Int = 0
    @State private var reviewsCount: Int = 0
    @State private var isLoadingStats = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploadingImage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile header with gradient background
                    profileHeaderView
                        .padding(.bottom, 24)
                    
                    // Stats section
                    statsSectionView
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    
                    // Account information section
                    accountInfoSection
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    
                    // Sign out button
                    signOutButton
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .onAppear {
                loadUserStats()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { newImage in
                if let image = newImage {
                    uploadProfileImage(image)
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderView: some View {
        VStack(spacing: 16) {
            // Profile image
            Button(action: {
                showingImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.8), .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    if let user = authManager.currentUser, let avatarUrl = user.avatarUrl, let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                    } else if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    
                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .offset(x: -5, y: -5)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
            .disabled(isUploadingImage)
            
            // User name
            if let user = authManager.currentUser {
                VStack(spacing: 4) {
                    let displayName = getUserDisplayName(user)
                    Text(displayName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Member since \(formatDate(user.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.1), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                // Favorites stat
                StatCard(
                    icon: "heart.fill",
                    value: "\(favoritesCount)",
                    label: "Favorites",
                    color: .red
                )
                
                // Reviews stat
                StatCard(
                    icon: "star.fill",
                    value: "\(reviewsCount)",
                    label: "Reviews",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Account Info Section
    
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Information")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            if let user = authManager.currentUser {
                VStack(spacing: 12) {
                    InfoRow(icon: "envelope.fill", label: "Email", value: user.email)
                    
                    if !user.firstName.isEmpty || !user.lastName.isEmpty {
                        InfoRow(
                            icon: "person.fill",
                            label: "Name",
                            value: "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
                        )
                    }
                    
                    InfoRow(
                        icon: "calendar",
                        label: "Member Since",
                        value: formatDate(user.createdAt)
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button(action: {
            showingSignOutAlert = true
        }) {
            HStack {
                Image(systemName: "arrow.right.square")
                Text("Sign Out")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserDisplayName(_ user: User) -> String {
        let fullName = "\(user.firstName) \(user.lastName)".trimmingCharacters(in: .whitespaces)
        return fullName.isEmpty ? user.email : fullName
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: date)
        }
        return "Unknown"
    }
    
    private func loadUserStats() {
        isLoadingStats = true
        
        // Get favorites count from backend API (same source as FavoritesView)
        apiService.getAllFavorites()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingStats = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to load favorites count: \(error)")
                        // Fallback to local manager if backend fails
                        favoritesCount = favoritesManager.favoritePlaces.count
                    }
                },
                receiveValue: { favorites in
                    favoritesCount = favorites.count
                    print("✅ Loaded \(favorites.count) favorites for profile stats")
                    isLoadingStats = false
                }
            )
            .store(in: &cancellables)
        
        // Try to get reviews count from backend
        // For now, we'll fetch a sample to get total count
        // In a real app, you'd have a dedicated endpoint for user's review count
        if let userId = authManager.currentUser?.id {
            // Try to get user's reviews - we'll use a dummy restaurant ID
            // In production, you'd have a /reviews/user endpoint
            reviewsCount = 0 // Will be updated if we can fetch it
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        // For now, we'll convert the image to base64 and send it as a URL
        // In production, you'd upload to a cloud storage service (S3, Cloudinary, etc.)
        // and get back a URL
        
        isUploadingImage = true
        
        // Convert image to base64 data URL (temporary solution)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            isUploadingImage = false
            return
        }
        
        let base64String = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64String)"
        
        // Update profile with the data URL
        apiService.updateProfile(avatarUrl: dataURL)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isUploadingImage = false
                    if case .failure(let error) = completion {
                        print("❌ Failed to upload profile image: \(error)")
                    }
                },
                receiveValue: { updatedUser in
                    // Update the current user in auth manager
                    authManager.updateCurrentUser(updatedUser)
                    print("✅ Profile image updated successfully")
                    isUploadingImage = false
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Row Component

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ContentView()
}
