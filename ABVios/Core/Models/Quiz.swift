import Foundation

// MARK: - Quiz Data Model
struct QuizData: Codable {
    let title: String
    let examiner: String?
    let level: String?
    let description: String?
    var questions: [Question]
    let resultAnalysis: ResultAnalysis?
    let isStreamingPartial: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case title, examiner, level, description, questions
        case resultAnalysis = "result_analysis"
        case isStreamingPartial = "is_streaming_partial"
    }
}

// MARK: - Question Model
struct Question: Codable, Identifiable {
    let id: String
    let type: QuestionType
    let question: String
    let hint: String?
    let options: [Option]?
    let items: [QuestionItem]?
    let pairs: [MatchPair]?
    let correctAnswer: String?
    let explanation: String?
    let cardTrigger: String?
    let examinerId: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Generate ID if not provided
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.type = try container.decode(QuestionType.self, forKey: .type)
        self.question = try container.decode(String.self, forKey: .question)
        self.hint = try container.decodeIfPresent(String.self, forKey: .hint)
        self.options = try container.decodeIfPresent([Option].self, forKey: .options)
        self.items = try container.decodeIfPresent([QuestionItem].self, forKey: .items)
        self.pairs = try container.decodeIfPresent([MatchPair].self, forKey: .pairs)
        self.correctAnswer = try container.decodeIfPresent(String.self, forKey: .correctAnswer)
        self.explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        self.cardTrigger = try container.decodeIfPresent(String.self, forKey: .cardTrigger)
        self.examinerId = try container.decodeIfPresent(String.self, forKey: .examinerId)
    }
    
    // Convenience initializer for previews and testing
    init(id: String, type: QuestionType, question: String, hint: String?, 
         options: [Option]?, items: [QuestionItem]?, pairs: [MatchPair]?, 
         correctAnswer: String?, explanation: String?, cardTrigger: String?, examinerId: String?) {
        self.id = id
        self.type = type
        self.question = question
        self.hint = hint
        self.options = options
        self.items = items
        self.pairs = pairs
        self.correctAnswer = correctAnswer
        self.explanation = explanation
        self.cardTrigger = cardTrigger
        self.examinerId = examinerId
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, question, hint, options, items, pairs
        case correctAnswer = "correct_answer"
        case explanation
        case cardTrigger = "card_trigger"
        case examinerId = "examiner_id"
    }
}

// MARK: - Question Type
enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice = "multiple_choice"
    case fillInBlank = "fill_in_blank"
    case ordering = "ordering"
    case matching = "matching"
    
    var displayName: String {
        switch self {
        case .multipleChoice:
            return "Multiple Choice"
        case .fillInBlank:
            return "Fill in the Blank"
        case .ordering:
            return "Put in Order"
        case .matching:
            return "Match the Pairs"
        }
    }
}

// MARK: - Option Model
struct Option: Codable, Identifiable {
    let id: String
    let text: String
    let isCorrect: Bool
    let explanation: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.text = try container.decode(String.self, forKey: .text)
        
        // Handle both Bool and String values for isCorrect
        if let boolValue = try? container.decode(Bool.self, forKey: .isCorrect) {
            self.isCorrect = boolValue
        } else if let stringValue = try? container.decode(String.self, forKey: .isCorrect) {
            self.isCorrect = stringValue.lowercased() == "true"
        } else {
            self.isCorrect = false
        }
        
        self.explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
    }
    
    // Convenience initializer for previews and testing
    init(id: String, text: String, isCorrect: Bool, explanation: String?) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
        self.explanation = explanation
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text
        case isCorrect = "is_correct"
        case explanation
    }
}

// MARK: - Question Item (for ordering questions)
struct QuestionItem: Codable, Identifiable {
    let id: String
    let text: String
    let order: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.text = try container.decode(String.self, forKey: .text)
        self.order = try container.decode(Int.self, forKey: .order)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, text, order
    }
}

// MARK: - Match Pair (for matching questions)
struct MatchPair: Codable, Identifiable {
    let id: String
    let left: String
    let right: String
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.left = try container.decode(String.self, forKey: .left)
        self.right = try container.decode(String.self, forKey: .right)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, left, right
    }
}

// MARK: - Result Analysis
struct ResultAnalysis: Codable {
    let strengths: [AnalysisItem]
    let improvements: [AnalysisItem]
}

struct AnalysisItem: Codable {
    let category: String
    let description: String
}

// MARK: - Quiz Result
struct QuizResult: Codable {
    let score: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let stars: Int
    let isPerfectRun: Bool
    let accuracy: Double
    
    var accuracyPercentage: String {
        return "\(Int(accuracy * 100))%"
    }
}

// MARK: - Answer Result
struct AnswerResult {
    let isCorrect: Bool
    let explanation: String?
    let pointsEarned: Int
}