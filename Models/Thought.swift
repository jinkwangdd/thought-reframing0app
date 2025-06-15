import Foundation

struct Thought: Identifiable, Codable {
    let id: UUID
    var content: String
    var emotion: Emotion
    var category: Category
    var tags: [String]
    var createdAt: Date
    var reframedContent: String?
    
    init(id: UUID = UUID(), content: String, emotion: Emotion, category: Category, tags: [String] = [], reframedContent: String? = nil) {
        self.id = id
        self.content = content
        self.emotion = emotion
        self.category = category
        self.tags = tags
        self.createdAt = Date()
        self.reframedContent = reframedContent
    }
}

enum Emotion: String, Codable, CaseIterable {
    case happy = "행복"
    case sad = "슬픔"
    case angry = "화남"
    case anxious = "불안"
    case neutral = "보통"
}

enum Category: String, Codable, CaseIterable {
    case work = "일"
    case personal = "개인"
    case relationship = "관계"
    case health = "건강"
    case other = "기타"
} 