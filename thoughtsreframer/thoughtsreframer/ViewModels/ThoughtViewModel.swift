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
        
        let contextualTemplates = [
            // 감정 기반 템플릿
            "불안": [
                "이 불안한 감정을 이해합니다. 하지만 잠시 멈추어 생각해보면, 이 상황이 정말 우리가 생각하는 것만큼 위험할까요? 과거에도 비슷한 걱정을 했지만 실제로는 잘 해결된 경험이 있지 않나요?",
                "불안은 미래에 대한 불확실성에서 오는 자연스러운 반응입니다. 하지만 이 순간에 집중하고, 할 수 있는 작은 행동부터 시작해보는 건 어떨까요?",
                "이 불안한 감정을 인정하고, 그것이 우리에게 전하는 메시지를 들어보세요. 아마도 더 나은 준비를 하라는 신호일 수도 있습니다."
            ],
            
            "우울": [
                "이 무거운 감정을 이해합니다. 하지만 이 감정이 영원하지 않다는 것을 기억해주세요. 작은 변화부터 시작해보는 건 어떨까요?",
                "우울한 감정은 우리에게 휴식과 성찰의 시간을 주는 신호일 수 있습니다. 이 시간을 자신을 돌보는 기회로 삼아보세요.",
                "이 순간의 어려움을 인정하면서도, 과거에 극복했던 경험들을 떠올려보세요. 당신은 이미 여러 번의 어려움을 이겨낸 강한 사람입니다."
            ],
            
            "분노": [
                "이 분노의 감정을 이해합니다. 하지만 잠시 멈추어 생각해보면, 이 감정이 우리에게 전하는 진짜 메시지는 무엇일까요?",
                "분노는 종종 우리가 소중히 여기는 것이 위협받을 때 나타납니다. 이 상황에서 우리가 진정으로 지키고 싶은 것은 무엇인가요?",
                "이 감정을 인정하면서도, 더 건설적인 방향으로 에너지를 전환해보는 건 어떨까요?"
            ],
            
            // 카테고리 기반 템플릿
            "일": [
                "직장에서의 어려움은 성장의 기회가 될 수 있습니다. 이 상황에서 배울 수 있는 점은 무엇일까요?",
                "업무상의 도전은 우리의 역량을 키우는 좋은 기회입니다. 이 경험을 통해 어떤 부분을 발전시킬 수 있을까요?",
                "일과 삶의 균형을 생각해볼 때, 이 상황이 우리에게 전하는 메시지는 무엇일까요?"
            ],
            
            "관계": [
                "인간관계의 어려움은 서로를 이해하는 기회가 될 수 있습니다. 이 상황에서 배울 수 있는 점은 무엇일까요?",
                "관계에서의 갈등은 서로의 경계를 설정하고 존중하는 법을 배우는 과정일 수 있습니다.",
                "이 관계에서 우리가 진정으로 원하는 것은 무엇인가요? 그것을 얻기 위해 할 수 있는 건설적인 방법은 무엇일까요?"
            ],
            
            "건강": [
                "건강에 대한 걱정은 우리가 자신을 더 잘 돌보라는 신호일 수 있습니다. 이 상황에서 할 수 있는 작은 변화는 무엇일까요?",
                "건강한 삶을 위한 여정은 작은 선택들의 연속입니다. 오늘 할 수 있는 작은 건강한 선택은 무엇일까요?",
                "이 걱정이 우리에게 전하는 긍정적인 메시지는 무엇일까요? 아마도 더 나은 건강 습관을 형성하는 기회일 수도 있습니다."
            ]
        ]
        
        // 감정과 카테고리에 따른 템플릿 선택
        var selectedTemplates: [String] = []
        
        if let emotionTemplates = contextualTemplates[thought.emotion] {
            selectedTemplates.append(contentsOf: emotionTemplates)
        }
        
        if let categoryTemplates = contextualTemplates[thought.category] {
            selectedTemplates.append(contentsOf: categoryTemplates)
        }
        
        // 기본 템플릿 추가
        let defaultTemplates = [
            "이 상황을 다른 관점에서 보면: \(thought.content)에서 배울 수 있는 점이 있을까요?",
            "더 균형잡힌 시각으로 보면: \(thought.content)이 완전히 사실일까요? 다른 가능성은 없을까요?",
            "긍정적 재구성: \(thought.content) 상황에서도 감사할 수 있는 부분이 있다면 무엇일까요?",
            "해결 중심 사고: \(thought.content) 문제를 해결하기 위해 할 수 있는 작은 행동은 무엇일까요?",
            "현실적 평가: \(thought.content) 이 생각이 도움이 되는지 생각해보세요. 더 건설적인 방향은 무엇일까요?"
        ]
        
        selectedTemplates.append(contentsOf: defaultTemplates)
        
        // 랜덤하게 템플릿 선택
        let selectedTemplate = selectedTemplates.randomElement() ?? "이 생각을 더 건설적인 방향으로 바라볼 수 있습니다."
        
        // 이모지 추가
        let emoticons = ["💙", "🌱", "✨", "🌈", "💝", "🤗"]
        let selectedEmoji = emoticons.randomElement() ?? "💙"
        
        return "\(selectedEmoji) \(selectedTemplate)"
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