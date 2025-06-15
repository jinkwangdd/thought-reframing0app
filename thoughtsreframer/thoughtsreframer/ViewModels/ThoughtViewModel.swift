import Foundation
import SwiftUI

public class ThoughtViewModel: ObservableObject {
    @Published public var thoughts: [Thought] = []
    @Published public var moodEntries: [MoodEntry] = []
    @Published public var isLoading = false
    @Published public var error: String?
    @Published public var currentStreak = 0
    @Published public var language = "ko"
    
    public let emotions = ["기쁨", "슬픔", "분노", "불안", "두려움", "놀람", "혐오", "중립"]
    public let categories = ["일반", "업무", "관계", "건강", "가족", "학업", "미래", "과거"]
    
    public init() {
        loadThoughts()
        loadMoodEntries()
        calculateStreak()
    }
    
    public func loadThoughts() {
        if let data = UserDefaults.standard.data(forKey: "thoughts"),
           let decodedThoughts = try? JSONDecoder().decode([Thought].self, from: data) {
            thoughts = decodedThoughts.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    public func saveThoughts() {
        if let encoded = try? JSONEncoder().encode(thoughts) {
            UserDefaults.standard.set(encoded, forKey: "thoughts")
        }
    }
    
    public func loadMoodEntries() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decodedEntries = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decodedEntries.sorted(by: { $0.date > $1.date })
        }
    }
    
    public func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
    
    public func addThought(_ content: String, emotion: String = "중립", category: String = "일반", moodRating: Int = 3) {
        let thought = Thought(content: content, emotion: emotion, category: category, moodRating: moodRating)
        thoughts.insert(thought, at: 0)
        saveThoughts()
    }
    
    public func addMoodEntry(_ rating: Int, emotions: [String], note: String?) {
        let entry = MoodEntry(rating: rating, emotions: emotions, note: note)
        moodEntries.insert(entry, at: 0)
        saveMoodEntries()
        calculateStreak()
    }
    
    public func updateThought(_ thought: Thought, reframedContent: String) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index].reframedContent = reframedContent
            thoughts[index].updatedAt = Date()
            saveThoughts()
        }
    }
    
    public func toggleFavorite(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index].isFavorite.toggle()
            saveThoughts()
        }
    }
    
    public func deleteThought(_ thought: Thought) {
        thoughts.removeAll { $0.id == thought.id }
        saveThoughts()
    }
    
    public func reframeThought(_ thought: Thought) async throws -> String {
        // 실제 AI 리프레이밍 로직 (현재는 시뮬레이션)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        let reframingTemplates = [
            "이 상황을 다른 관점에서 보면: \(thought.content)에서 배울 수 있는 점이 있을까요?",
            "더 균형잡힌 시각으로 보면: \(thought.content)이 완전히 사실일까요? 다른 가능성은 없을까요?",
            "긍정적 재구성: \(thought.content) 상황에서도 감사할 수 있는 부분이 있다면 무엇일까요?",
            "해결 중심 사고: \(thought.content) 문제를 해결하기 위해 할 수 있는 작은 행동은 무엇일까요?",
            "현실적 평가: \(thought.content) 이 생각이 도움이 되는지 생각해보세요. 더 건설적인 방향은 무엇일까요?"
        ]
        
        return reframingTemplates.randomElement() ?? "이 생각을 더 건설적인 방향으로 바라볼 수 있습니다."
    }
    
    public func calculateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
            let hasEntryForDate = moodEntries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: currentDate)
            }
            
            if hasEntryForDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        currentStreak = streak
    }
    
    public func getReframingRate() -> Double {
        let reframedCount = thoughts.filter { $0.reframedContent != nil }.count
        return thoughts.isEmpty ? 0 : Double(reframedCount) / Double(thoughts.count)
    }
    
    public func getMostCommonEmotion() -> String {
        let emotionCounts = Dictionary(grouping: thoughts, by: { $0.emotion })
            .mapValues { $0.count }
        return emotionCounts.max(by: { $0.value < $1.value })?.key ?? "중립"
    }
    
    public func getAverageMood() -> Double {
        guard !moodEntries.isEmpty else { return 0 }
        let total = moodEntries.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(moodEntries.count)
    }
    
    public func getEmotionCounts() -> [String: Int] {
        Dictionary(grouping: thoughts, by: { $0.emotion })
            .mapValues { $0.count }
    }
    
    public func getCategoryCounts() -> [String: Int] {
        Dictionary(grouping: thoughts, by: { $0.category })
            .mapValues { $0.count }
    }
} 