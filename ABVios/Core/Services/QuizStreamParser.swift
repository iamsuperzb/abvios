import Foundation

// MARK: - Quiz Stream Parser
class QuizStreamParser {
    static let shared = QuizStreamParser()
    
    private init() {}
    
    /// Parse streaming Quiz JSON, handling incomplete JSON fragments
    func parseQuizStreamJson(_ text: String) -> QuizData? {
        // Safety check
        guard !text.isEmpty else {
            print("[QuizStreamParser] Input is empty")
            return nil
        }
        
        print("=== QuizStreamParser Debug ===")
        print("Input text length: \(text.count)")
        
        // Check for key fields
        let hasTitle = text.contains("\"title\"")
        let hasQuestions = text.contains("\"questions\"")
        print("Contains title field: \(hasTitle)")
        print("Contains questions field: \(hasQuestions)")
        
        // Clean text
        let cleanedText = cleanText(text)
        
        // First try complete JSON parsing
        if let completeData = tryParseCompleteJson(cleanedText) {
            return completeData
        }
        
        // If complete parsing fails, try to repair
        if let repairedData = tryRepairQuizJson(cleanedText) {
            return repairedData
        }
        
        // Finally try to extract first complete question
        if checkForFirstCompleteQuestion(cleanedText) {
            print("🎯 Detected first complete question, returning partial data")
            return extractPartialQuizDataWithFirstQuestion(cleanedText)
        }
        
        return nil
    }
    
    private func cleanText(_ text: String) -> String {
        // Remove control characters
        let controlCharacterSet = CharacterSet(charactersIn: "\u{0000}"..."\u{001F}")
            .union(CharacterSet(charactersIn: "\u{007F}"..."\u{009F}"))
        
        return text
            .components(separatedBy: controlCharacterSet)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func tryParseCompleteJson(_ text: String) -> QuizData? {
        do {
            let data = text.data(using: .utf8)!
            let decoder = JSONDecoder()
            return try decoder.decode(QuizData.self, from: data)
        } catch {
            print("Complete JSON parsing failed: \(error)")
            return nil
        }
    }
    
    private func tryRepairQuizJson(_ text: String) -> QuizData? {
        var repairedText = text
        
        // Fix unterminated strings
        repairedText = fixUnterminatedStrings(repairedText)
        
        // Balance braces
        repairedText = balanceBraces(repairedText)
        
        return tryParseCompleteJson(repairedText)
    }
    
    private func fixUnterminatedStrings(_ text: String) -> String {
        let quoteCount = text.filter { $0 == "\"" }.count
        if quoteCount % 2 != 0 {
            return text + "\""
        }
        return text
    }
    
    private func balanceBraces(_ text: String) -> String {
        var fixed = text
        
        // Count braces
        let openBraces = fixed.filter { $0 == "{" }.count
        let closeBraces = fixed.filter { $0 == "}" }.count
        
        // Add missing closing braces
        for _ in 0..<(openBraces - closeBraces) {
            fixed += "}"
        }
        
        // Count brackets
        let openBrackets = fixed.filter { $0 == "[" }.count
        let closeBrackets = fixed.filter { $0 == "]" }.count
        
        // Add missing closing brackets
        for _ in 0..<(openBrackets - closeBrackets) {
            fixed += "]"
        }
        
        return fixed
    }
    
    private func checkForFirstCompleteQuestion(_ text: String) -> Bool {
        // Check for complete first question
        let hasQuestionText = text.range(of: #""question"\s*:\s*"[^"]+"#, 
                                        options: .regularExpression) != nil
        let hasOptionsStart = text.range(of: #""options"\s*:\s*\["#, 
                                       options: .regularExpression) != nil
        let hasAtLeastOneOption = text.range(of: #""text"\s*:\s*"[^"]+"\s*,\s*"is_correct"\s*:\s*(true|false|"true"|"false")"#, 
                                           options: .regularExpression) != nil
        
        return hasQuestionText && hasOptionsStart && hasAtLeastOneOption
    }
    
    private func extractPartialQuizDataWithFirstQuestion(_ text: String) -> QuizData? {
        // Extract title
        var title = "Quiz"
        if let titleMatch = text.range(of: #""title"\s*:\s*"([^"]+)"#, 
                                      options: .regularExpression) {
            let titleText = String(text[titleMatch])
            if let startQuote = titleText.lastIndex(of: "\"") {
                let startIndex = titleText.index(after: startQuote)
                if startIndex < titleText.endIndex {
                    let endIndex = titleText.index(before: titleText.endIndex)
                    if startIndex < endIndex {
                        title = String(titleText[startIndex..<endIndex])
                    }
                }
            }
        }
        
        // Extract first question
        guard let firstQuestion = extractFirstCompleteQuestion(text) else {
            return nil
        }
        
        return QuizData(
            title: title,
            examiner: nil,
            level: nil,
            description: nil,
            questions: [firstQuestion],
            resultAnalysis: nil,
            isStreamingPartial: true
        )
    }
    
    private func extractFirstCompleteQuestion(_ text: String) -> Question? {
        // Extract question text
        guard let questionMatch = text.range(of: #""question"\s*:\s*"([^"]+)"#, 
                                           options: .regularExpression) else {
            return nil
        }
        
        let questionText = String(text[questionMatch])
        guard let questionStart = questionText.firstIndex(of: "\""),
              let questionEnd = questionText.lastIndex(of: "\""),
              questionStart != questionEnd else {
            return nil
        }
        
        let startIndex = questionText.index(after: questionStart)
        let question = String(questionText[startIndex..<questionEnd])
        
        // Extract hint (optional)
        var hint: String?
        if let hintMatch = text.range(of: #""hint"\s*:\s*"([^"]*)"#, 
                                    options: .regularExpression) {
            let hintText = String(text[hintMatch])
            if let hintStart = hintText.firstIndex(of: "\""),
               let hintEnd = hintText.lastIndex(of: "\""),
               hintStart != hintEnd {
                let startIndex = hintText.index(after: hintStart)
                hint = String(hintText[startIndex..<hintEnd])
            }
        }
        
        // Extract options
        guard let options = extractOptionsFromText(text) else {
            return nil
        }
        
        // Determine question type based on options
        let questionType: QuestionType = .multipleChoice
        
        return Question(
            id: UUID().uuidString,
            type: questionType,
            question: question,
            hint: hint,
            options: options,
            items: [],
            pairs: [],
            correctAnswer: "",
            explanation: "",
            cardTrigger: "",
            examinerId: ""
        )
    }
    
    private func extractOptionsFromText(_ text: String) -> [Option]? {
        var options: [Option] = []
        
        let pattern = #"\{\s*"text"\s*:\s*"([^"]+)"\s*,\s*"is_correct"\s*:\s*(true|false|"true"|"false")\s*(?:,\s*"explanation"\s*:\s*"([^"]*)")?\s*\}"#
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let textRange = Range(match.range(at: 1), in: text),
                   let isCorrectRange = Range(match.range(at: 2), in: text) {
                    let optionText = String(text[textRange])
                    let isCorrectStr = String(text[isCorrectRange])
                    let isCorrect = isCorrectStr == "true" || isCorrectStr == "\"true\""
                    
                    var explanation: String?
                    if match.numberOfRanges > 3,
                       let explanationRange = Range(match.range(at: 3), in: text) {
                        explanation = String(text[explanationRange])
                    }
                    
                    options.append(Option(
                        id: UUID().uuidString,
                        text: optionText,
                        isCorrect: isCorrect,
                        explanation: explanation ?? ""
                    ))
                }
            }
        } catch {
            print("Regex error: \(error)")
            return nil
        }
        
        return options.isEmpty ? nil : options
    }
}