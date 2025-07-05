import Foundation
import Combine

// MARK: - API Service
class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://www.askbibleverse.com/api/quiz"
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isLoading = false
    @Published var error: APIError?
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)
    }
    
    // MARK: - Error Types
    enum APIError: LocalizedError {
        case invalidURL
        case noData
        case decodingError(Error)
        case networkError(Error)
        case serverError(Int, String?)
        case unauthorized
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .noData:
                return "No data received"
            case .decodingError(let error):
                return "Decoding error: \(error.localizedDescription)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .serverError(let code, let message):
                return "Server error (\(code)): \(message ?? "Unknown error")"
            case .unauthorized:
                return "Unauthorized access"
            case .rateLimited:
                return "Rate limit exceeded"
            }
        }
    }
    
    // MARK: - Generic Request Method
    private func request<T: Decodable>(_ endpoint: String, 
                                       method: String = "GET",
                                       body: Data? = nil,
                                       headers: [String: String] = [:]) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if present
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    // Success
                    break
                case 401:
                    throw APIError.unauthorized
                case 429:
                    throw APIError.rateLimited
                default:
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw APIError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            
            // Decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
            
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Chapter/Lesson Methods
    func fetchChapters() async throws -> [ChapterData] {
        struct LevelsResponse: Decodable {
            let levels: [ChapterData]
        }
        
        let response: LevelsResponse = try await request("/levels")
        return response.levels
    }
    
    // MARK: - User Progress Methods
    func fetchUserProgress(userId: String) async throws -> [UserProgress] {
        struct ProgressResponse: Decodable {
            let progress: [UserProgress]
        }
        
        let response: ProgressResponse = try await request("/user-progress?userId=\(userId)")
        return response.progress
    }
    
    func saveUserProgress(_ progress: UserProgress) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(progress)
        
        let _: EmptyResponse = try await request("/user-progress", 
                                                 method: "POST", 
                                                 body: body)
    }
    
    // MARK: - Question Methods
    func fetchQuestions(lessonId: String) async throws -> [Question] {
        struct QuestionsResponse: Decodable {
            let questions: [Question]
        }
        
        let response: QuestionsResponse = try await request("/questions/\(lessonId)")
        return response.questions
    }
    
    // MARK: - User Stats Methods
    func fetchUserCrosses(userId: String) async throws -> Int {
        struct CrossesResponse: Decodable {
            let totalCrosses: Int
        }
        
        let response: CrossesResponse = try await request("/user-crosses?userId=\(userId)")
        return response.totalCrosses
    }
    
    func fetchUserCorrectCount(userId: String) async throws -> Int {
        struct CorrectCountResponse: Decodable {
            let totalCorrectCount: Int
        }
        
        let response: CorrectCountResponse = try await request("/user-correct-count?userId=\(userId)")
        return response.totalCorrectCount
    }
    
    // MARK: - Card Methods
    func fetchCard(cardId: String, userId: String? = nil) async throws -> Card {
        struct CardResponse: Decodable {
            let card: Card
        }
        
        var endpoint = "/cards?cardId=\(cardId)"
        if let userId = userId {
            endpoint += "&userId=\(userId)"
        }
        
        let response: CardResponse = try await request(endpoint)
        return response.card
    }
    
    func unlockCard(cardId: String, userId: String) async throws {
        struct UnlockRequest: Encodable {
            let cardId: String
            let userId: String
        }
        
        let unlockData = UnlockRequest(cardId: cardId, userId: userId)
        let body = try JSONEncoder().encode(unlockData)
        
        let _: EmptyResponse = try await request("/cards", 
                                                 method: "POST", 
                                                 body: body)
    }
    
    func fetchUserUnlockedCards(userId: String) async throws -> [UserUnlockedCard] {
        struct UnlockedCardsResponse: Decodable {
            let cards: [UserUnlockedCard]
        }
        
        let response: UnlockedCardsResponse = try await request("/user-unlocked-cards?userId=\(userId)")
        return response.cards
    }
    
    // MARK: - Error Tracking Methods
    func saveUserError(_ error: UserError) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(error)
        
        let _: EmptyResponse = try await request("/user-errors", 
                                                 method: "POST", 
                                                 body: body)
    }
    
    // MARK: - Streaming Quiz Methods
    func streamQuizData(lessonId: String) -> AsyncStream<QuizData?> {
        AsyncStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(baseURL)/streaming-quiz/\(lessonId)") else {
                        continuation.yield(nil)
                        continuation.finish()
                        return
                    }
                    
                    let (bytes, _) = try await session.bytes(for: URLRequest(url: url))
                    var buffer = ""
                    
                    for try await byte in bytes {
                        buffer.append(String(decoding: [byte], as: UTF8.self))
                        
                        // Try to parse when we have a complete line or chunk
                        if let parsedData = QuizStreamParser.shared.parseQuizStreamJson(buffer) {
                            continuation.yield(parsedData)
                            
                            // If we have all questions, finish the stream
                            if parsedData.isStreamingPartial == false {
                                continuation.finish()
                                break
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("Streaming error: \(error)")
                    continuation.yield(nil)
                    continuation.finish()
                }
            }
        }
    }
}

// MARK: - Empty Response for POST requests
private struct EmptyResponse: Decodable {}

// MARK: - Request Retry Logic
extension APIService {
    func withRetry<T>(_ operation: @escaping () async throws -> T, 
                      maxAttempts: Int = 3,
                      delay: TimeInterval = 1.0) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry for certain errors
                if let apiError = error as? APIError {
                    switch apiError {
                    case .unauthorized, .decodingError:
                        throw error
                    default:
                        break
                    }
                }
                
                // Wait before retrying (exponential backoff)
                if attempt < maxAttempts {
                    let backoffDelay = delay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError.networkError(NSError(domain: "APIService", code: -1))
    }
}