import Foundation

final class CoverFetcher {
    static let shared = CoverFetcher()
    private var cache: [String: URL] = [:]
    private let storageKey = "CoverFetcher.cache.v1"
    private let queue = DispatchQueue(label: "cover.fetcher")

    init() {
        // Load persisted cache (string URL map)
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            for (k, v) in dict {
                if let url = URL(string: v) {
                    cache[k] = url
                }
            }
        }
    }

    func key(for title: String, author: String) -> String {
        return "\(title.lowercased())::\(author.lowercased())"
    }

    func fetchCover(for title: String, author: String, completion: @escaping (URL?) -> Void) {
        let k = key(for: title, author: author)
        if let u = cache[k] {
            completion(u)
            return
        }

        // Use Google Books Volumes API to find a cover thumbnail
        let queryTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let queryAuthor = author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=intitle:\(queryTitle)+inauthor:\(queryAuthor)&maxResults=1"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]],
               let volumeInfo = items.first?["volumeInfo"] as? [String: Any],
               let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
               let thumb = imageLinks["thumbnail"] as? String {

                // Google Books often returns http; make https
                let httpsThumb = thumb.replacingOccurrences(of: "http://", with: "https://")
                if let finalURL = URL(string: httpsThumb) {
                    self.queue.async {
                        self.cache[k] = finalURL

                        // Persist cache as [key: urlString]
                        var toSave: [String: String] = [:]
                        for (key, url) in self.cache {
                            toSave[key] = url.absoluteString
                        }
                        if let data = try? JSONEncoder().encode(toSave) {
                            UserDefaults.standard.set(data, forKey: self.storageKey)
                        }
                    }
                    completion(finalURL)
                    return
                }
            }

            completion(nil)
        }
        task.resume()
    }

    /// Attempt to fetch a cover quickly with a short timeout; calls completion(nil) on timeout or failure.
    func fetchCoverQuick(for title: String, author: String, timeout: TimeInterval = 0.6, completion: @escaping (URL?) -> Void) {
        let k = key(for: title, author: author)
        if let u = cache[k] {
            completion(u)
            return
        }

        let queryTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let queryAuthor = author.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://www.googleapis.com/books/v1/volumes?q=intitle:\(queryTitle)+inauthor:\(queryAuthor)&maxResults=1"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(configuration: config)

        let task = session.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]],
               let volumeInfo = items.first?["volumeInfo"] as? [String: Any],
               let imageLinks = volumeInfo["imageLinks"] as? [String: Any],
               let thumb = imageLinks["thumbnail"] as? String {

                let httpsThumb = thumb.replacingOccurrences(of: "http://", with: "https://")
                if let finalURL = URL(string: httpsThumb) {
                    self.queue.async {
                        self.cache[k] = finalURL
                        // persist as before
                        var toSave: [String: String] = [:]
                        for (key, url) in self.cache {
                            toSave[key] = url.absoluteString
                        }
                        if let data = try? JSONEncoder().encode(toSave) {
                            UserDefaults.standard.set(data, forKey: self.storageKey)
                        }
                    }
                    completion(finalURL)
                    return
                }
            }

            completion(nil)
        }
        task.resume()
    }
}
