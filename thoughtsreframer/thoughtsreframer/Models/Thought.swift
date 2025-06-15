import Foundation

public struct Thought: Identifiable, Codable {
    public let id: UUID
    public var content: String
    public var reframedContent: String?
    public var emotion: String
    public var category: String
    public var moodRating: Int
    public let createdAt: Date
    public var updatedAt: Date
    public var isFavorite: Bool
    
    public init(content: String, emotion: String = "중립", category: String = "일반", moodRating: Int = 3) {
        self.id = UUID()
        self.content = content
        self.reframedContent = nil
        self.emotion = emotion
        self.category = category
        self.moodRating = moodRating
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFavorite = false
    }
}

public struct MoodEntry: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let rating: Int
    public let emotions: [String]
    public let note: String?
    
    public init(rating: Int, emotions: [String], note: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.rating = rating
        self.emotions = emotions
        self.note = note
    }
} 