import SwiftUI
import Combine

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var apiService = BackendAPIService.shared
    
    @State private var email = "test@example.com"
    @State private var password = "password123"
    @State private var firstName = "Test"
    @State private var lastName = "User"
    @State private var isRegistering = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("TastyCompass")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 50)
                
                Text("Sign in to save your favorite restaurants")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    if isRegistering {
                        TextField("First Name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Last Name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal, 20)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal, 20)
                }
                
                Button {
                    if isRegistering {
                        register()
                    } else {
                        login()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        Text(isRegistering ? "Sign Up" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 20)
                
                Button {
                    isRegistering.toggle()
                    errorMessage = ""
                } label: {
                    Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            if authManager.isAuthenticated {
                // Auto-dismiss if already logged in
                // This would typically navigate to the main app
            }
        }
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        apiService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Login failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { user, token in
                    authManager.login(token: token, user: user)
                    // Dismiss the view or navigate to main app
                }
            )
            .store(in: &cancellables)
    }
    
    private func register() {
        guard !firstName.isEmpty && !lastName.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        apiService.register(email: email, password: password, firstName: firstName, lastName: lastName)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case .failure(let error) = completion {
                        errorMessage = "Registration failed: \(error.localizedDescription)"
                    }
                },
                receiveValue: { user, token in
                    authManager.login(token: token, user: user)
                    // Dismiss the view or navigate to main app
                }
            )
            .store(in: &cancellables)
    }
    
    @State private var cancellables = Set<AnyCancellable>()
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
