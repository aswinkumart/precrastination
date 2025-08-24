import Foundation
import Alamofire

// MARK: - Response Structures

struct AnthropicResponse: Decodable {
    let id: String
    let type: String
    let role: String
    let content: [ContentBlock]
    let model: String
    let stopReason: String?
    let stopSequence: String?
    let usage: Usage?
    
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
    
    struct Usage: Decodable {
        let inputTokens: Int?
        let outputTokens: Int?
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, role, content, model
        case stopReason = "stop_reason"
        case stopSequence = "stop_sequence"
        case usage
    }
}

struct AnthropicError: Decodable {
    let error: ErrorDetail
    
    struct ErrorDetail: Decodable {
        let type: String
        let message: String
    }
}

class LLMService {
    static let shared = LLMService()
    private let session: Session
    private let retrier = ConnectionRetrier()
    private let eventMonitor = NetworkEventMonitor()
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        self.session = Session(
            configuration: configuration,
            interceptor: retrier,
            eventMonitors: [eventMonitor]
        )
    }
    
    func fetchSummary(for book: String = "Atomic Habits", author: String = "James Clear", completion: @escaping (String?) -> Void) {
        fetchFromAnthropic(book: book, author: author) { summary in
            completion(summary ?? "Failed to generate summary. Please check your internet connection and API key.")
        }
    }

    private func fetchFromAnthropic(book: String, author: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] else {
            print("⚠️ Anthropic API key not found in environment variables")
            print("ℹ️ Set ANTHROPIC_API_KEY in your Xcode scheme's environment variables")
            completion("Configuration Error: API key not found. Please set ANTHROPIC_API_KEY in Xcode scheme.")
            return
        }
        
        // Debug logging
        print("🔑 API Key Debug:")
        print("  Length: \(apiKey.count) characters")
        
        // Validate API key
        guard !apiKey.isEmpty else {
            print("⚠️ Anthropic API key not found")
            completion("Configuration Error: API key not found. Please get a key from console.anthropic.com")
            return
        }
        
        print("✅ API Key validation passed")
        let url = "https://api.anthropic.com/v1/messages"
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json"
        ]
        let prompt = "Summarize the book '\(book)' by \(author) in approximately 10.1 minutes of spoken audio."
        let params: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            // Increased token budget to support a longer (~10.1 minute) spoken summary
            "max_tokens": 1800,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]
        
        // Debug: Print request details
        print("📡 Request Debug:")
        print("  URL: \(url)")
        print("  Headers:")
        print("    x-api-key: [HIDDEN]")
        print("    anthropic-version: \(headers["anthropic-version"] ?? "none")")
        print("    Content-Type: \(headers["Content-Type"] ?? "none")")
        print("  Parameters:")
        print("    Model: \(params["model"] as? String ?? "none")")
        print("    Max Tokens: \(params["max_tokens"] as? Int ?? 0)")
        
        session.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: AnthropicResponse.self) { response in
                switch response.result {
                case .success(let anthropicResponse):
                    let summary = anthropicResponse.content.first?.text
                    completion(summary)
                case .failure(let error):
                    print("❌ Anthropic API Error: \(error.localizedDescription)")
                    
                    // Parse and handle specific API errors
                    if let data = response.data,
                       let apiError = try? JSONDecoder().decode(AnthropicError.self, from: data) {
                        
                        let errorMessage: String
                        switch (response.response?.statusCode, apiError.error.type) {
                        case (429, _):
                            errorMessage = "Rate limit exceeded. Please try again in a few moments."
                        case (401, _):
                            errorMessage = "Authentication failed. Please verify your API key."
                        case (400, _):
                            errorMessage = "Invalid request: \(apiError.error.message)"
                        default:
                            errorMessage = "An error occurred: \(apiError.error.message)"
                        }
                        
                        print("📝 Detailed error: \(apiError.error.message)")
                        completion(errorMessage)
                    } else {
                        // Network or other non-API errors
                        completion("Network error: \(error.localizedDescription)")
                    }
                }
            }
    }
}

// MARK: - Network Support

class ConnectionRetrier: RequestInterceptor {
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        let statusCode = (request.response?.statusCode ?? 0)
        
        // Retry on network errors, rate limits (429), or 5xx server errors
        if let error = error.asAFError,
           error.isSessionTaskError || statusCode == 429 || (500...599).contains(statusCode) {
            
            let retryCount = request.retryCount
            if retryCount < 3 { // Maximum 3 retries
                // Exponential backoff: 2s, 4s, 8s for rate limits, 1s, 2s, 4s for other errors
                let baseDelay = statusCode == 429 ? 2.0 : 1.0
                let delay = pow(2.0, Double(retryCount)) * baseDelay
                completion(.retryWithDelay(delay))
                return
            }
        }
        
        completion(.doNotRetry)
    }
}

class NetworkEventMonitor: EventMonitor {
    func request(_ request: Request, didCreateURLRequest urlRequest: URLRequest) {
        print("📡 Starting Request: \(urlRequest.url?.absoluteString ?? "unknown")")
    }
    
    func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: Error?) {
        if let error = error {
            print("❌ Request failed: \(error.localizedDescription)")
        } else {
            print("✅ Request completed: \(request.description)")
        }
    }
}
