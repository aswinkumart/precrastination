import Foundation
import Alamofire

enum LLMProvider {
    case openAI, llama, anthropic, gpt5
}

class LLMService {
    static let shared = LLMService()
    
    func fetchSummary(for book: String, author: String, completion: @escaping (String?) -> Void) {
        let group = DispatchGroup()
        var summaries: [String] = []

        // OpenAI GPT-5
        group.enter()
        fetchFromGPT5(book: book, author: author) { summary in
            if let summary = summary { summaries.append(summary) }
            group.leave()
        }

        // Anthropic Claude
        group.enter()
        fetchFromAnthropic(book: book, author: author) { summary in
            if let summary = summary { summaries.append(summary) }
            group.leave()
        }

        // OpenAI GPT-4 (optional, can remove if only want GPT-5)
        group.enter()
        fetchFromOpenAI(book: book, author: author) { summary in
            if let summary = summary { summaries.append(summary) }
            group.leave()
        }

        // Llama (Meta)
        group.enter()
        fetchFromLlama(book: book, author: author) { summary in
            if let summary = summary { summaries.append(summary) }
            group.leave()
        }

        group.notify(queue: .main) {
            // Consolidate summaries (simple join, you can use LLM to merge)
            let consolidated = summaries.joined(separator: "\n\n")
            completion(consolidated)
        }
    }
    
    private func fetchFromOpenAI(book: String, author: String, completion: @escaping (String?) -> Void) {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let url = "https://api.openai.com/v1/chat/completions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        let prompt = "Summarize the book '\(book)' by \(author) in less than 5 minutes of spoken audio."
        let params: [String: Any] = [
            "model": "gpt-4",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 1024
        ]
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: [String: Any].self) { response in
                if let dict = response.value,
                   let choices = dict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            }
    }

    private func fetchFromGPT5(book: String, author: String, completion: @escaping (String?) -> Void) {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let url = "https://api.openai.com/v1/chat/completions"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
        let prompt = "Summarize the book '\(book)' by \(author) in less than 5 minutes of spoken audio."
        let params: [String: Any] = [
            "model": "gpt-5",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 2048
        ]
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: [String: Any].self) { response in
                if let dict = response.value,
                   let choices = dict["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            }
    }

    private func fetchFromAnthropic(book: String, author: String, completion: @escaping (String?) -> Void) {
        let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] ?? ""
        let url = "https://api.anthropic.com/v1/messages"
        let headers: HTTPHeaders = [
            "x-api-key": apiKey,
            "Content-Type": "application/json"
        ]
        let prompt = "Summarize the book '\(book)' by \(author) in less than 5 minutes of spoken audio."
        let params: [String: Any] = [
            "model": "claude-3-opus-20240229", // or latest
            "max_tokens": 2048,
            "messages": [["role": "user", "content": prompt]]
        ]
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: [String: Any].self) { response in
                if let dict = response.value,
                   let content = (dict["content"] as? [[String: Any]])?.first?["text"] as? String {
                    completion(content)
                } else {
                    completion(nil)
                }
            }
    }
    
    private func fetchFromLlama(book: String, author: String, completion: @escaping (String?) -> Void) {
        // Replace with your Llama API endpoint and key
        completion(nil) // Placeholder
    }
}
