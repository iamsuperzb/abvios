import Foundation
import Combine

// MARK: - Scoring System
class ScoringSystem: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var isPerfectRun: Bool = true
    @Published private(set) var lastScoreGained: Int = 0
    @Published private(set) var showScoreAnimation: Bool = false
    @Published private(set) var correctAnswersCount: Int = 0
    
    private var isInitialized: Bool = false
    private var scoreAnimationTimer: Timer?
    
    /// Initialize scoring system
    func initialize(initialScore: Int = 0, initialCorrectCount: Int = 0) {
        self.score = initialScore
        self.correctAnswersCount = initialCorrectCount
        self.streak = 0
        self.isPerfectRun = true
        self.lastScoreGained = 0
        self.showScoreAnimation = false
        self.isInitialized = true
        
        print("✅ [ScoringSystem] Initialized: score=\(initialScore), correctCount=\(initialCorrectCount)")
    }
    
    /// Process answer and update score
    func processAnswer(isCorrect: Bool) {
        print("🎯 [ScoringSystem] Processing answer: isCorrect=\(isCorrect), currentScore=\(score), currentCorrectCount=\(correctAnswersCount)")
        
        if isCorrect {
            // Calculate score: base score 1 + streak bonus
            let questionScore = 1 + streak
            score += questionScore
            streak += 1
            lastScoreGained = questionScore
            correctAnswersCount += 1
            
            // Trigger score animation
            showScoreAnimation = true
            startScoreAnimationTimer()
            
            print("✅ Correct! Score: +\(questionScore) (base: 1 + streak: \(streak - 1)) Total: \(score), Correct count: \(correctAnswersCount)")
        } else {
            // Wrong answer: reset streak, mark non-perfect run
            streak = 0
            isPerfectRun = false
            lastScoreGained = 0
            print("❌ Wrong! Streak reset")
        }
    }
    
    /// Get final score (including perfect run bonus)
    func getFinalScore() -> Int {
        if isPerfectRun {
            return score + 10 // Perfect run bonus: 10 points
        }
        return score
    }
    
    /// Calculate star rating
    /// - Parameters:
    ///   - totalQuestions: Total number of questions
    /// - Returns: Number of stars earned (0-3)
    func calculateStars(totalQuestions: Int) -> Int {
        let accuracy = Double(correctAnswersCount) / Double(totalQuestions)
        
        if isPerfectRun {
            return 3 // Perfect run: 3 stars
        } else if accuracy >= 0.8 {
            return 2 // 80% or higher: 2 stars
        } else if accuracy >= 0.6 {
            return 1 // 60% or higher: 1 star
        } else {
            return 0 // Below 60%: 0 stars
        }
    }
    
    private func startScoreAnimationTimer() {
        scoreAnimationTimer?.invalidate()
        scoreAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.showScoreAnimation = false
        }
    }
}

// Scoring Algorithm Details:
// 1. Base score: 1 point per correct answer
// 2. Streak bonus: Additional points equal to current streak (streak - 1)
// 3. Perfect run: Extra 10 points if all answers are correct
// 4. Star rating:
//    - 3 stars: Perfect run (100% correct)
//    - 2 stars: 80% or more correct
//    - 1 star: 60% or more correct
//    - 0 stars: Below 60% correct