import Foundation
import UIKit
import SwiftUI

// MARK: - App Constants
struct Constants {
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://www.askbibleverse.com/api/quiz"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let duration: TimeInterval = 5 * 60 // 5 minutes
        static let maxImageCacheSize = 50 * 1024 * 1024 // 50MB
        static let maxImageCount = 100
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.6
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: normal)
        static let easeInOut = SwiftUI.Animation.easeInOut(duration: normal)
    }
    
    // MARK: - Layout Constants
    struct Layout {
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
        static let buttonHeight: CGFloat = 50
        static let tabBarHeight: CGFloat = 83
        static let topBarHeight: CGFloat = 100
    }
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color(red: 0.06, green: 0.72, blue: 0.5)
        static let secondary = Color(red: 0.05, green: 0.58, blue: 0.53)
        
        // Background Colors
        static let background = Color(UIColor.systemBackground)
        static let secondaryBackground = Color(UIColor.secondarySystemBackground)
        static let tertiaryBackground = Color(UIColor.tertiarySystemBackground)
        
        // Text Colors
        static let primaryText = Color(UIColor.label)
        static let secondaryText = Color(UIColor.secondaryLabel)
        static let tertiaryText = Color(UIColor.tertiaryLabel)
        
        // Status Colors
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35)
        static let error = Color(red: 0.91, green: 0.26, blue: 0.21)
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let info = Color(red: 0.0, green: 0.48, blue: 1.0)
        
        // Game Colors
        static let locked = Color(UIColor.systemGray3)
        static let unlocked = primary
        static let completed = Color(red: 0.98, green: 0.75, blue: 0.14)
        
        // Unit Theme Colors
        static let unitColors = [
            Color(red: 0.98, green: 0.42, blue: 0.42), // Red
            Color(red: 0.38, green: 0.65, blue: 0.98), // Blue
            Color(red: 0.2, green: 0.78, blue: 0.35),  // Green
            Color(red: 0.98, green: 0.75, blue: 0.14), // Yellow
            Color(red: 0.65, green: 0.55, blue: 0.98), // Purple
            Color(red: 0.98, green: 0.58, blue: 0.0)   // Orange
        ]
    }
    
    // MARK: - Fonts
    struct Fonts {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    }
    
    // MARK: - Icons
    struct Icons {
        static let home = "house.fill"
        static let bible = "book.fill"
        static let cards = "rectangle.stack.fill"
        static let study = "graduationcap.fill"
        static let profile = "person.crop.circle.fill"
        static let close = "xmark"
        static let checkmark = "checkmark"
        static let star = "star.fill"
        static let starEmpty = "star"
        static let lock = "lock.fill"
        static let unlock = "lock.open.fill"
        static let cross = "cross.fill"
        static let sparkles = "sparkles"
        static let chevronRight = "chevron.right"
        static let chevronLeft = "chevron.left"
        static let info = "info.circle"
        static let warning = "exclamationmark.triangle"
        static let error = "xmark.circle"
        static let success = "checkmark.circle"
    }
    
    // MARK: - Game Configuration
    struct Game {
        static let maxStars = 3
        static let perfectRunBonus = 10
        static let minAccuracyFor1Star = 0.6
        static let minAccuracyFor2Stars = 0.8
        static let minAccuracyFor3Stars = 1.0
        static let freeChaptersForAnonymous = 3
    }
    
    // MARK: - Storage Keys
    struct StorageKeys {
        static let userSession = "user_session"
        static let anonymousUserId = "anonymous_user_id"
        static let cachePrefix = "bible_adventure_cache"
        static let quizCachePrefix = "quiz"
        static let hasSeenOnboarding = "has_seen_onboarding"
        static let soundEnabled = "sound_enabled"
        static let hapticEnabled = "haptic_enabled"
    }
    
    // MARK: - Notification Names
    struct Notifications {
        static let userDidSignIn = Notification.Name("userDidSignIn")
        static let userDidSignOut = Notification.Name("userDidSignOut")
        static let progressUpdated = Notification.Name("progressUpdated")
        static let cardUnlocked = Notification.Name("cardUnlocked")
        static let networkStatusChanged = Notification.Name("networkStatusChanged")
    }
}