import Foundation
import AuthenticationServices
import Security
import Combine

// MARK: - Auth Service
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isAnonymous = false
    @Published var isLoading = true
    @Published var error: AuthError?
    
    private let apiService = APIService.shared
    private let keychainService = KeychainService()
    private let userIdentityManager = UserIdentityManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Error Types
    enum AuthError: LocalizedError {
        case signInFailed(String)
        case tokenExpired
        case noCredentials
        case keychainError
        case networkError
        case migrationFailed
        
        var errorDescription: String? {
            switch self {
            case .signInFailed(let message):
                return "Sign in failed: \(message)"
            case .tokenExpired:
                return "Your session has expired. Please sign in again."
            case .noCredentials:
                return "No credentials found"
            case .keychainError:
                return "Failed to access secure storage"
            case .networkError:
                return "Network connection error"
            case .migrationFailed:
                return "Failed to migrate user data"
            }
        }
    }
    
    override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// Check current authentication state
    func checkAuthenticationState() async {
        isLoading = true
        
        // Check for stored credentials
        if let session = loadStoredSession() {
            if !session.isExpired {
                // Valid session found
                self.user = User(
                    id: session.userId,
                    email: nil,
                    name: nil,
                    userType: session.isAnonymous ? .anonymous : .apple,
                    createdAt: Date(),
                    isAnonymous: session.isAnonymous
                )
                self.isAuthenticated = true
                self.isAnonymous = session.isAnonymous
            } else {
                // Session expired, try to refresh
                await refreshSession(session)
            }
        }
        
        isLoading = false
    }
    
    /// Sign in with Apple
    func signInWithApple() async throws {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        // Create a continuation to handle the async delegate callbacks
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.signInContinuation = continuation
            authorizationController.performRequests()
        }
    }
    
    /// Sign in anonymously
    func signInAnonymously() async throws {
        isLoading = true
        
        let temporaryId = generateTemporaryId()
        
        // Create anonymous user
        let anonymousUser = User(
            id: temporaryId,
            email: nil,
            name: "Guest User",
            userType: .anonymous,
            createdAt: Date(),
            isAnonymous: true
        )
        
        // Create session
        let session = UserSession(
            sessionId: UUID().uuidString,
            userId: temporaryId,
            authToken: nil,
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
            isAnonymous: true
        )
        
        // Save to keychain
        try saveSession(session)
        
        // Update state
        self.user = anonymousUser
        self.isAuthenticated = true
        self.isAnonymous = true
        
        isLoading = false
    }
    
    /// Upgrade anonymous user to full account
    func upgradeAnonymousUser() async throws {
        guard let currentUser = user, currentUser.isAnonymous else {
            throw AuthError.noCredentials
        }
        
        isLoading = true
        
        do {
            // Perform Apple Sign In
            try await signInWithApple()
            
            // If sign in successful, migrate data
            if let newUser = user, !newUser.isAnonymous {
                await migrateUserData(from: currentUser.id, to: newUser.id)
            }
        } catch {
            isLoading = false
            throw error
        }
    }
    
    /// Sign out
    func signOut() async {
        // Clear keychain
        keychainService.deleteSession()
        
        // Clear state
        user = nil
        isAuthenticated = false
        isAnonymous = false
        error = nil
    }
    
    // MARK: - Private Methods
    
    private var signInContinuation: CheckedContinuation<Void, Error>?
    
    private func generateTemporaryId() -> String {
        return "temporary_\(UUID().uuidString)"
    }
    
    private func loadStoredSession() -> UserSession? {
        return keychainService.loadSession()
    }
    
    private func saveSession(_ session: UserSession) throws {
        try keychainService.saveSession(session)
    }
    
    private func refreshSession(_ session: UserSession) async {
        // For anonymous users, just extend the session
        if session.isAnonymous {
            let newSession = UserSession(
                sessionId: session.sessionId,
                userId: session.userId,
                authToken: session.authToken,
                refreshToken: session.refreshToken,
                expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60),
                isAnonymous: true
            )
            
            try? saveSession(newSession)
            
            self.user = User(
                id: session.userId,
                email: nil,
                name: "Guest User",
                userType: .anonymous,
                createdAt: Date(),
                isAnonymous: true
            )
            self.isAuthenticated = true
            self.isAnonymous = true
        } else {
            // For authenticated users, would need to refresh with backend
            // For now, just sign out
            await signOut()
        }
    }
    
    private func migrateUserData(from oldId: String, to newId: String) async {
        do {
            // Call migration API
            // This would be implemented with your backend migration endpoint
            print("Migrating data from \(oldId) to \(newId)")
            
            // Clear old anonymous session
            keychainService.deleteSession()
            
        } catch {
            print("Migration failed: \(error)")
            self.error = .migrationFailed
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, 
                                didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            signInContinuation?.resume(throwing: AuthError.signInFailed("Invalid credential type"))
            return
        }
        
        // Process the Apple ID credential
        let userIdentifier = appleIDCredential.user
        let fullName = appleIDCredential.fullName
        let email = appleIDCredential.email
        
        // Create authenticated user
        let authenticatedUser = User(
            id: userIdentifier,
            email: email,
            name: fullName?.givenName,
            userType: .apple,
            createdAt: Date(),
            isAnonymous: false
        )
        
        // Create session
        let session = UserSession(
            sessionId: UUID().uuidString,
            userId: userIdentifier,
            authToken: appleIDCredential.identityToken.map { String(data: $0, encoding: .utf8) } ?? nil,
            refreshToken: appleIDCredential.authorizationCode.map { String(data: $0, encoding: .utf8) } ?? nil,
            expiresAt: Date().addingTimeInterval(90 * 24 * 60 * 60), // 90 days
            isAnonymous: false
        )
        
        // Save to keychain
        do {
            try saveSession(session)
            
            // Update state
            self.user = authenticatedUser
            self.isAuthenticated = true
            self.isAnonymous = false
            
            signInContinuation?.resume()
        } catch {
            signInContinuation?.resume(throwing: AuthError.keychainError)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, 
                                didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                signInContinuation?.resume(throwing: AuthError.signInFailed("User canceled"))
            case .unknown:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Unknown error"))
            case .invalidResponse:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Invalid response"))
            case .notHandled:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Not handled"))
            case .failed:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Authorization failed"))
            case .notInteractive:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Not interactive"))
            @unknown default:
                signInContinuation?.resume(throwing: AuthError.signInFailed("Unknown error"))
            }
        } else {
            signInContinuation?.resume(throwing: error)
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the key window
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - Keychain Service
class KeychainService {
    private let service = "com.abvios.bible-adventure"
    private let sessionKey = "user_session"
    
    func saveSession(_ session: UserSession) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthService.AuthError.keychainError
        }
    }
    
    func loadSession() -> UserSession? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(UserSession.self, from: data)
    }
    
    func deleteSession() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: sessionKey
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}