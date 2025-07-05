import Foundation
import SwiftUI
import CoreGraphics

// MARK: - Path Generator
struct PathGenerator {
    
    // MARK: - S-Shape Patterns
    private static let duolingoSPatterns: [Int: [Double]] = [
        3: [0, 40, -20],         // 3 levels: center → left → right
        4: [0, 30, -30, 20],     // 4 levels: center → left → right → left
        5: [0, 40, 0, -40, 30]   // 5 levels: center → left → center → right → left
    ]
    
    /// Create extended S-shape pattern (for more than 5 levels)
    private static func createExtendedSPattern(count: Int) -> [Double] {
        if count <= 5 {
            return duolingoSPatterns[count] ?? duolingoSPatterns[5]!
        }
        
        var pattern = duolingoSPatterns[5]!
        
        // Continue S-shape pattern after base
        for i in 5..<count {
            let offset = (i - 5) % 2 == 0 ? -20.0 : 20.0
            pattern.append(offset)
        }
        
        return pattern
    }
    
    /// Convert S-offset to X percentage
    private static func convertSOffsetToXPercent(rightOffset: Double, unitIndex: Int = 0) -> Double {
        let centerX = 50.0
        let maxOffset = 80.0
        let maxPercentageRange = 30.0
        
        let offsetPercentage = (rightOffset / maxOffset) * maxPercentageRange
        let finalX = centerX - offsetPercentage
        
        // Add slight base offset for different units
        let unitBaseOffset = Double(unitIndex % 2) * 3.0
        
        return max(15, min(85, finalX + unitBaseOffset))
    }
    
    /// Calculate S-shape X position
    static func calculateSShapeXPosition(
        positionInUnit: Int,
        lessonsPerUnit: Int,
        unitIndex: Int = 0,
        allUnitsData: [(unitIndex: Int, lessonsPerUnit: Int)]? = nil
    ) -> Double {
        
        // Get base S-shape pattern
        let basePattern: [Double]
        if lessonsPerUnit <= 5, let pattern = duolingoSPatterns[lessonsPerUnit] {
            basePattern = pattern
        } else {
            basePattern = createExtendedSPattern(count: lessonsPerUnit)
        }
        
        // Get offset for current position
        let rightOffset = basePattern[positionInUnit]
        
        // Convert to X coordinate percentage
        return convertSOffsetToXPercent(rightOffset: rightOffset, unitIndex: unitIndex)
    }
    
    /// Calculate chapter position
    static func calculatePosition(
        index: Int,
        total: Int,
        unitIndex: Int,
        positionInUnit: Int,
        lessonsPerUnit: Int = 4
    ) -> CGPoint {
        
        // Vertical spacing settings
        let chapterVerticalSpacing = 10.0
        let initialTopOffset = 15.0
        let unitSpacing = 8.0
        
        // Calculate Y coordinate
        let baseY = initialTopOffset + (Double(index) * chapterVerticalSpacing)
        let unitExtraSpacing = Double(unitIndex) * unitSpacing
        let y = baseY + unitExtraSpacing
        
        // Calculate X coordinate
        let x = calculateSShapeXPosition(
            positionInUnit: positionInUnit,
            lessonsPerUnit: lessonsPerUnit,
            unitIndex: unitIndex
        )
        
        return CGPoint(
            x: max(15, min(85, x)),
            y: max(0, y)
        )
    }
}

// MARK: - Chapter Unlock Manager
struct ChapterUnlockManager {
    
    /// Update chapters with user progress
    func updateChaptersWithProgress(chapters: [ChapterData], progressMap: [String: UserProgress]) -> [ChapterData] {
        return chapters.map { chapter in
            var updatedChapter = chapter
            let progress = progressMap[chapter.chapterId]
            let isCompleted = progress?.status == .completed
            
            var isUnlocked = false
            
            // Rule 1: First lesson in each unit is automatically unlocked
            if chapter.levelData.lessonOrderInUnit == 1 {
                isUnlocked = true
            }
            // Rule 2: If user has progress (unlocked, in progress, or completed)
            else if let status = progress?.status,
                    [UserProgress.ProgressStatus.unlocked, .inProgress, .completed].contains(status) {
                isUnlocked = true
            }
            // Rule 3: If previous chapter is completed
            else {
                let prevChapter = chapters.first { ch in
                    ch.levelData.unitId == chapter.levelData.unitId &&
                    ch.levelData.lessonOrderInUnit == chapter.levelData.lessonOrderInUnit - 1
                }
                
                if let prevChapter = prevChapter,
                   let prevProgress = progressMap[prevChapter.chapterId],
                   prevProgress.status == .completed {
                    isUnlocked = true
                }
            }
            
            updatedChapter.isUnlocked = isUnlocked
            updatedChapter.isCompleted = isCompleted
            updatedChapter.progress = progress?.progress ?? 0
            updatedChapter.stars = progress?.starsEarned ?? 0
            
            return updatedChapter
        }
    }
}

// MARK: - Unit Info Extractor
struct UnitInfoExtractor {
    
    /// Extract unit info from chapters
    static func extractUnitsInfo(from chapters: [ChapterData]) -> [UnitInfo] {
        var unitsMap: [String: UnitInfo] = [:]
        
        for chapter in chapters {
            guard let units = chapter.levelData.units else { continue }
            
            if unitsMap[units.unitId] == nil {
                let unitIndex = unitsMap.count
                let themeColor = getUnitThemeColor(index: unitIndex)
                
                unitsMap[units.unitId] = UnitInfo(
                    id: units.unitId,
                    name: units.unitName,
                    description: units.unitDescription,
                    themeColor: themeColor,
                    iconName: getUnitIcon(index: unitIndex),
                    totalLessons: units.totalLessons,
                    index: unitIndex
                )
            }
        }
        
        return Array(unitsMap.values).sorted { $0.index < $1.index }
    }
    
    /// Get theme color for unit
    private static func getUnitThemeColor(index: Int) -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FECA57", "#DDA0DD"]
        return colors[index % colors.count]
    }
    
    /// Get icon for unit
    private static func getUnitIcon(index: Int) -> String {
        let icons = ["star.fill", "heart.fill", "bolt.fill", "flame.fill", "sparkles", "crown.fill"]
        return icons[index % icons.count]
    }
}

// MARK: - Haptic Manager
struct HapticManager {
    
    /// Trigger haptic feedback
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Trigger notification feedback
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Trigger selection feedback
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Device Info
struct DeviceInfo {
    
    /// Check if device is iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Check if device is iPhone
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    /// Get screen size
    static var screenSize: CGSize {
        UIScreen.main.bounds.size
    }
    
    /// Get safe area insets
    static var safeAreaInsets: UIEdgeInsets {
        UIApplication.shared.keyWindow?.safeAreaInsets ?? .zero
    }
    
    /// Check if device has notch
    static var hasNotch: Bool {
        safeAreaInsets.bottom > 0
    }
}

// MARK: - Formatter Helpers
struct Formatters {
    
    /// Number formatter for scores
    static let scoreFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    /// Percentage formatter
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    /// Date formatter for relative dates
    static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}