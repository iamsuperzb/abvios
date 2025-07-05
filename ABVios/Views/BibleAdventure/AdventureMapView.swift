import SwiftUI

// MARK: - Adventure Map View
struct AdventureMapView: View {
    let chapters: [ChapterData]
    let userProgress: [String: UserProgress]
    let onStartQuiz: (ChapterData) -> Void
    
    @State private var scrollOffset: CGFloat = 0
    @State private var viewSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack {
                    // Background path
                    if chapters.count > 1 {
                        AdventurePathView(chapters: chapters, viewHeight: calculateContentHeight())
                            .allowsHitTesting(false)
                    }
                    
                    // Chapter nodes
                    ForEach(chapters) { chapter in
                        ChapterNodeView(
                            chapter: chapter,
                            position: calculateNodePosition(for: chapter, in: geometry.size),
                            onTap: {
                                if chapter.isUnlocked {
                                    onStartQuiz(chapter)
                                }
                            }
                        )
                    }
                }
                .frame(width: geometry.size.width, height: calculateContentHeight())
                .background(
                    GeometryReader { scrollGeometry in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: scrollGeometry.frame(in: .global).minY
                            )
                    }
                )
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onAppear {
                viewSize = geometry.size
            }
        }
    }
    
    private func calculateContentHeight() -> CGFloat {
        guard let lastChapter = chapters.last else { return 600 }
        return lastChapter.position.y * 10 + 200 // Convert percentage to points with padding
    }
    
    private func calculateNodePosition(for chapter: ChapterData, in size: CGSize) -> CGPoint {
        return CGPoint(
            x: chapter.position.x * size.width / 100,
            y: chapter.position.y * 10 // Convert percentage to points
        )
    }
}

// MARK: - Adventure Path View
struct AdventurePathView: View {
    let chapters: [ChapterData]
    let viewHeight: CGFloat
    
    var body: some View {
        Canvas { context, size in
            // Group chapters by unit for segmented paths
            let unitPaths = generateUnitSegmentedPaths()
            
            for unitPath in unitPaths {
                var path = Path()
                
                guard unitPath.chapters.count > 1 else { continue }
                
                // Create bezier curve path
                for i in 0..<(unitPath.chapters.count - 1) {
                    let start = CGPoint(
                        x: unitPath.chapters[i].position.x * size.width / 100.0,
                        y: unitPath.chapters[i].position.y * 10
                    )
                    let end = CGPoint(
                        x: unitPath.chapters[i + 1].position.x * size.width / 100.0,
                        y: unitPath.chapters[i + 1].position.y * 10
                    )
                    
                    if i == 0 {
                        path.move(to: start)
                    }
                    
                    // Create smooth curve
                    let controlPoint1 = CGPoint(x: start.x, y: (start.y + end.y) / 2)
                    let controlPoint2 = CGPoint(x: end.x, y: (start.y + end.y) / 2)
                    
                    path.addCurve(to: end, control1: controlPoint1, control2: controlPoint2)
                }
                
                // Draw the path
                context.stroke(
                    path,
                    with: .linearGradient(
                        Gradient(colors: [
                            getUnitColor(for: unitPath.unitId).opacity(0.3),
                            getUnitColor(for: unitPath.unitId).opacity(0.5)
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: size.width, y: size.height)
                    ),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [8, 4]
                    )
                )
            }
        }
        .frame(height: viewHeight)
    }
    
    private func generateUnitSegmentedPaths() -> [(unitId: String, chapters: [ChapterData])] {
        var unitGroups: [String: [ChapterData]] = [:]
        
        for chapter in chapters {
            let unitId = chapter.levelData.unitId
            if unitGroups[unitId] == nil {
                unitGroups[unitId] = []
            }
            unitGroups[unitId]?.append(chapter)
        }
        
        return unitGroups.map { (unitId: $0.key, chapters: $0.value) }
    }
    
    private func getUnitColor(for unitId: String) -> Color {
        // Use consistent color based on unit ID hash
        let hash = unitId.hashValue
        let colorIndex = abs(hash) % Constants.Colors.unitColors.count
        return Constants.Colors.unitColors[colorIndex]
    }
}

// MARK: - Chapter Node View
struct ChapterNodeView: View {
    let chapter: ChapterData
    let position: CGPoint
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var showPulse = false
    
    private var nodeSize: CGFloat {
        DeviceInfo.isIPad ? 70 : 60
    }
    
    var body: some View {
        ZStack {
            // Pulse animation for unlocked chapters
            if chapter.isUnlocked && !chapter.isCompleted {
                Circle()
                    .stroke(Constants.Colors.primary.opacity(0.3), lineWidth: 2)
                    .frame(width: nodeSize + 20, height: nodeSize + 20)
                    .scaleEffect(showPulse ? 1.3 : 1.0)
                    .opacity(showPulse ? 0 : 1)
                    .animation(
                        .easeOut(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: showPulse
                    )
            }
            
            // Main node
            Button(action: {
                if chapter.isUnlocked {
                    HapticManager.impact(style: .medium)
                    onTap()
                } else {
                    HapticManager.notification(type: .warning)
                }
            }) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(nodeBackgroundColor)
                        .frame(width: nodeSize, height: nodeSize)
                        .shadow(
                            color: shadowColor,
                            radius: isPressed ? 2 : 8,
                            x: 0,
                            y: isPressed ? 1 : 4
                        )
                    
                    // Progress ring
                    if chapter.isUnlocked && chapter.progress > 0 {
                        ProgressRingView(
                            progress: chapter.progress,
                            color: progressColor,
                            lineWidth: 4
                        )
                        .frame(width: nodeSize - 8, height: nodeSize - 8)
                    }
                    
                    // Center icon
                    nodeIcon
                        .font(.system(size: nodeSize * 0.4, weight: .semibold))
                        .foregroundColor(iconColor)
                    
                    // Stars
                    if chapter.isCompleted && chapter.stars > 0 {
                        StarsView(count: chapter.stars)
                            .offset(y: nodeSize * 0.65)
                    }
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!chapter.isUnlocked)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
            )
            
            // Chapter title
            Text(chapter.title)
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.primaryText)
                .multilineTextAlignment(.center)
                .frame(width: 100)
                .offset(y: nodeSize * 0.9)
        }
        .position(position)
        .onAppear {
            if chapter.isUnlocked && !chapter.isCompleted {
                showPulse = true
            }
        }
    }
    
    private var nodeBackgroundColor: Color {
        if !chapter.isUnlocked {
            return Constants.Colors.locked
        } else if chapter.isCompleted {
            return Constants.Colors.completed
        } else {
            return Constants.Colors.unlocked
        }
    }
    
    private var shadowColor: Color {
        if !chapter.isUnlocked {
            return Color.black.opacity(0.1)
        } else if chapter.isCompleted {
            return Constants.Colors.completed.opacity(0.3)
        } else {
            return Constants.Colors.primary.opacity(0.3)
        }
    }
    
    private var progressColor: Color {
        return chapter.isCompleted ? Constants.Colors.completed : Constants.Colors.primary
    }
    
    private var iconColor: Color {
        if !chapter.isUnlocked {
            return Color.white.opacity(0.6)
        } else {
            return .white
        }
    }
    
    @ViewBuilder
    private var nodeIcon: some View {
        if !chapter.isUnlocked {
            Image(systemName: Constants.Icons.lock)
        } else if chapter.isCompleted {
            Image(systemName: Constants.Icons.checkmark)
        } else {
            Text("\(chapter.questionProgress)")
                .font(.system(size: nodeSize * 0.25, weight: .bold, design: .rounded))
        }
    }
}

// MARK: - Progress Ring View
struct ProgressRingView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

// MARK: - Stars View
struct StarsView: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Image(systemName: index < count ? Constants.Icons.star : Constants.Icons.starEmpty)
                    .font(.system(size: 12))
                    .foregroundColor(Constants.Colors.completed)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct AdventureMapView_Previews: PreviewProvider {
    static var previews: some View {
        AdventureMapView(
            chapters: [],
            userProgress: [:],
            onStartQuiz: { _ in }
        )
    }
}