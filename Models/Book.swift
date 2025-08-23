import Foundation

struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverURL: URL?
    let description: String

    // Top 10 personality development / self-improvement books (placeholder covers via picsum)
    static let featured: [Book] = [
     Book(title: "Atomic Habits",
          author: "James Clear",
          coverURL: nil,
             description: "Tiny changes, remarkable results."),

     Book(title: "Think and Grow Rich",
          author: "Napoleon Hill",
          coverURL: nil,
             description: "Classic guide to success."),

     Book(title: "The Psychology of Money",
          author: "Morgan Housel",
          coverURL: nil,
             description: "Timeless lessons on wealth and happiness."),

     Book(title: "Rich Dad Poor Dad",
          author: "Robert Kiyosaki",
          coverURL: nil,
             description: "What the rich teach their kids about money."),

     Book(title: "The 7 Habits of Highly Effective People",
          author: "Stephen Covey",
          coverURL: nil,
             description: "Powerful lessons in personal change."),

     Book(title: "Deep Work",
          author: "Cal Newport",
          coverURL: nil,
             description: "Rules for focused success in a distracted world."),

     Book(title: "The Alchemist",
          author: "Paulo Coelho",
          coverURL: nil,
             description: "A fable about following your dream."),

     Book(title: "Start with Why",
          author: "Simon Sinek",
          coverURL: nil,
             description: "How great leaders inspire action."),

     Book(title: "Good to Great",
          author: "Jim Collins",
          coverURL: nil,
             description: "Why some companies make the leap."),

     Book(title: "The Power of Now",
          author: "Eckhart Tolle",
          coverURL: nil,
             description: "A guide to spiritual enlightenment.")
    ]
}
