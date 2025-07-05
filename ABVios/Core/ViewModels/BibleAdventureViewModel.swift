import Foundation
import Combine
import SwiftUI

// MARK: - Bible Adventure View Model
@MainActor
class BibleAdventureViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var chapters: [ChapterData] = []
    @Published var userProgress: [String: UserProgress] = [:]
    @Published var totalCrosses: Int = 0
    @Published var totalCorrectCount: Int = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedChapter: ChapterData?
    @Published var currentUnit: UnitInfo?
    @Published var isCached = false
    
    // MARK: - Services
    private let apiService = APIService.shared
    private let cacheService = CacheService.shared
    let authService = AuthService.shared
    private let userIdentityManager = UserIdentityManager.shared
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var progressCheckTimer: Timer?
    
    // MARK: - Computed Properties
    var progressMap: [String: UserProgress] {
        Dictionary(uniqueKeysWithValues: userProgress.map { ($0.key, $0.value) })
    }
    
    var completedChaptersCount: Int {
        chapters.filter { $0.isCompleted }.count
    }
    
    var totalChaptersCount: Int {
        chapters.count
    }
    
    var overallProgress: Double {
        guard totalChaptersCount > 0 else { return 0 }
        return Double(completedChaptersCount) / Double(totalChaptersCount)
    }
    
    // MARK: - Initialization
    init() {
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe auth state changes
        authService.$user
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    func loadData(forceRefresh: Bool = false) async {
        guard let userId = await getEffectiveUserId() else {
            print("❌ No user ID available")
            return
        }
        
        isLoading = true
        error = nil
        
        // Try cache first unless force refresh
        if !forceRefresh, let cachedData = await cacheService.getAdventureData(userId: userId) {
            self.chapters = cachedData.chapters
            self.userProgress = cachedData.userProgress
            self.totalCrosses = cachedData.totalCrosses
            self.totalCorrectCount = cachedData.totalCorrectCount
            self.isCached = true
            
            // Update chapters with progress
            updateChaptersWithProgress()
            
            isLoading = false
            
            // Refresh in background
            Task {
                await refreshDataInBackground(userId: userId)
            }
            
            return
        }
        
        // Load from API
        await refreshData(userId: userId)
    }
    
    private func refreshData(userId: String) async {
        do {
            // Fetch all data in parallel
            async let chaptersTask = apiService.fetchChapters()
            async let progressTask = apiService.fetchUserProgress(userId: userId)
            async let crossesTask = apiService.fetchUserCrosses(userId: userId)
            async let correctCountTask = apiService.fetchUserCorrectCount(userId: userId)
            
            let (fetchedChapters, fetchedProgress, crosses, correctCount) = try await (
                chaptersTask,
                progressTask,
                crossesTask,
                correctCountTask
            )
            
            // Update state
            self.chapters = fetchedChapters
            self.userProgress = Dictionary(uniqueKeysWithValues: fetchedProgress.map { ($0.lessonId, $0) })
            self.totalCrosses = crosses
            self.totalCorrectCount = correctCount
            self.isCached = false
            
            // Update chapters with progress
            updateChaptersWithProgress()
            
            // Cache the data
            try await cacheService.saveAdventureData(
                userId: userId,
                chapters: fetchedChapters,
                progress: self.userProgress,
                crosses: crosses,
                correctCount: correctCount
            )
            
            isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    private func refreshDataInBackground(userId: String) async {
        do {
            // Fetch fresh data
            async let chaptersTask = apiService.fetchChapters()
            async let progressTask = apiService.fetchUserProgress(userId: userId)
            async let crossesTask = apiService.fetchUserCrosses(userId: userId)
            async let correctCountTask = apiService.fetchUserCorrectCount(userId: userId)
            
            let (fetchedChapters, fetchedProgress, crosses, correctCount) = try await (
                chaptersTask,
                progressTask,
                crossesTask,
                correctCountTask
            )
            
            // Only update if data has changed
            let newProgress = Dictionary(uniqueKeysWithValues: fetchedProgress.map { ($0.lessonId, $0) })
            
            if !chaptersEqual(fetchedChapters, chapters) || !progressEqual(newProgress, userProgress) {
                self.chapters = fetchedChapters
                self.userProgress = newProgress
                self.totalCrosses = crosses
                self.totalCorrectCount = correctCount
                self.isCached = false
                
                // Update chapters with progress
                updateChaptersWithProgress()
                
                // Update cache
                try await cacheService.saveAdventureData(
                    userId: userId,
                    chapters: fetchedChapters,
                    progress: newProgress,
                    crosses: crosses,
                    correctCount: correctCount
                )
            }
            
        } catch {
            print("Background refresh failed: \(error)")
        }
    }
    
    // MARK: - Chapter Management
    private func updateChaptersWithProgress() {
        let unlockManager = ChapterUnlockManager()
        chapters = unlockManager.updateChaptersWithProgress(
            chapters: chapters,
            progressMap: progressMap
        )
        
        // Update current unit
        if let firstUnlockedChapter = chapters.first(where: { $0.isUnlocked && !$0.isCompleted }) {
            currentUnit = firstUnlockedChapter.unitInfo
        }
    }
    
    func startQuiz(for chapter: ChapterData) {
        selectedChapter = chapter
        // Navigation to quiz will be handled by the view
    }
    
    // MARK: - Progress Management
    func updateProgress(for lessonId: String, progress: UserProgress) async {
        // Update local state immediately
        userProgress[lessonId] = progress
        updateChaptersWithProgress()
        
        // Update cache
        if let userId = await getEffectiveUserId() {
            await cacheService.updateCachedProgress(
                userId: userId,
                lessonId: lessonId,
                progress: progress
            )
        }
        
        // Save to backend
        do {
            try await apiService.saveUserProgress(progress)
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
    
    func refreshProgress() async {
        guard let userId = await getEffectiveUserId() else { return }
        
        do {
            let fetchedProgress = try await apiService.fetchUserProgress(userId: userId)
            self.userProgress = Dictionary(uniqueKeysWithValues: fetchedProgress.map { ($0.lessonId, $0) })
            updateChaptersWithProgress()
        } catch {
            print("Failed to refresh progress: \(error)")
        }
    }
    
    // MARK: - Stats Update
    func incrementCrosses() {
        totalCrosses += 1
    }
    
    func incrementCorrectCount() {
        totalCorrectCount += 1
    }
    
    // MARK: - Helper Methods
    private func getEffectiveUserId() async -> String? {
        let authenticatedId = authService.user?.id
        let identity = await userIdentityManager.getCurrentIdentity(authenticatedId: authenticatedId)
        return identity.currentUserId
    }
    
    private func chaptersEqual(_ a: [ChapterData], _ b: [ChapterData]) -> Bool {
        guard a.count == b.count else { return false }
        
        for i in 0..<a.count {
            if a[i].chapterId != b[i].chapterId ||
               a[i].title != b[i].title {
                return false
            }
        }
        
        return true
    }
    
    private func progressEqual(_ a: [String: UserProgress], _ b: [String: UserProgress]) -> Bool {
        guard a.count == b.count else { return false }
        
        for (key, value) in a {
            guard let bValue = b[key] else { return false }
            if value.status != bValue.status ||
               value.score != bValue.score ||
               value.starsEarned != bValue.starsEarned {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Unit Navigation
    func getChaptersForUnit(_ unitId: String) -> [ChapterData] {
        return chapters.filter { $0.levelData.unitId == unitId }
    }
    
    func getNextUnit(after unitId: String) -> UnitInfo? {
        let sortedUnits = chapters
            .compactMap { $0.unitInfo }
            .sorted { $0.index < $1.index }
        
        if let currentIndex = sortedUnits.firstIndex(where: { $0.id == unitId }) {
            let nextIndex = currentIndex + 1
            if nextIndex < sortedUnits.count {
                return sortedUnits[nextIndex]
            }
        }
        
        return nil
    }
    
    func getPreviousUnit(before unitId: String) -> UnitInfo? {
        let sortedUnits = chapters
            .compactMap { $0.unitInfo }
            .sorted { $0.index < $1.index }
        
        if let currentIndex = sortedUnits.firstIndex(where: { $0.id == unitId }) {
            let prevIndex = currentIndex - 1
            if prevIndex >= 0 {
                return sortedUnits[prevIndex]
            }
        }
        
        return nil
    }
}