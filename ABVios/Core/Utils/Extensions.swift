import Foundation
import SwiftUI
import UIKit

// MARK: - View Extensions
extension View {
    /// Apply haptic feedback
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Hide keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    /// Card style modifier
    func cardStyle(backgroundColor: Color = Constants.Colors.secondaryBackground) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(Constants.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    /// Loading overlay
    func loadingOverlay(isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    }
                }
            }
        )
    }
}

// MARK: - Color Extensions
extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Get UIColor from Color
    var uiColor: UIColor {
        UIColor(self)
    }
}

// MARK: - String Extensions
extension String {
    /// Trim whitespace and newlines
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    /// Convert to attributed string with markdown
    func markdownToAttributed() -> AttributedString {
        do {
            return try AttributedString(markdown: self)
        } catch {
            return AttributedString(self)
        }
    }
}

// MARK: - Date Extensions
extension Date {
    /// Format date to string
    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Get relative time string
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - Array Extensions
extension Array {
    /// Safe subscript
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    /// Split array into chunks
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Dictionary Extensions
extension Dictionary where Key == String, Value == UserProgress {
    /// Get progress for lesson ID
    func progress(for lessonId: String) -> UserProgress? {
        return self[lessonId]
    }
    
    /// Get completion percentage
    var completionPercentage: Double {
        guard !isEmpty else { return 0 }
        let completed = values.filter { $0.status == .completed }.count
        return Double(completed) / Double(count)
    }
}

// MARK: - Double Extensions
extension Double {
    /// Format as percentage
    var percentageString: String {
        return "\(Int(self * 100))%"
    }
    
    /// Round to decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - CGPoint Extensions
extension CGPoint {
    /// Distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Midpoint between two points
    func midpoint(to point: CGPoint) -> CGPoint {
        return CGPoint(x: (x + point.x) / 2, y: (y + point.y) / 2)
    }
}

// MARK: - UIApplication Extensions
extension UIApplication {
    /// Get key window
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    /// Get safe area insets
    var safeAreaInsets: UIEdgeInsets {
        keyWindow?.safeAreaInsets ?? .zero
    }
}