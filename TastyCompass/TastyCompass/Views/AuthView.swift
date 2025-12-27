import SwiftUI
import Combine

/// Authentication view with login and signup functionality
struct AuthView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    Text("Welcome to TastyCompass")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(isSignUp ? "Create your account" : "Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textContentType(.none)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                    }
                    
                    // Confirm password field (sign up only)
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            SecureField("Confirm your password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textContentType(.none)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // Action button
                Button(action: handleAuthAction) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        }
                        
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty) ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && confirmPassword.isEmpty))
                .padding(.horizontal, 24)
                
                // Toggle sign up/sign in
                Button(action: {
                    isSignUp.toggle()
                    errorMessage = ""
                    password = ""
                    confirmPassword = ""
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Demo account info
                VStack(spacing: 8) {
                    Text("Demo Account")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Email: demo@tastycompass.com\nPassword: demo123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showingAlert) {
                Button("OK") {
                    errorMessage = ""
                }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthAction() {
        guard !email.isEmpty && !password.isEmpty else {
            showError("Please fill in all fields")
            return
        }
        
        if isSignUp {
            guard !confirmPassword.isEmpty else {
                showError("Please confirm your password")
                return
            }
            
            guard password == confirmPassword else {
                showError("Passwords do not match")
                return
            }
            
            guard isValidEmail(email) else {
                showError("Please enter a valid email address")
                return
            }
        }
        
        isLoading = true
        errorMessage = ""
        
        if isSignUp {
            authManager.signUp(email: email, password: password)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoading = false
                        if case .failure(let error) = completion {
                            self.showError(error.localizedDescription)
                        }
                    },
                    receiveValue: { success in
                        if success {
                            print("✅ Sign up successful")
                        }
                    }
                )
                .store(in: &authManager.cancellables)
        } else {
            authManager.signIn(email: email, password: password)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        self.isLoading = false
                        if case .failure(let error) = completion {
                            self.showError(error.localizedDescription)
                        }
                    },
                    receiveValue: { success in
                        if success {
                            print("✅ Sign in successful")
                        }
                    }
                )
                .store(in: &authManager.cancellables)
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingAlert = true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Preview

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
