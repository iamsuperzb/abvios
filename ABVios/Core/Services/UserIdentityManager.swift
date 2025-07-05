import Foundation

// MARK: - User Identity Manager
class UserIdentityManager {
    static let shared = UserIdentityManager()
    
    private let anonymousUserKey = "anonymous_user_id"
    private let apiBaseURL = "https://www.askbibleverse.com"
    
    private init() {}
    
    // MARK: - Identity Management
    
    /// Generate new temporary ID
    private func generateTemporaryId() -> String {
        let tempId = "temporary_\(UUID().uuidString)"
        saveIdentityToStorage(tempId)
        return tempId
    }
    
    /// Save ID to storage
    private func saveIdentityToStorage(_ id: String) {
        UserDefaults.standard.set(id, forKey: anonymousUserKey)
    }
    
    /// Clear stored identity
    private func clearStoredIdentity() {
        UserDefaults.standard.removeObject(forKey: anonymousUserKey)
    }
    
    /// Get stored anonymous ID
    private func getStoredAnonymousId() -> String? {
        return UserDefaults.standard.string(forKey: anonymousUserKey)
    }
    
    /// Check if ID needs upgrade
    private func needsIdUpgrade(_ id: String) -> Bool {
        return id.hasPrefix("user_anon_") || id.hasPrefix("anonymous_")
    }
    
    /// Upgrade ID to new format
    private func upgradeId(oldId: String) async throws -> String {
        let newId = "temporary_\(UUID().uuidString)"
        
        // Migrate data
        let migrated = await migrateUserData(from: oldId, to: newId)
        if migrated {
            saveIdentityToStorage(newId)
            print("✅ User ID upgraded: \(oldId) -> \(newId)")
            return newId
        } else {
            // Migration failed, continue using old ID
            return oldId
        }
    }
    
    /// Get current user identity
    func getCurrentIdentity(authenticatedId: String? = nil) async -> UserIdentity {
        // If user is authenticated
        if let authId = authenticatedId {
            let storedId = getStoredAnonymousId()
            
            // Check if we need to sync data
            let syncRequired = storedId != nil &&
                               storedId != authId &&
                               (storedId!.hasPrefix("temporary_") ||
                                storedId!.hasPrefix("user_anon_") ||
                                storedId!.hasPrefix("anonymous_"))
            
            if syncRequired, let storedId = storedId {
                // Execute data sync
                let syncResults = await syncUserData(from: storedId, to: authId)
                if syncResults.allSuccessful {
                    clearStoredIdentity()
                    print("✅ Data sync successful, cleared temporary ID")
                }
            }
            
            return UserIdentity(
                currentUserId: authId,
                isTemporary: false,
                syncRequired: false,
                displayName: nil,
                email: nil
            )
        }
        
        // Unauthenticated user
        if var storedId = getStoredAnonymousId() {
            // Check if ID needs upgrade
            if needsIdUpgrade(storedId) {
                storedId = try! await upgradeId(oldId: storedId)
            }
            
            return UserIdentity(
                currentUserId: storedId,
                isTemporary: true,
                syncRequired: false,
                displayName: "Guest User",
                email: nil
            )
        }
        
        // Generate new temporary ID
        let temporaryId = generateTemporaryId()
        return UserIdentity(
            currentUserId: temporaryId,
            isTemporary: true,
            syncRequired: false,
            displayName: "Guest User",
            email: nil
        )
    }
    
    // MARK: - Data Migration
    
    /// Migrate user data from old ID to new ID
    private func migrateUserData(from oldId: String, to newId: String) async -> Bool {
        do {
            let url = URL(string: "\(apiBaseURL)/api/user-data/migrate")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["oldId": oldId, "newId": newId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("❌ Failed to migrate user data: \(error)")
            return false
        }
    }
    
    /// Sync user data
    func syncUserData(from oldId: String, to newId: String) async -> (quizProgress: Bool, cards: Bool, errors: Bool, allSuccessful: Bool) {
        var results = (quizProgress: false, cards: false, errors: false, allSuccessful: false)
        
        // Sync quiz progress
        results.quizProgress = await syncQuizProgress(from: oldId, to: newId)
        
        // Sync unlocked cards
        results.cards = await syncUnlockedCards(from: oldId, to: newId)
        
        // Sync error records
        results.errors = await syncErrorRecords(from: oldId, to: newId)
        
        results.allSuccessful = results.quizProgress && results.cards && results.errors
        
        return results
    }
    
    private func syncQuizProgress(from oldId: String, to newId: String) async -> Bool {
        do {
            let url = URL(string: "\(apiBaseURL)/api/quiz/sync-progress")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["fromUserId": oldId, "toUserId": newId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("❌ Failed to sync quiz progress: \(error)")
            return false
        }
    }
    
    private func syncUnlockedCards(from oldId: String, to newId: String) async -> Bool {
        do {
            let url = URL(string: "\(apiBaseURL)/api/quiz/sync-cards")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["fromUserId": oldId, "toUserId": newId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("❌ Failed to sync unlocked cards: \(error)")
            return false
        }
    }
    
    private func syncErrorRecords(from oldId: String, to newId: String) async -> Bool {
        do {
            let url = URL(string: "\(apiBaseURL)/api/quiz/sync-errors")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["fromUserId": oldId, "toUserId": newId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            print("❌ Failed to sync error records: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get effective user ID (for API calls)
    func getEffectiveUserId(authenticatedId: String?) async -> String {
        let identity = await getCurrentIdentity(authenticatedId: authenticatedId)
        return identity.currentUserId
    }
    
    /// Check if user needs upgrade prompt
    func needsUpgradePrompt(authenticatedId: String?) async -> Bool {
        let identity = await getCurrentIdentity(authenticatedId: authenticatedId)
        return identity.isTemporary
    }
}