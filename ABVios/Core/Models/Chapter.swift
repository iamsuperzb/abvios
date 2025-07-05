import Foundation
import CoreGraphics

// MARK: - Chapter Data Model
struct ChapterData: Codable, Identifiable {
    let id: String
    let chapterId: String
    let title: String
    let position: Position
    let levelData: QuizLesson
    var questions: [Question]
    var isUnlocked: Bool
    var isCompleted: Bool
    var progress: Double
    var stars: Int
    let unitInfo: UnitInfo?
    
    struct Position: Codable {
        let x: Double
        let y: Double
        
        var cgPoint: CGPoint {
            CGPoint(x: x, y: y)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chapterId = try container.decode(String.self, forKey: .chapterId)
        self.id = chapterId // Use chapterId as the Identifiable id
        self.title = try container.decode(String.self, forKey: .title)
        self.position = try container.decode(Position.self, forKey: .position)
        self.levelData = try container.decode(QuizLesson.self, forKey: .levelData)
        self.questions = try container.decodeIfPresent([Question].self, forKey: .questions) ?? []
        self.isUnlocked = try container.decodeIfPresent(Bool.self, forKey: .isUnlocked) ?? false
        self.isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        self.progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        self.stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        self.unitInfo = try container.decodeIfPresent(UnitInfo.self, forKey: .unitInfo)
    }
    
    private enum CodingKeys: String, CodingKey {
        case chapterId, title, position, levelData, questions
        case isUnlocked, isCompleted, progress, stars, unitInfo
    }
}

// MARK: - Quiz Lesson
struct QuizLesson: Codable {
    let lessonId: String
    let title: String
    let bibleReference: String
    let lessonOrderInUnit: Int
    let unitId: String
    let units: Unit?
    
    private enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case title
        case bibleReference = "bible_reference"
        case lessonOrderInUnit = "lesson_order_in_unit"
        case unitId = "unit_id"
        case units
    }
}

// MARK: - Unit Info
struct UnitInfo: Codable {
    let id: String
    let name: String
    let description: String?
    let themeColor: String?
    let iconName: String?
    let totalLessons: Int
    let index: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "unit_id"
        case name = "unit_name"
        case description = "unit_description"
        case themeColor = "theme_color"
        case iconName = "icon_name"
        case totalLessons = "total_lessons"
        case index = "unit_index"
    }
}

// MARK: - Unit
struct Unit: Codable {
    let unitId: String
    let unitName: String
    let unitDescription: String?
    let totalLessons: Int
    
    private enum CodingKeys: String, CodingKey {
        case unitId = "unit_id"
        case unitName = "unit_name"
        case unitDescription = "unit_description"
        case totalLessons = "total_lessons"
    }
}

// MARK: - Chapter Helper Functions
extension ChapterData {
    var questionProgress: String {
        let answered = Int(progress * Double(questions.count))
        return "\(answered)/\(questions.count)"
    }
    
    var completionPercentage: Double {
        return progress * 100
    }
    
    var starRating: Int {
        return min(max(stars, 0), 3)
    }
}