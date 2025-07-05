import Foundation
import Combine
import SwiftUI

// MARK: - Quiz View Model
@MainActor
class QuizViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var quizData: QuizData?
    @Published var currentQuestionIndex = 0
    @Published var selectedAnswers: [String: Any] = [:]
    @Published var showExplanation = false
    @Published var isAnswerCorrect = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var quizResult: QuizResult?
    @Published var showCardUnlock = false
    @Published var unlockedCard: Card?
    
    // MARK: - Scoring Properties
    @Published private(set) var score = 0
    @Published private(set) var streak = 0
    @Published private(set) var isPerfectRun = true
    @Published private(set) var lastScoreGained = 0
    @Published private(set) var showScoreAnimation = false
    @Published private(set) var correctAnswersCount = 0
    
    // MARK: - Services
    private let apiService = APIService.shared
    private let cacheService = CacheService.shared
    private let authService = AuthService.shared
    private let scoringSystem = ScoringSystem()
    
    // MARK: - Private Properties
    private var chapter: ChapterData?
    private var questions: [Question] = []
    private var cancellables = Set<AnyCancellable>()
    private var scoreAnimationTimer: Timer?
    
    // MARK: - Computed Properties
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var totalQuestions: Int {
        questions.count
    }
    
    var progress: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(currentQuestionIndex) / Double(totalQuestions)
    }
    
    var isLastQuestion: Bool {
        currentQuestionIndex >= totalQuestions - 1
    }
    
    var canProceed: Bool {
        !selectedAnswers.isEmpty && showExplanation
    }
    
    // MARK: - Initialization
    init() {
        setupScoring()
    }
    
    private func setupScoring() {
        // Observe scoring system changes
        scoringSystem.$score
            .assign(to: &$score)
        
        scoringSystem.$streak
            .assign(to: &$streak)
        
        scoringSystem.$isPerfectRun
            .assign(to: &$isPerfectRun)
        
        scoringSystem.$lastScoreGained
            .assign(to: &$lastScoreGained)
        
        scoringSystem.$showScoreAnimation
            .assign(to: &$showScoreAnimation)
        
        scoringSystem.$correctAnswersCount
            .assign(to: &$correctAnswersCount)
    }
    
    // MARK: - Quiz Loading
    func loadQuiz(for chapter: ChapterData) async {
        self.chapter = chapter
        isLoading = true
        error = nil
        
        // Reset state
        currentQuestionIndex = 0
        selectedAnswers = [:]
        showExplanation = false
        scoringSystem.initialize()
        
        do {
            // Try cache first
            if let cachedQuestions = await cacheService.getQuizQuestions(lessonId: chapter.chapterId) {
                self.questions = cachedQuestions
                self.quizData = QuizData(
                    title: chapter.title,
                    examiner: nil,
                    level: nil,
                    description: nil,
                    questions: cachedQuestions,
                    resultAnalysis: nil,
                    isStreamingPartial: false
                )
                isLoading = false
                return
            }
            
            // Load from API
            let fetchedQuestions = try await apiService.fetchQuestions(lessonId: chapter.chapterId)
            self.questions = fetchedQuestions
            self.quizData = QuizData(
                title: chapter.title,
                examiner: nil,
                level: nil,
                description: nil,
                questions: fetchedQuestions,
                resultAnalysis: nil,
                isStreamingPartial: false
            )
            
            // Cache questions
            try await cacheService.saveQuizQuestions(
                lessonId: chapter.chapterId,
                questions: fetchedQuestions
            )
            
            isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    // MARK: - Answer Handling
    func selectAnswer(_ answer: Any, for questionId: String) {
        selectedAnswers[questionId] = answer
    }
    
    func checkAnswer() {
        guard let question = currentQuestion else { return }
        
        let isCorrect = evaluateAnswer(for: question)
        self.isAnswerCorrect = isCorrect
        self.showExplanation = true
        
        // Process scoring
        scoringSystem.processAnswer(isCorrect: isCorrect)
        
        // Check for card unlock
        if let cardTrigger = question.cardTrigger, isCorrect {
            Task {
                await unlockCard(cardId: cardTrigger)
            }
        }
        
        // Save progress checkpoint
        Task {
            await saveProgressCheckpoint()
        }
    }
    
    private func evaluateAnswer(for question: Question) -> Bool {
        guard let answer = selectedAnswers[question.id] else { return false }
        
        switch question.type {
        case .multipleChoice:
            guard let selectedOption = answer as? String,
                  let options = question.options else { return false }
            return options.first(where: { $0.id == selectedOption })?.isCorrect ?? false
            
        case .fillInBlank:
            guard let userAnswer = answer as? String,
                  let correctAnswer = question.correctAnswer else { return false }
            return userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased() == correctAnswer.lowercased()
            
        case .ordering:
            guard let orderedItems = answer as? [QuestionItem],
                  let originalItems = question.items else { return false }
            
            for (index, item) in orderedItems.enumerated() {
                if item.order != index + 1 {
                    return false
                }
            }
            return true
            
        case .matching:
            guard let matches = answer as? [String: String],
                  let pairs = question.pairs else { return false }
            
            for pair in pairs {
                if matches[pair.left] != pair.right {
                    return false
                }
            }
            return true
        }
    }
    
    // MARK: - Navigation
    func nextQuestion() {
        if currentQuestionIndex < totalQuestions - 1 {
            currentQuestionIndex += 1
            selectedAnswers.removeAll()
            showExplanation = false
            isAnswerCorrect = false
        } else {
            // Quiz completed
            completeQuiz()
        }
    }
    
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
            showExplanation = false
        }
    }
    
    // MARK: - Quiz Completion
    private func completeQuiz() {
        let finalScore = scoringSystem.getFinalScore()
        let stars = scoringSystem.calculateStars(totalQuestions: totalQuestions)
        let accuracy = Double(correctAnswersCount) / Double(totalQuestions)
        
        self.quizResult = QuizResult(
            score: finalScore,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswersCount,
            stars: stars,
            isPerfectRun: isPerfectRun,
            accuracy: accuracy
        )
        
        // Save final progress
        Task {
            await saveFinalProgress()
        }
    }
    
    // MARK: - Progress Saving
    private func saveProgressCheckpoint() async {
        guard let chapter = chapter,
              let userId = authService.user?.id else { return }
        
        let progress = UserProgress(
            lessonId: chapter.chapterId,
            userId: userId,
            status: .inProgress,
            score: score,
            starsEarned: 0,
            progress: Double(currentQuestionIndex) / Double(totalQuestions),
            currentQuestionId: currentQuestion?.id,
            correctQuestionsCount: correctAnswersCount,
            createdAt: nil,
            updatedAt: nil
        )
        
        do {
            try await apiService.saveUserProgress(progress)
        } catch {
            print("Failed to save progress checkpoint: \(error)")
        }
    }
    
    private func saveFinalProgress() async {
        guard let chapter = chapter,
              let userId = authService.user?.id,
              let result = quizResult else { return }
        
        let progress = UserProgress(
            lessonId: chapter.chapterId,
            userId: userId,
            status: .completed,
            score: result.score,
            starsEarned: result.stars,
            progress: 1.0,
            currentQuestionId: nil,
            correctQuestionsCount: result.correctAnswers,
            createdAt: nil,
            updatedAt: nil
        )
        
        do {
            try await apiService.saveUserProgress(progress)
        } catch {
            print("Failed to save final progress: \(error)")
        }
    }
    
    // MARK: - Card Unlocking
    private func unlockCard(cardId: String) async {
        guard let userId = authService.user?.id else { return }
        
        do {
            // Fetch card data
            let card = try await apiService.fetchCard(cardId: cardId, userId: userId)
            
            // Show unlock animation
            self.unlockedCard = card
            self.showCardUnlock = true
            
            // Unlock card in backend
            try await apiService.unlockCard(cardId: cardId, userId: userId)
            
        } catch {
            print("Failed to unlock card: \(error)")
        }
    }
    
    func dismissCardUnlock() {
        showCardUnlock = false
        unlockedCard = nil
    }
    
    // MARK: - Error Tracking
    func trackError(for question: Question) async {
        guard let userId = authService.user?.id,
              let chapter = chapter,
              let answer = selectedAnswers[question.id] else { return }
        
        let userError = UserError(
            errorId: nil,
            userId: userId,
            lessonId: chapter.chapterId,
            questionId: question.id,
            questionType: question.type.rawValue,
            userAnswer: String(describing: answer),
            correctAnswer: question.correctAnswer ?? "",
            errorType: determineErrorType(for: question),
            errorCategory: nil,
            timestamp: Date()
        )
        
        do {
            try await apiService.saveUserError(userError)
        } catch {
            print("Failed to track error: \(error)")
        }
    }
    
    private func determineErrorType(for question: Question) -> UserError.ErrorType {
        switch question.type {
        case .multipleChoice:
            return .wrongSelection
        case .fillInBlank:
            return .spellingError
        case .ordering:
            return .orderingError
        case .matching:
            return .matchingError
        }
    }
}