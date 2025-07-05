import Foundation
import UIKit

// MARK: - Card Model
struct Card: Codable, Identifiable {
    let id: String
    let cardId: String
    let name: String
    let title: String
    let rarity: Rarity
    let description: String?
    let imageUrl: String?
    let keyVerse: String?
    let bookName: String
    let cardType: CardType
    let unlockChapter: Int
    let evolutionChainId: String?
    let evolutionStage: Int?
    
    enum Rarity: String, Codable, CaseIterable {
        case C = "C"     // Common
        case R = "R"     // Rare
        case SR = "SR"   // Super Rare
        case SSR = "SSR" // Super Super Rare
        case UR = "UR"   // Ultra Rare
        
        var displayName: String {
            switch self {
            case .C: return "Common"
            case .R: return "Rare"
            case .SR: return "Super Rare"
            case .SSR: return "Super Super Rare"
            case .UR: return "Ultra Rare"
            }
        }
        
        var color: UIColor {
            switch self {
            case .C: return UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 1.0) // gray-400
            case .R: return UIColor(red: 0.38, green: 0.65, blue: 0.98, alpha: 1.0) // blue-400
            case .SR: return UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 1.0) // purple-400
            case .SSR: return UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0) // yellow-400
            case .UR: return UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1.0) // red-400
            }
        }
        
        var glowColor: UIColor {
            switch self {
            case .C: return UIColor(red: 0.61, green: 0.64, blue: 0.69, alpha: 0.5)
            case .R: return UIColor(red: 0.38, green: 0.65, blue: 0.98, alpha: 0.6)
            case .SR: return UIColor(red: 0.65, green: 0.55, blue: 0.98, alpha: 0.7)
            case .SSR: return UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 0.8)
            case .UR: return UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 0.9)
            }
        }
    }
    
    enum CardType: String, Codable {
        case character = "character"
        case location = "location"
        case event = "event"
        case artifact = "artifact"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.cardId = try container.decode(String.self, forKey: .cardId)
        self.id = cardId // Use cardId as the Identifiable id
        self.name = try container.decode(String.self, forKey: .name)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        
        // Handle rarity with validation
        let rarityString = try container.decode(String.self, forKey: .rarity)
        self.rarity = Rarity(rawValue: rarityString) ?? .C
        
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.keyVerse = try container.decodeIfPresent(String.self, forKey: .keyVerse)
        self.bookName = try container.decodeIfPresent(String.self, forKey: .bookName) ?? ""
        
        let cardTypeString = try container.decodeIfPresent(String.self, forKey: .cardType) ?? "character"
        self.cardType = CardType(rawValue: cardTypeString) ?? .character
        
        self.unlockChapter = try container.decodeIfPresent(Int.self, forKey: .unlockChapter) ?? 0
        self.evolutionChainId = try container.decodeIfPresent(String.self, forKey: .evolutionChainId)
        self.evolutionStage = try container.decodeIfPresent(Int.self, forKey: .evolutionStage)
    }
    
    private enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case name, title, rarity, description
        case imageUrl = "image_url"
        case keyVerse = "key_verse"
        case bookName = "book_name"
        case cardType = "card_type"
        case unlockChapter = "unlock_chapter"
        case evolutionChainId = "evolution_chain_id"
        case evolutionStage = "evolution_stage"
    }
}

// MARK: - User Unlocked Card
struct UserUnlockedCard: Codable {
    let userId: String
    let cardId: String
    let unlockedAt: Date
    let card: Card?
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case cardId = "card_id"
        case unlockedAt = "unlocked_at"
        case card
    }
}

// MARK: - Card Collection Stats
struct CardCollectionStats: Codable {
    let totalCards: Int
    let unlockedCards: Int
    let commonCards: Int
    let rareCards: Int
    let superRareCards: Int
    let superSuperRareCards: Int
    let ultraRareCards: Int
    
    var completionPercentage: Double {
        guard totalCards > 0 else { return 0 }
        return Double(unlockedCards) / Double(totalCards) * 100
    }
    
    var formattedCompletion: String {
        return "\(unlockedCards)/\(totalCards)"
    }
}

// MARK: - Card Reward Trigger
struct CardRewardTrigger: Codable {
    let cardId: String
    let lessonId: String
    let questionId: String
    let triggerType: TriggerType
    
    enum TriggerType: String, Codable {
        case questionCorrect = "question_correct"
        case lessonComplete = "lesson_complete"
        case perfectScore = "perfect_score"
        case streakReward = "streak_reward"
    }
    
    private enum CodingKeys: String, CodingKey {
        case cardId = "card_id"
        case lessonId = "lesson_id"
        case questionId = "question_id"
        case triggerType = "trigger_type"
    }
}