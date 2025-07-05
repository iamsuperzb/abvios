import Foundation
import UIKit

// MARK: - Cache Service
class CacheService {
    static let shared = CacheService()
    
    private let cacheKey = "bible_adventure_cache"
    private let cacheExpiryKey = "bible_adventure_cache_expiry"
    private let cacheDuration: TimeInterval = 5 * 60 // 5 minutes
    
    // Image cache
    private let imageCache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configure image cache
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Adventure Data Cache
    
    struct CachedAdventureData: Codable {
        let userId: String
        let chapters: [ChapterData]
        let userProgress: [String: UserProgress]
        let totalCrosses: Int
        let totalCorrectCount: Int
        let timestamp: Date
    }
    
    /// Save adventure data to cache
    func saveAdventureData(userId: String, 
                          chapters: [ChapterData], 
                          progress: [String: UserProgress],
                          crosses: Int,
                          correctCount: Int) async throws {
        let cachedData = CachedAdventureData(
            userId: userId,
            chapters: chapters,
            userProgress: progress,
            totalCrosses: crosses,
            totalCorrectCount: correctCount,
            timestamp: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(cachedData)
        
        UserDefaults.standard.set(data, forKey: "\(cacheKey)_\(userId)")
        UserDefaults.standard.set(Date().addingTimeInterval(cacheDuration), forKey: "\(cacheExpiryKey)_\(userId)")
        
        print("📦 [Cache] Adventure data saved for user: \(userId)")
    }
    
    /// Get cached adventure data
    func getAdventureData(userId: String) async -> CachedAdventureData? {
        guard let data = UserDefaults.standard.data(forKey: "\(cacheKey)_\(userId)"),
              let expiryDate = UserDefaults.standard.object(forKey: "\(cacheExpiryKey)_\(userId)") as? Date else {
            return nil
        }
        
        // Check if cache is expired
        if Date() > expiryDate {
            print("📦 [Cache] Cache expired for user: \(userId)")
            await clearAdventureData(userId: userId)
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedData = try decoder.decode(CachedAdventureData.self, from: data)
            
            // Verify user ID matches
            if cachedData.userId != userId {
                print("📦 [Cache] User ID mismatch, clearing cache")
                await clearAdventureData(userId: userId)
                return nil
            }
            
            print("📦 [Cache] Loading cached data for user: \(userId)")
            return cachedData
        } catch {
            print("📦 [Cache] Failed to decode cached data: \(error)")
            await clearAdventureData(userId: userId)
            return nil
        }
    }
    
    /// Clear cached adventure data
    func clearAdventureData(userId: String) async {
        UserDefaults.standard.removeObject(forKey: "\(cacheKey)_\(userId)")
        UserDefaults.standard.removeObject(forKey: "\(cacheExpiryKey)_\(userId)")
        print("📦 [Cache] Cleared cache for user: \(userId)")
    }
    
    /// Check if cache is valid
    func isCacheValid(userId: String) -> Bool {
        guard let expiryDate = UserDefaults.standard.object(forKey: "\(cacheExpiryKey)_\(userId)") as? Date else {
            return false
        }
        
        return Date() <= expiryDate
    }
    
    // MARK: - Image Cache
    
    /// Cache image
    func cacheImage(_ image: UIImage, for url: String) {
        imageCache.setObject(image, forKey: url as NSString)
    }
    
    /// Get cached image
    func getCachedImage(for url: String) -> UIImage? {
        return imageCache.object(forKey: url as NSString)
    }
    
    /// Load image with cache
    func loadImage(from urlString: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = getCachedImage(for: urlString) {
            return cachedImage
        }
        
        // Download image
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }
            
            // Cache the image
            cacheImage(image, for: urlString)
            
            return image
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
    
    // MARK: - Quiz Cache
    
    struct CachedQuizData: Codable {
        let lessonId: String
        let questions: [Question]
        let timestamp: Date
    }
    
    /// Save quiz questions to cache
    func saveQuizQuestions(lessonId: String, questions: [Question]) async throws {
        let cachedData = CachedQuizData(
            lessonId: lessonId,
            questions: questions,
            timestamp: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(cachedData)
        
        UserDefaults.standard.set(data, forKey: "quiz_\(lessonId)")
        UserDefaults.standard.set(Date().addingTimeInterval(cacheDuration), forKey: "quiz_expiry_\(lessonId)")
    }
    
    /// Get cached quiz questions
    func getQuizQuestions(lessonId: String) async -> [Question]? {
        guard let data = UserDefaults.standard.data(forKey: "quiz_\(lessonId)"),
              let expiryDate = UserDefaults.standard.object(forKey: "quiz_expiry_\(lessonId)") as? Date else {
            return nil
        }
        
        // Check if cache is expired
        if Date() > expiryDate {
            UserDefaults.standard.removeObject(forKey: "quiz_\(lessonId)")
            UserDefaults.standard.removeObject(forKey: "quiz_expiry_\(lessonId)")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cachedData = try decoder.decode(CachedQuizData.self, from: data)
            return cachedData.questions
        } catch {
            return nil
        }
    }
    
    // MARK: - Progress Cache
    
    /// Update cached progress
    func updateCachedProgress(userId: String, lessonId: String, progress: UserProgress) async {
        // Get existing cached data
        guard var cachedData = await getAdventureData(userId: userId) else { return }
        
        // Update progress
        var updatedProgress = cachedData.userProgress
        updatedProgress[lessonId] = progress
        
        // Save updated data
        try? await saveAdventureData(
            userId: userId,
            chapters: cachedData.chapters,
            progress: updatedProgress,
            crosses: cachedData.totalCrosses,
            correctCount: cachedData.totalCorrectCount
        )
    }
    
    // MARK: - Clear All Cache
    
    /// Clear all cached data
    func clearAllCache() {
        // Clear UserDefaults cache
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.contains(cacheKey) || key.contains(cacheExpiryKey) || key.contains("quiz_") {
                defaults.removeObject(forKey: key)
            }
        }
        
        // Clear image cache
        imageCache.removeAllObjects()
        
        print("📦 [Cache] All cache cleared")
    }
}