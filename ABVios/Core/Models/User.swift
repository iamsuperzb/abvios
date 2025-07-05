import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let name: String?
    let userType: UserType
    let createdAt: Date
    let isAnonymous: Bool
    
    enum UserType: String, Codable {
        case clerk = "clerk"
        case temporary = "temporary"
        case apple = "apple"
        case google = "google"
        case anonymous = "anonymous"
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case email, name
        case userType = "user_type"
        case createdAt = "created_at"
        case isAnonymous = "is_anonymous"
    }
}

// MARK: - User Progress
struct UserProgress: Codable {
    let lessonId: String
    let userId: String
    let status: ProgressStatus
    var score: Int
    var starsEarned: Int
    var progress: Double
    let currentQuestionId: String?
    var correctQuestionsCount: Int
    let createdAt: Date?
    let updatedAt: Date?
    
    enum ProgressStatus: String, Codable {
        case locked = "locked"
        case unlocked = "unlocked"
        case inProgress = "in_progress"
        case completed = "completed"
    }
    
    private enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case userId = "user_id"
        case status
        case score
        case starsEarned = "stars_earned"
        case progress
        case currentQuestionId = "current_question_id"
        case correctQuestionsCount = "correct_questions_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - User Stats
struct UserStats: Codable {
    let totalCrosses: Int
    let totalCorrectCount: Int
    let totalCardsUnlocked: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalPlayTime: Int
    
    private enum CodingKeys: String, CodingKey {
        case totalCrosses = "total_crosses"
        case totalCorrectCount = "total_correct_count"
        case totalCardsUnlocked = "total_cards_unlocked"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalPlayTime = "total_play_time"
    }
}

// MARK: - User Error Record
struct UserError: Codable {
    let errorId: String?
    let userId: String
    let lessonId: String
    let questionId: String
    let questionType: String
    let userAnswer: String
    let correctAnswer: String
    let errorType: ErrorType
    let errorCategory: String?
    let timestamp: Date
    
    enum ErrorType: String, Codable {
        case wrongSelection = "wrong_selection"
        case spellingError = "spelling_error"
        case orderingError = "ordering_error"
        case matchingError = "matching_error"
        case conceptualError = "conceptual_error"
    }
    
    private enum CodingKeys: String, CodingKey {
        case errorId = "error_id"
        case userId = "user_id"
        case lessonId = "lesson_id"
        case questionId = "question_id"
        case questionType = "question_type"
        case userAnswer = "user_answer"
        case correctAnswer = "correct_answer"
        case errorType = "error_type"
        case errorCategory = "error_category"
        case timestamp
    }
}

// MARK: - User Session
struct UserSession: Codable {
    let sessionId: String
    let userId: String
    let authToken: String?
    let refreshToken: String?
    let expiresAt: Date
    let isAnonymous: Bool
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}

// MARK: - User Identity
struct UserIdentity {
    let currentUserId: String
    let isTemporary: Bool
    let syncRequired: Bool
    let displayName: String?
    let email: String?
    
    var needsUpgrade: Bool {
        return isTemporary
    }
}