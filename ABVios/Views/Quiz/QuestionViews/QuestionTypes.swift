import SwiftUI

// MARK: - Multiple Choice Question View
struct MultipleChoiceQuestionView: View {
    let question: Question
    let selectedAnswer: String?
    let showExplanation: Bool
    let isCorrect: Bool
    let onAnswerSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(question.options ?? []) { option in
                MultipleChoiceOptionView(
                    option: option,
                    isSelected: selectedAnswer == option.id,
                    isDisabled: showExplanation,
                    showResult: showExplanation,
                    onTap: {
                        if !showExplanation {
                            onAnswerSelected(option.id)
                            HapticManager.selection()
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Multiple Choice Option View
struct MultipleChoiceOptionView: View {
    let option: Option
    let isSelected: Bool
    let isDisabled: Bool
    let showResult: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    private var backgroundColor: Color {
        if showResult {
            if option.isCorrect {
                return Constants.Colors.success.opacity(0.1)
            } else if isSelected && !option.isCorrect {
                return Constants.Colors.error.opacity(0.1)
            }
        }
        
        if isSelected {
            return Constants.Colors.primary.opacity(0.1)
        }
        
        return Color(UIColor.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        if showResult {
            if option.isCorrect {
                return Constants.Colors.success
            } else if isSelected && !option.isCorrect {
                return Constants.Colors.error
            }
        }
        
        if isSelected {
            return Constants.Colors.primary
        }
        
        return Color.clear
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected || (showResult && option.isCorrect) {
                        Circle()
                            .fill(borderColor)
                            .frame(width: 16, height: 16)
                    }
                }
                
                // Option text
                Text(option.text)
                    .font(Constants.Fonts.body)
                    .foregroundColor(Constants.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Result icon
                if showResult {
                    if option.isCorrect {
                        Image(systemName: Constants.Icons.checkmark)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Constants.Colors.success)
                    } else if isSelected && !option.isCorrect {
                        Image(systemName: Constants.Icons.close)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Constants.Colors.error)
                    }
                }
            }
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
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
    }
}

// MARK: - Fill In Blank Question View
struct FillInBlankQuestionView: View {
    let question: Question
    @State var userAnswer: String
    let showExplanation: Bool
    let isCorrect: Bool
    let onAnswerChanged: (String) -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Type your answer here...", text: $userAnswer)
                .font(Constants.Fonts.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            showExplanation
                                ? (isCorrect ? Constants.Colors.success : Constants.Colors.error)
                                : (isTextFieldFocused ? Constants.Colors.primary : Color.clear),
                            lineWidth: 2
                        )
                )
                .focused($isTextFieldFocused)
                .disabled(showExplanation)
                .onChange(of: userAnswer) { newValue in
                    onAnswerChanged(newValue)
                }
                .submitLabel(.done)
                .onSubmit {
                    isTextFieldFocused = false
                }
            
            if showExplanation && !isCorrect, let correctAnswer = question.correctAnswer {
                HStack {
                    Text("Correct answer:")
                        .font(Constants.Fonts.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                    
                    Text(correctAnswer)
                        .font(Constants.Fonts.callout.weight(.semibold))
                        .foregroundColor(Constants.Colors.primaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Constants.Colors.success.opacity(0.1))
                )
            }
        }
    }
}

// MARK: - Ordering Question View
struct OrderingQuestionView: View {
    let question: Question
    @State var orderedItems: [QuestionItem]
    let showExplanation: Bool
    let isCorrect: Bool
    let onItemsReordered: ([QuestionItem]) -> Void
    
    @State private var draggedItem: QuestionItem?
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(orderedItems) { item in
                OrderingItemView(
                    item: item,
                    index: orderedItems.firstIndex(where: { $0.id == item.id }) ?? 0,
                    isCorrect: showExplanation && isItemInCorrectPosition(item),
                    isDisabled: showExplanation,
                    draggedItem: $draggedItem
                )
                .onDrag {
                    draggedItem = item
                    return NSItemProvider(object: item.id as NSString)
                }
                .onDrop(of: [.text], delegate: OrderingDropDelegate(
                    item: item,
                    items: $orderedItems,
                    draggedItem: $draggedItem,
                    onReorder: { onItemsReordered($0) }
                ))
            }
        }
    }
    
    private func isItemInCorrectPosition(_ item: QuestionItem) -> Bool {
        guard let index = orderedItems.firstIndex(where: { $0.id == item.id }) else { return false }
        return item.order == index + 1
    }
}

// MARK: - Ordering Item View
struct OrderingItemView: View {
    let item: QuestionItem
    let index: Int
    let isCorrect: Bool
    let isDisabled: Bool
    @Binding var draggedItem: QuestionItem?
    
    private var isDragging: Bool {
        draggedItem?.id == item.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Order number
            Text("\(index + 1)")
                .font(Constants.Fonts.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(isCorrect ? Constants.Colors.success : Constants.Colors.primary)
                )
            
            // Item text
            Text(item.text)
                .font(Constants.Fonts.body)
                .foregroundColor(Constants.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Drag handle
            if !isDisabled {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18))
                    .foregroundColor(Constants.Colors.tertiaryText)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCorrect ? Constants.Colors.success : Color.clear, lineWidth: 2)
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .scaleEffect(isDragging ? 0.95 : 1.0)
    }
}

// MARK: - Ordering Drop Delegate
struct OrderingDropDelegate: DropDelegate {
    let item: QuestionItem
    @Binding var items: [QuestionItem]
    @Binding var draggedItem: QuestionItem?
    let onReorder: ([QuestionItem]) -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        onReorder(items)
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem else { return }
        
        if draggedItem.id != item.id {
            let from = items.firstIndex(where: { $0.id == draggedItem.id })!
            let to = items.firstIndex(where: { $0.id == item.id })!
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// MARK: - Matching Question View
struct MatchingQuestionView: View {
    let question: Question
    @State var matches: [String: String]
    let showExplanation: Bool
    let isCorrect: Bool
    let onMatchesChanged: ([String: String]) -> Void
    
    @State private var selectedLeft: String?
    
    var body: some View {
        HStack(spacing: 20) {
            // Left column
            VStack(spacing: 12) {
                ForEach(question.pairs ?? [], id: \.left) { pair in
                    MatchingItemView(
                        text: pair.left,
                        isSelected: selectedLeft == pair.left,
                        isMatched: matches[pair.left] != nil,
                        isCorrect: showExplanation && matches[pair.left] == pair.right,
                        onTap: {
                            if !showExplanation {
                                selectedLeft = pair.left
                                HapticManager.selection()
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            
            // Right column
            VStack(spacing: 12) {
                ForEach(shuffledRightItems(), id: \.self) { rightItem in
                    MatchingItemView(
                        text: rightItem,
                        isSelected: false,
                        isMatched: matches.values.contains(rightItem),
                        isCorrect: showExplanation && isRightItemCorrect(rightItem),
                        onTap: {
                            if !showExplanation, let left = selectedLeft {
                                matches[left] = rightItem
                                selectedLeft = nil
                                onMatchesChanged(matches)
                                HapticManager.selection()
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private func shuffledRightItems() -> [String] {
        return (question.pairs ?? []).map { $0.right }.shuffled()
    }
    
    private func isRightItemCorrect(_ rightItem: String) -> Bool {
        guard let pairs = question.pairs else { return false }
        
        for pair in pairs {
            if pair.right == rightItem && matches[pair.left] == rightItem {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Matching Item View
struct MatchingItemView: View {
    let text: String
    let isSelected: Bool
    let isMatched: Bool
    let isCorrect: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isCorrect {
            return Constants.Colors.success.opacity(0.1)
        } else if isSelected {
            return Constants.Colors.primary.opacity(0.1)
        } else if isMatched {
            return Constants.Colors.secondary.opacity(0.1)
        }
        
        return Color(UIColor.secondarySystemBackground)
    }
    
    private var borderColor: Color {
        if isCorrect {
            return Constants.Colors.success
        } else if isSelected {
            return Constants.Colors.primary
        } else if isMatched {
            return Constants.Colors.secondary
        }
        
        return Color.clear
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(Constants.Fonts.callout)
                .foregroundColor(Constants.Colors.primaryText)
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(backgroundColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}