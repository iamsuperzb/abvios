import SwiftUI

// MARK: - Quiz Result View
struct QuizResultView: View {
    let result: QuizResult
    let chapter: ChapterData
    let onContinue: () -> Void
    
    @State private var showConfetti = false
    @State private var animateElements = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Constants.Colors.primary.opacity(0.1),
                    Constants.Colors.secondary.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Confetti for perfect score
            if result.isPerfectRun && showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Trophy or completion icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Constants.Colors.primary,
                                    Constants.Colors.secondary
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: Constants.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: result.isPerfectRun ? "trophy.fill" : "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }
                .scaleEffect(animateElements ? 1.0 : 0.5)
                .opacity(animateElements ? 1.0 : 0)
                
                // Title
                Text(result.isPerfectRun ? "Perfect Score!" : "Quiz Complete!")
                    .font(Constants.Fonts.largeTitle)
                    .foregroundColor(Constants.Colors.primaryText)
                    .opacity(animateElements ? 1.0 : 0)
                    .offset(y: animateElements ? 0 : 20)
                
                // Score details
                VStack(spacing: 20) {
                    // Main score
                    HStack(spacing: 16) {
                        ScoreCard(
                            title: "Score",
                            value: "\(result.score)",
                            icon: Constants.Icons.star,
                            color: Constants.Colors.warning
                        )
                        
                        ScoreCard(
                            title: "Accuracy",
                            value: result.accuracyPercentage,
                            icon: Constants.Icons.checkmark,
                            color: Constants.Colors.success
                        )
                    }
                    
                    // Stars earned
                    StarsEarnedView(count: result.stars)
                        .scaleEffect(animateElements ? 1.0 : 0.8)
                        .opacity(animateElements ? 1.0 : 0)
                    
                    // Summary text
                    Text("You got \(result.correctAnswers) out of \(result.totalQuestions) questions correct!")
                        .font(Constants.Fonts.body)
                        .foregroundColor(Constants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .opacity(animateElements ? 1.0 : 0)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    HapticManager.impact(style: .medium)
                    onContinue()
                }) {
                    Text("Continue Adventure")
                        .font(Constants.Fonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Constants.Colors.primary,
                                    Constants.Colors.secondary
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Constants.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(animateElements ? 1.0 : 0)
                .offset(y: animateElements ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateElements = true
            }
            
            if result.isPerfectRun {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showConfetti = true
                    HapticManager.notification(type: .success)
                }
            }
        }
    }
}

// MARK: - Score Card
struct ScoreCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(Constants.Fonts.largeTitle)
                    .foregroundColor(Constants.Colors.primaryText)
            }
            
            Text(title)
                .font(Constants.Fonts.caption)
                .foregroundColor(Constants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Stars Earned View
struct StarsEarnedView: View {
    let count: Int
    @State private var animateStars = [false, false, false]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<3) { index in
                Image(systemName: index < count ? Constants.Icons.star : Constants.Icons.starEmpty)
                    .font(.system(size: 40))
                    .foregroundColor(index < count ? Constants.Colors.warning : Color.gray.opacity(0.3))
                    .scaleEffect(animateStars[index] ? 1.2 : 1.0)
                    .rotationEffect(.degrees(animateStars[index] ? 360 : 0))
            }
        }
        .onAppear {
            for i in 0..<count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        animateStars[i] = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            animateStars[i] = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                createConfetti(in: geometry.size)
            }
        }
    }
    
    private func createConfetti(in size: CGSize) {
        for _ in 0..<50 {
            let piece = ConfettiPiece(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: -20
                ),
                color: Constants.Colors.unitColors.randomElement() ?? Constants.Colors.primary,
                size: CGFloat.random(in: 8...15),
                velocity: CGFloat.random(in: 200...400),
                spin: CGFloat.random(in: -5...5)
            )
            confettiPieces.append(piece)
        }
    }
}

// MARK: - Confetti Piece
struct ConfettiPiece: Identifiable {
    let id = UUID()
    let position: CGPoint
    let color: Color
    let size: CGFloat
    let velocity: CGFloat
    let spin: CGFloat
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    init(piece: ConfettiPiece) {
        self.piece = piece
        self._position = State(initialValue: piece.position)
    }
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(.linear(duration: 3)) {
                    position.y = UIScreen.main.bounds.height + 100
                    rotation = piece.spin * 360
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview
struct QuizResultView_Previews: PreviewProvider {
    static var previews: some View {
        QuizResultView(
            result: QuizResult(
                score: 15,
                totalQuestions: 5,
                correctAnswers: 5,
                stars: 3,
                isPerfectRun: true,
                accuracy: 1.0
            ),
            chapter: ChapterData(
                id: "1",
                chapterId: "1",
                title: "Sample Chapter",
                position: ChapterData.Position(x: 50, y: 50),
                levelData: QuizLesson(
                    lessonId: "1",
                    title: "Sample",
                    bibleReference: "Genesis 1",
                    lessonOrderInUnit: 1,
                    unitId: "1",
                    units: nil
                ),
                questions: [],
                isUnlocked: true,
                isCompleted: false,
                progress: 0,
                stars: 0,
                unitInfo: nil
            ),
            onContinue: {}
        )
    }
}