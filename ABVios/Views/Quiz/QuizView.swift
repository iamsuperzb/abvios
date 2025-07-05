import SwiftUI

// MARK: - Quiz View
struct QuizView: View {
    let chapter: ChapterData
    @EnvironmentObject var adventureViewModel: BibleAdventureViewModel
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var quizViewModel = QuizViewModel()
    @State private var showExitConfirmation = false
    @State private var showFlyingCross = false
    @State private var crossStartPosition: CGPoint = .zero
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if quizViewModel.isLoading {
                LoadingView()
            } else if let error = quizViewModel.error {
                ErrorView(error: error) {
                    Task {
                        await quizViewModel.loadQuiz(for: chapter)
                    }
                }
            } else if let result = quizViewModel.quizResult {
                // Quiz completed
                QuizResultView(
                    result: result,
                    chapter: chapter,
                    onContinue: {
                        dismiss()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else if let currentQuestion = quizViewModel.currentQuestion {
                // Quiz content
                VStack(spacing: 0) {
                    // Header
                    QuizHeaderView(
                        title: chapter.title,
                        currentQuestion: quizViewModel.currentQuestionIndex + 1,
                        totalQuestions: quizViewModel.totalQuestions,
                        score: quizViewModel.score,
                        onClose: {
                            showExitConfirmation = true
                        }
                    )
                    
                    // Progress bar
                    ProgressView(value: quizViewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Constants.Colors.primary))
                        .frame(height: 4)
                    
                    // Question content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question
                            QuestionView(
                                question: currentQuestion,
                                selectedAnswer: quizViewModel.selectedAnswers[currentQuestion.id],
                                showExplanation: quizViewModel.showExplanation,
                                isCorrect: quizViewModel.isAnswerCorrect,
                                onAnswerSelected: { answer in
                                    quizViewModel.selectAnswer(answer, for: currentQuestion.id)
                                }
                            )
                            .padding(.horizontal)
                            .padding(.top, 24)
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                if quizViewModel.showExplanation {
                                    Button(action: {
                                        withAnimation {
                                            quizViewModel.nextQuestion()
                                        }
                                    }) {
                                        Label(
                                            quizViewModel.isLastQuestion ? "Finish" : "Next",
                                            systemImage: quizViewModel.isLastQuestion ? Constants.Icons.checkmark : Constants.Icons.chevronRight
                                        )
                                        .font(Constants.Fonts.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Constants.Colors.primary)
                                        .cornerRadius(25)
                                    }
                                    .hapticFeedback()
                                } else {
                                    Button(action: {
                                        // Get cross position before checking
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let window = windowScene.windows.first {
                                            let buttonFrame = window.convert(CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 200, width: 0, height: 0), from: nil)
                                            crossStartPosition = CGPoint(x: buttonFrame.midX, y: buttonFrame.midY)
                                        }
                                        
                                        quizViewModel.checkAnswer()
                                        
                                        // Show flying cross if correct
                                        if quizViewModel.isAnswerCorrect {
                                            showFlyingCross = true
                                        }
                                    }) {
                                        Text("Check Answer")
                                            .font(Constants.Fonts.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                quizViewModel.selectedAnswers[currentQuestion.id] != nil
                                                    ? Constants.Colors.primary
                                                    : Color.gray
                                            )
                                            .cornerRadius(25)
                                    }
                                    .hapticFeedback()
                                    .disabled(quizViewModel.selectedAnswers[currentQuestion.id] == nil)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                    
                    // Score animation
                    if quizViewModel.showScoreAnimation {
                        ScoreAnimationView(score: quizViewModel.lastScoreGained)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
            }
            
            // Flying cross animation
            if showFlyingCross {
                FlyingCrossView(
                    startPosition: crossStartPosition,
                    onComplete: {
                        showFlyingCross = false
                        adventureViewModel.incrementCrosses()
                    }
                )
            }
            
            // Card unlock animation
            if quizViewModel.showCardUnlock, let card = quizViewModel.unlockedCard {
                CardUnlockView(
                    card: card,
                    isVisible: quizViewModel.showCardUnlock,
                    onClose: {
                        quizViewModel.dismissCardUnlock()
                    }
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            await quizViewModel.loadQuiz(for: chapter)
        }
        .alert("Exit Quiz?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Your progress will be saved.")
        }
    }
}

// MARK: - Quiz Header View
struct QuizHeaderView: View {
    let title: String
    let currentQuestion: Int
    let totalQuestions: Int
    let score: Int
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            // Close button
            Button(action: onClose) {
                Image(systemName: Constants.Icons.close)
                    .font(.title2)
                    .foregroundColor(Constants.Colors.primaryText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.black.opacity(0.05)))
            }
            .hapticFeedback()
            
            Spacer()
            
            // Question counter
            Text("\(currentQuestion) / \(totalQuestions)")
                .font(Constants.Fonts.headline)
                .foregroundColor(Constants.Colors.secondaryText)
            
            Spacer()
            
            // Score
            HStack(spacing: 4) {
                Image(systemName: Constants.Icons.star)
                    .font(.system(size: 18))
                    .foregroundColor(Constants.Colors.warning)
                
                Text("\(score)")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(Constants.Colors.primaryText)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Constants.Colors.warning.opacity(0.1))
            )
        }
        .padding()
    }
}

// MARK: - Score Animation View
struct ScoreAnimationView: View {
    let score: Int
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Text("+\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Constants.Colors.success)
                    .padding()
                    .background(
                        Circle()
                            .fill(Constants.Colors.success.opacity(0.2))
                    )
                    .padding()
            }
        }
    }
}

// MARK: - Flying Cross View
struct FlyingCrossView: View {
    let startPosition: CGPoint
    let onComplete: () -> Void
    
    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    init(startPosition: CGPoint, onComplete: @escaping () -> Void) {
        self.startPosition = startPosition
        self.onComplete = onComplete
        self._position = State(initialValue: startPosition)
    }
    
    var body: some View {
        Image(systemName: Constants.Icons.cross)
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(Constants.Colors.primary)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                animateCross()
            }
    }
    
    private func animateCross() {
        // Target position (top bar cross counter)
        let endPosition = CGPoint(x: 80, y: 100)
        
        // Create parabolic path
        withAnimation(.easeOut(duration: 1.0)) {
            position = endPosition
            scale = 0.5
            rotation = 360
        }
        
        withAnimation(.easeIn(duration: 0.8).delay(0.2)) {
            opacity = 0
        }
        
        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onComplete()
        }
    }
}

// MARK: - Preview
struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            QuizView(chapter: ChapterData(
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
            ))
            .environmentObject(BibleAdventureViewModel())
        }
    }
}