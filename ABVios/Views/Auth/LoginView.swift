import SwiftUI
import AuthenticationServices

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    let isUpgrading: Bool
    
    init(isUpgrading: Bool = false) {
        self.isUpgrading = isUpgrading
    }
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.06, green: 0.72, blue: 0.5).opacity(0.1),
                    Color(red: 0.05, green: 0.58, blue: 0.53).opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                if isUpgrading {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: Constants.Icons.close)
                                .font(.title2)
                                .foregroundColor(Constants.Colors.secondaryText)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.black.opacity(0.05)))
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Logo and title
                VStack(spacing: 24) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Constants.Colors.primary)
                        .shadow(color: Constants.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 8) {
                        Text(isUpgrading ? "Upgrade Your Account" : "Welcome to Bible Adventure")
                            .font(Constants.Fonts.title)
                            .foregroundColor(Constants.Colors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text(isUpgrading ? "Sign in to unlock all chapters and sync your progress" : "Start your learning journey")
                            .font(Constants.Fonts.body)
                            .foregroundColor(Constants.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Sign in options
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleSignInResult(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(25)
                    
                    // Continue as Guest
                    if !isUpgrading && !authService.isAnonymous {
                        Button(action: {
                            Task {
                                do {
                                    try await authService.signInAnonymously()
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .font(.title3)
                                
                                Text("Continue as Guest")
                                    .font(Constants.Fonts.headline)
                            }
                            .foregroundColor(Constants.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Constants.Colors.primary, lineWidth: 2)
                            )
                        }
                        .hapticFeedback()
                        
                        Text("Limited to first 3 chapters")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.tertiaryText)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Terms and privacy
                VStack(spacing: 4) {
                    Text("By continuing, you agree to our")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.tertiaryText)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Show terms
                        }
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primary)
                        
                        Text("and")
                            .font(Constants.Fonts.caption)
                            .foregroundColor(Constants.Colors.tertiaryText)
                        
                        Button("Privacy Policy") {
                            // Show privacy
                        }
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.primary)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success:
            // Auth service will handle the authorization
            if isUpgrading {
                Task {
                    do {
                        try await authService.upgradeAnonymousUser()
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            } else {
                dismiss()
            }
            
        case .failure(let error):
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                // User canceled, don't show error
                return
            }
            
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView(isUpgrading: false)
                .environmentObject(AuthService())
            
            LoginView(isUpgrading: true)
                .environmentObject(AuthService())
        }
    }
}