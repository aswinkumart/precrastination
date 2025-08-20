import Foundation

struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: URL?
    let summary: String
    let audioURL: URL?
}
