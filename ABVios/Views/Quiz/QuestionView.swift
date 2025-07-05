import SwiftUI

// MARK: - Question View
struct QuestionView: View {
    let question: Question
    let selectedAnswer: Any?
    let showExplanation: Bool
    let isCorrect: Bool
    let onAnswerSelected: (Any) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question header
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(question.type.displayName)
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Constants.Colors.primary.opacity(0.1))
                        )
                    
                    Spacer()
                }
                
                Text(question.question)
                    .font(Constants.Fonts.title3)
                    .foregroundColor(Constants.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let hint = question.hint {
                    HStack(spacing: 8) {
                        Image(systemName: Constants.Icons.info)
                            .font(.caption)
                        
                        Text(hint)
                            .font(Constants.Fonts.caption)
                    }
                    .foregroundColor(Constants.Colors.info)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Constants.Colors.info.opacity(0.1))
                    )
                }
            }
            
            // Question content based on type
            Group {
                switch question.type {
                case .multipleChoice:
                    MultipleChoiceQuestionView(
                        question: question,
                        selectedAnswer: selectedAnswer as? String,
                        showExplanation: showExplanation,
                        isCorrect: isCorrect,
                        onAnswerSelected: { answer in
                            onAnswerSelected(answer)
                        }
                    )
                    
                case .fillInBlank:
                    FillInBlankQuestionView(
                        question: question,
                        userAnswer: selectedAnswer as? String ?? "",
                        showExplanation: showExplanation,
                        isCorrect: isCorrect,
                        onAnswerChanged: { answer in
                            onAnswerSelected(answer)
                        }
                    )
                    
                case .ordering:
                    OrderingQuestionView(
                        question: question,
                        orderedItems: selectedAnswer as? [QuestionItem] ?? question.items ?? [],
                        showExplanation: showExplanation,
                        isCorrect: isCorrect,
                        onItemsReordered: { items in
                            onAnswerSelected(items)
                        }
                    )
                    
                case .matching:
                    MatchingQuestionView(
                        question: question,
                        matches: selectedAnswer as? [String: String] ?? [:],
                        showExplanation: showExplanation,
                        isCorrect: isCorrect,
                        onMatchesChanged: { matches in
                            onAnswerSelected(matches)
                        }
                    )
                }
            }
            
            // Answer feedback
            if showExplanation {
                AnswerFeedbackView(
                    isCorrect: isCorrect,
                    explanation: question.explanation
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }
}

// MARK: - Answer Feedback View
struct AnswerFeedbackView: View {
    let isCorrect: Bool
    let explanation: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? Constants.Icons.checkmark : Constants.Icons.close)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isCorrect ? Constants.Colors.success : Constants.Colors.error)
                    )
                
                Text(isCorrect ? "Correct!" : "Not quite right")
                    .font(Constants.Fonts.headline)
                    .foregroundColor(isCorrect ? Constants.Colors.success : Constants.Colors.error)
            }
            
            if let explanation = explanation {
                Text(explanation)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview
struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            QuestionView(
                question: Question(
                    id: "1",
                    type: .multipleChoice,
                    question: "What is the first book of the Bible?",
                    hint: "It starts with 'In the beginning...'",
                    options: [
                        Option(id: "1", text: "Genesis", isCorrect: true, explanation: nil),
                        Option(id: "2", text: "Exodus", isCorrect: false, explanation: nil),
                        Option(id: "3", text: "Matthew", isCorrect: false, explanation: nil),
                        Option(id: "4", text: "John", isCorrect: false, explanation: nil)
                    ],
                    items: nil,
                    pairs: nil,
                    correctAnswer: nil,
                    explanation: "Genesis is the first book of the Bible and describes the creation of the world.",
                    cardTrigger: nil,
                    examinerId: nil
                ),
                selectedAnswer: "1",
                showExplanation: true,
                isCorrect: true,
                onAnswerSelected: { _ in }
            )
            .padding()
        }
    }
}