//
//  ContentView.swift
//  thoughtsreframer
//
//  Created by Solum on 2025/06/13.
//

import SwiftUI

// MARK: - Models
struct Thought: Identifiable, Codable {
    let id: UUID
    var content: String
    var reframedContent: String?
    var emotion: String
    var category: String
    var moodRating: Int
    let createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    
    init(content: String, emotion: String = "중립", category: String = "일반", moodRating: Int = 3) {
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

struct MoodEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let rating: Int
    let emotions: [String]
    let note: String?
    
    init(rating: Int, emotions: [String], note: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.rating = rating
        self.emotions = emotions
        self.note = note
    }
}

// MARK: - View Models
class ThoughtViewModel: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var moodEntries: [MoodEntry] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentStreak = 0
    @Published var language = "ko"
    
    let emotions = ["기쁨", "슬픔", "분노", "불안", "두려움", "놀람", "혐오", "중립"]
    let categories = ["일반", "업무", "관계", "건강", "가족", "학업", "미래", "과거"]
    
    init() {
        loadThoughts()
        loadMoodEntries()
        calculateStreak()
    }
    
    func loadThoughts() {
        if let data = UserDefaults.standard.data(forKey: "thoughts"),
           let decodedThoughts = try? JSONDecoder().decode([Thought].self, from: data) {
            thoughts = decodedThoughts.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }
    
    func saveThoughts() {
        if let encoded = try? JSONEncoder().encode(thoughts) {
            UserDefaults.standard.set(encoded, forKey: "thoughts")
        }
    }
    
    func loadMoodEntries() {
        if let data = UserDefaults.standard.data(forKey: "moodEntries"),
           let decodedEntries = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decodedEntries.sorted(by: { $0.date > $1.date })
        }
    }
    
    func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encoded, forKey: "moodEntries")
        }
    }
    
    func addThought(_ content: String, emotion: String, category: String, moodRating: Int) {
        let thought = Thought(content: content, emotion: emotion, category: category, moodRating: moodRating)
        thoughts.insert(thought, at: 0)
        saveThoughts()
    }
    
    func addMoodEntry(_ rating: Int, emotions: [String], note: String?) {
        let entry = MoodEntry(rating: rating, emotions: emotions, note: note)
        moodEntries.insert(entry, at: 0)
        saveMoodEntries()
        calculateStreak()
    }
    
    func updateThought(_ thought: Thought, reframedContent: String) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index].reframedContent = reframedContent
            thoughts[index].updatedAt = Date()
            saveThoughts()
        }
    }
    
    func toggleFavorite(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index].isFavorite.toggle()
            saveThoughts()
        }
    }
    
    func deleteThought(_ thought: Thought) {
        thoughts.removeAll { $0.id == thought.id }
        saveThoughts()
    }
    
    func reframeThought(_ thought: Thought) async throws -> String {
        // 허깅페이스 무료 AI 추론 API 사용
        let url = URL(string: "https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 상황별 맞춤 프롬프트 생성
        let contextualPrompt = generateContextualPrompt(for: thought.content)
        
        let payload: [String: Any] = [
            "inputs": contextualPrompt,
            "parameters": [
                "max_length": 150,
                "temperature": 0.7,
                "do_sample": true,
                "top_p": 0.9
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("Hugging Face API 응답 코드: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 503 {
                    // 모델 로딩 중이거나 과부하 상태
                    print("허깅페이스 모델 로딩 중... 로컬 응답 사용")
                    return generateLocalReframing(for: thought.content)
                }
                
                if httpResponse.statusCode != 200 {
                    throw NSError(domain: "HuggingFaceAPI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API 요청 실패"])
                }
            }
            
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
               let firstResponse = jsonResponse.first,
               let generatedText = firstResponse["generated_text"] as? String {
                
                // AI 응답을 한국어 CBT 스타일로 후처리
                return processAIResponse(generatedText, originalThought: thought.content)
            }
            
        } catch {
            print("허깅페이스 API 에러: \(error)")
            // 네트워크 에러시 로컬 응답 사용
            return generateLocalReframing(for: thought.content)
        }
        
        // 기본 로컬 응답
        return generateLocalReframing(for: thought.content)
    }
    
    private func generateContextualPrompt(for thoughtContent: String) -> String {
        let basePrompt = """
        당신은 따뜻하고 전문적인 심리 상담사입니다. 
        부정적인 생각을 긍정적이고 건설적으로 재구성해주세요.
        
        사용자의 생각: "\(thoughtContent)"
        
        다음 원칙을 따라 응답해주세요:
        1. 공감하고 이해하는 톤으로 시작
        2. 인지적 재구성 기법 사용
        3. 구체적이고 실행 가능한 조언 제공
        4. 희망적이고 격려하는 메시지로 마무리
        5. 150자 이내로 간결하게
        
        리프레이밍된 생각:
        """
        
        return basePrompt
    }
    
    private func processAIResponse(_ aiResponse: String, originalThought: String) -> String {
        // AI 응답을 CBT 스타일로 후처리
        let cleanedResponse = aiResponse
            .replacingOccurrences(of: originalThought, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedResponse.isEmpty || cleanedResponse.count < 20 {
            return generateLocalReframing(for: originalThought)
        }
        
        // 이모지와 따뜻한 톤 추가
        let emoticons = ["💙", "🌱", "✨", "🌈", "💝", "🤗"]
        let selectedEmoji = emoticons.randomElement() ?? "💙"
        
        return "\(selectedEmoji) \(cleanedResponse)"
    }
    
    private func generateLocalReframing(for thoughtContent: String) -> String {
        // 상황별 맞춤 로컬 리프레이밍
        let lowerThought = thoughtContent.lowercased()
        
        // 관계/연애 문제
        if lowerThought.contains("여자친구") || lowerThought.contains("남자친구") || 
           lowerThought.contains("연애") || lowerThought.contains("헤어") || 
           lowerThought.contains("롱디") || lowerThought.contains("멀리") {
            let relationshipFrames = [
                "💙 사랑하는 사람과 떨어져 있는 것은 힘들지만, 이 시간이 서로에 대한 소중함을 더 깨닫게 해줄 거예요. 거리는 멀어도 마음은 가까이 있어요.",
                "🌈 롱디스턴스는 도전이지만 불가능하지 않아요. 이 경험을 통해 더 깊은 신뢰와 소통 능력을 기를 수 있을 거예요.",
                "✨ 지금은 서로를 그리워하는 마음이 크지만, 이 시간을 자신을 성장시키는 기회로 활용해보면 어떨까요? 더 나은 사람이 되어 다시 만날 수 있어요."
            ]
            return relationshipFrames.randomElement()!
        }
        
        // 취업/면접 실패
        if lowerThought.contains("면접") || lowerThought.contains("취업") || 
           lowerThought.contains("떨어") || lowerThought.contains("실패") ||
           lowerThought.contains("불합격") {
            let jobFrames = [
                "💝 면접 결과가 아쉽지만, 이는 당신의 가치를 결정하지 않아요. 더 좋은 기회가 기다리고 있을 거예요.",
                "🌱 모든 면접은 경험이 되고 성장의 기회가 됩니다. 이번 경험을 통해 다음에는 더 잘할 수 있을 거예요.",
                "🤗 지금은 실망스럽지만, 때로는 문이 닫히는 것이 더 좋은 문을 열어주는 신호일 수도 있어요."
            ]
            return jobFrames.randomElement()!
        }
        
        // 학업/성적 문제
        if lowerThought.contains("공부") || lowerThought.contains("시험") || 
           lowerThought.contains("성적") || lowerThought.contains("학교") {
            let studyFrames = [
                "📚 공부는 결과보다 과정이 더 중요해요. 지금 노력하는 모든 것이 미래의 자양분이 될 거예요.",
                "✨ 완벽한 성적보다는 꾸준한 성장이 더 의미 있어요. 어제의 나보다 조금씩 나아지고 있다면 충분해요.",
                "💙 힘든 공부 시간을 보내고 계시는군요. 자신만의 속도로 천천히, 하지만 꾸준히 해나가면 됩니다."
            ]
            return studyFrames.randomElement()!
        }
        
        // 자존감 문제
        if lowerThought.contains("못") || lowerThought.contains("안돼") || 
           lowerThought.contains("바보") || lowerThought.contains("쓸모") {
            let selfEsteemFrames = [
                "🤗 완벽하지 않아도 괜찮아요. 당신은 이미 충분히 가치 있는 사람이고, 있는 그대로도 소중해요.",
                "💝 자신에게 친구에게 하듯 따뜻하게 말해주세요. 당신은 사랑받을 자격이 있고, 노력하는 모습 자체가 아름다워요.",
                "🌈 모든 사람은 실수를 하고 부족한 면이 있어요. 그것이 인간다운 거예요. 당신의 노력과 마음을 인정해주세요."
            ]
            return selfEsteemFrames.randomElement()!
        }
        
        // 기본 CBT 리프레이밍
        let generalFrames = [
            "💙 이런 마음이 드는 것은 자연스러운 일이에요. 지금 이 순간 내가 할 수 있는 작은 것부터 시작해보면 어떨까요?",
            "🌱 힘든 감정을 느끼고 계시는군요. 이 상황에서도 내가 성장할 수 있는 기회가 있을까요?",
            "✨ 지금 느끼는 감정을 인정하고 받아들여주세요. 당신은 최선을 다하고 있고, 그것만으로도 충분해요.",
            "🌈 어려운 상황이지만 당신은 이미 많은 것을 해내고 있어요. 이 경험을 통해 더 강해질 수 있을 거예요.",
            "💝 자신에게 따뜻하게 말해주세요. 지금은 힘들지만, 이 또한 지나갈 것이고 당신은 충분히 가치 있는 사람이에요."
        ]
        
        return generalFrames.randomElement()!
    }
    
    func calculateStreak() {
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
    
    func getReframingRate() -> Double {
        let reframedCount = thoughts.filter { $0.reframedContent != nil }.count
        return thoughts.isEmpty ? 0 : Double(reframedCount) / Double(thoughts.count)
    }
    
    func getMostCommonEmotion() -> String {
        let emotionCounts = Dictionary(grouping: thoughts, by: { $0.emotion })
            .mapValues { $0.count }
        return emotionCounts.max(by: { $0.value < $1.value })?.key ?? "중립"
    }
}

// MARK: - Main ContentView
struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)
            
            ThoughtListView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("생각")
                }
                .tag(1)
            
            SimpleMoodView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("일일체크")
                }
                .tag(2)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("분석")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - HomeView
struct HomeView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var showingNewThought = false
    @State private var showingNewMood = false
    @State private var todayMoodRating = 3
    @State private var hasCheckedToday = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.0), location: 0.0),
                        .init(color: Color(red: 0.92, green: 0.95, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.88, green: 0.93, blue: 0.97), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // 프로페셔널 헤더
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Re:Frame")
                                        .font(.system(size: 32, weight: .light, design: .rounded))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Text("마음 돌보기 플랫폼")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                        
                                }
                                
                                Spacer()
                                
                                // 프로필 아바타
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.6, green: 0.8, blue: 1.0),
                                                Color(red: 0.8, green: 0.9, blue: 1.0)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 24, weight: .light))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                            // 인사이트 메시지 카드
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(red: 0.9, green: 0.95, blue: 1.0))
                                            .frame(width: 8, height: 8)
                                        Text("오늘의 인사이트")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                                            
                                    }
                                    
                                    Text("생각을 바꾸면 감정이 바뀌고,\n감정을 바꾸면 행동이 바뀝니다")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                        
                        // 기분 체크 모듈
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Mood Check")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Text("오늘의 감정 상태를 기록해보세요")
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                                Spacer()
                                
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 24, weight: .light))
                                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.5))
                            }
                            
                            if !hasCheckedToday {
                                VStack(spacing: 16) {
                                    HStack(spacing: 12) {
                                        ForEach(1...5, id: \.self) { index in
                                            Button(action: {
                                                todayMoodRating = index
                                            }) {
                                                Circle()
                                                    .fill(
                                                        index <= todayMoodRating 
                                                        ? LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 1.0, green: 0.8, blue: 0.4),
                                                                Color(red: 1.0, green: 0.6, blue: 0.3)
                                                            ]),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                        : LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 0.95, green: 0.95, blue: 0.95),
                                                                Color(red: 0.90, green: 0.90, blue: 0.90)
                                                            ]),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: 44, height: 44)
                                                    .overlay(
                                                        Text("\(index)")
                                                            .font(.system(size: 16, weight: .medium))
                                                            .foregroundColor(
                                                                index <= todayMoodRating ? .white : Color(red: 0.6, green: 0.6, blue: 0.6)
                                                            )
                                                    )
                                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    Button(action: checkTodayMood) {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16, weight: .medium))
                                            Text("기분 상태 기록")
                                                .font(.system(size: 15, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.6, green: 0.7, blue: 0.9),
                                                    Color(red: 0.5, green: 0.6, blue: 0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.clear
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // 통계 대시보드 - 비대칭 레이아웃
                        VStack(spacing: 16) {
                            HStack {
                                Text("Analytics")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Text("실시간 분석")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    
                            }
                            .padding(.horizontal, 24)
                            
                            // 비대칭 그리드
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    // 큰 카드
                                    AdvancedStatCard(
                                        title: "연속 기록",
                                        value: "\(thoughtViewModel.currentStreak)",
                                        unit: "Days",
                                        icon: "flame.fill",
                                        gradientColors: [
                                            Color(red: 1.0, green: 0.6, blue: 0.3),
                                            Color(red: 1.0, green: 0.4, blue: 0.2)
                                        ],
                                        isLarge: true
                                    )
                                    
                                    VStack(spacing: 12) {
                                        // 작은 카드들
                                        AdvancedStatCard(
                                            title: "총 생각",
                                            value: "\(thoughtViewModel.thoughts.count)",
                                            unit: "Posts",
                                            icon: "brain.head.profile",
                                            gradientColors: [
                                                Color(red: 0.5, green: 0.7, blue: 1.0),
                                                Color(red: 0.4, green: 0.6, blue: 0.9)
                                            ],
                                            isLarge: false
                                        )
                                        
                                        AdvancedStatCard(
                                            title: "완료율",
                                            value: "\(Int(thoughtViewModel.getReframingRate() * 100))",
                                            unit: "%",
                                            icon: "checkmark.circle.fill",
                                            gradientColors: [
                                                Color(red: 0.3, green: 0.8, blue: 0.5),
                                                Color(red: 0.2, green: 0.7, blue: 0.4)
                                            ],
                                            isLarge: false
                                        )
                                    }
                                }
                                
                                // 하단 전체 너비 카드
                                AdvancedStatCard(
                                    title: "주요 감정 패턴",
                                    value: thoughtViewModel.getMostCommonEmotion(),
                                    unit: "Most Frequent",
                                    icon: "heart.text.square.fill",
                                    gradientColors: [
                                        Color(red: 0.9, green: 0.5, blue: 0.7),
                                        Color(red: 0.8, green: 0.4, blue: 0.6)
                                    ],
                                    isWide: true
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // 액션 모듈 - 더 전문적인 디자인
                        VStack(spacing: 20) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            
                            VStack(spacing: 14) {
                                ProfessionalActionCard(
                                    title: "새로운 생각 기록",
                                    subtitle: "인지 패턴을 분석하고 기록합니다",
                                    icon: "doc.text.fill",
                                    gradientColors: [
                                        Color(red: 0.6, green: 0.7, blue: 1.0),
                                        Color(red: 0.5, green: 0.6, blue: 0.9)
                                    ]
                                ) {
                                    showingNewThought = true
                                }
                                
                                ProfessionalActionCard(
                                    title: "감정 상태 체크",
                                    subtitle: "현재 감정을 상세히 분석해보세요",
                                    icon: "heart.text.square.fill",
                                    gradientColors: [
                                        Color(red: 0.9, green: 0.5, blue: 0.6),
                                        Color(red: 0.8, green: 0.4, blue: 0.5)
                                    ]
                                ) {
                                    showingNewMood = true
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewThought) {
                NewThoughtView()
            }
            .sheet(isPresented: $showingNewMood) {
                NewMoodView()
            }
            .onAppear {
                checkIfAlreadyCheckedToday()
            }
        }
    }
    
    private func checkTodayMood() {
        thoughtViewModel.addMoodEntry(todayMoodRating, emotions: [], note: nil)
        hasCheckedToday = true
    }
    
    private func moodDescription(_ rating: Int) -> String {
        switch rating {
        case 1: return "매우 나쁨"
        case 2: return "나쁨"
        case 3: return "보통"
        case 4: return "좋음"
        case 5: return "매우 좋음"
        default: return "보통"
        }
    }
    
    private func checkIfAlreadyCheckedToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        hasCheckedToday = thoughtViewModel.moodEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }
        
        if let todayEntry = thoughtViewModel.moodEntries.first(where: { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }) {
            todayMoodRating = todayEntry.rating
        }
    }
}

// MARK: - Professional Components
struct AdvancedStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let gradientColors: [Color]
    var isLarge: Bool = false
    var isWide: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: isLarge ? 24 : 18, weight: .light))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    
                    .textCase(.uppercase)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: isLarge ? 28 : 20, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: isLarge ? 14 : 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
        }
        .padding(isLarge ? 20 : 16)
        .frame(maxWidth: .infinity, minHeight: isLarge ? 120 : (isWide ? 80 : 100), alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .shadow(color: gradientColors.first?.opacity(0.3) ?? Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}

struct ProfessionalActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                        )
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Spacer()
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(20)
            .frame(height: 90)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: gradientColors.first?.opacity(0.2) ?? Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ThoughtListView
struct ThoughtListView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var showingNewThought = false
    @State private var selectedThought: Thought?
    @State private var searchText = ""
    @State private var selectedEmotion = "전체"
    
    var filteredThoughts: [Thought] {
        var filtered = thoughtViewModel.thoughts
        
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        
        if selectedEmotion != "전체" {
            filtered = filtered.filter { $0.emotion == selectedEmotion }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.0), location: 0.0),
                        .init(color: Color(red: 0.92, green: 0.95, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.88, green: 0.93, blue: 0.97), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 프로페셔널 헤더
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Thoughts")
                                    .font(.system(size: 28, weight: .light, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("생각 기록 & 분석")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                    
                            }
                            
                            Spacer()
                            
                            // 새 기록 버튼
                            Button(action: { showingNewThought = true }) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.6, green: 0.7, blue: 1.0),
                                                Color(red: 0.5, green: 0.6, blue: 0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                        }
                        
                        // 검색 및 필터 - 프로페셔널 스타일
                        VStack(spacing: 16) {
                            // 검색바
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                
                                TextField("생각 검색...", text: $searchText)
                                    .font(.system(size: 15))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                            
                            // 필터 칩들
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ProfessionalFilterChip(
                                        title: "전체", 
                                        isSelected: selectedEmotion == "전체"
                                    ) {
                                        selectedEmotion = "전체"
                                    }
                                    
                                    ForEach(thoughtViewModel.emotions, id: \.self) { emotion in
                                        ProfessionalFilterChip(
                                            title: emotion, 
                                            isSelected: selectedEmotion == emotion
                                        ) {
                                            selectedEmotion = emotion
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // 생각 목록
                    if filteredThoughts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 48, weight: .light))
                                .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.8))
                            
                            Text("아직 기록된 생각이 없어요")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            
                            Text("첫 번째 생각을 기록해보세요")
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredThoughts) { thought in
                                    ProfessionalThoughtCard(thought: thought)
                                        .onTapGesture {
                                            selectedThought = thought
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewThought) {
                NewThoughtView()
            }
            .sheet(item: $selectedThought) { thought in
                ThoughtDetailView(thought: thought)
            }
        }
    }
    
    private func deleteThoughts(offsets: IndexSet) {
        for index in offsets {
            thoughtViewModel.deleteThought(filteredThoughts[index])
        }
    }
}

// MARK: - Professional Filter & Card Components
struct ProfessionalFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected 
                            ? LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.5, green: 0.7, blue: 1.0),
                                    Color(red: 0.4, green: 0.6, blue: 0.9)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.5)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    isSelected 
                                    ? Color.clear 
                                    : Color.white.opacity(0.6), 
                                    lineWidth: 1
                                )
                        )
                )
                .foregroundColor(isSelected ? .white : Color(red: 0.4, green: 0.5, blue: 0.6))
                .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.04), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfessionalThoughtCard: View {
    let thought: Thought
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thought.createdAt, style: .date)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                        
                    
                    HStack(spacing: 8) {
                        ProfessionalEmotionTag(emotion: thought.emotion)
                        ProfessionalCategoryTag(category: thought.category)
                    }
                }
                
                Spacer()
                
                // 즐겨찾기 & 기분 점수
                VStack(spacing: 8) {
                    Button(action: {
                        thoughtViewModel.toggleFavorite(thought)
                    }) {
                        Image(systemName: thought.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(thought.isFavorite ? Color(red: 1.0, green: 0.4, blue: 0.5) : Color(red: 0.6, green: 0.7, blue: 0.8))
                    }
                    
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Circle()
                                .fill(index <= thought.moodRating ? Color(red: 1.0, green: 0.7, blue: 0.3) : Color(red: 0.9, green: 0.9, blue: 0.9))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            // 생각 내용
            Text(thought.content)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                .lineLimit(4)
                .lineSpacing(2)
            
            // 리프레이밍된 내용 (있는 경우)
            if let reframedContent = thought.reframedContent {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(red: 0.3, green: 0.8, blue: 0.5))
                            .frame(width: 6, height: 6)
                        Text("리프레이밍 완료")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5))
                            
                    }
                    
                    Text(reframedContent)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                        .lineLimit(3)
                        .padding(.leading, 12)
                        .overlay(
                            Rectangle()
                                .fill(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.3))
                                .frame(width: 3)
                                .padding(.leading, 2),
                            alignment: .leading
                        )
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct ProfessionalEmotionTag: View {
    let emotion: String
    
    var body: some View {
        Text(emotion)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.6, green: 0.7, blue: 1.0).opacity(0.2))
            )
            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.8))
            
    }
}

struct ProfessionalCategoryTag: View {
    let category: String
    
    var body: some View {
        Text(category)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.3, green: 0.8, blue: 0.5).opacity(0.2))
            )
            .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.4))
            
    }
}

// MARK: - NewThoughtView (Enhanced)
struct NewThoughtView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var thoughtText = ""
    @State private var selectedEmotion = "중립"
    @State private var selectedCategory = "일반"
    @State private var moodRating = 3
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("생각 내용")) {
                    TextEditor(text: $thoughtText)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("감정")) {
                    Picker("감정 선택", selection: $selectedEmotion) {
                        ForEach(thoughtViewModel.emotions, id: \.self) { emotion in
                            Text(emotion).tag(emotion)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("카테고리")) {
                    Picker("카테고리 선택", selection: $selectedCategory) {
                        ForEach(thoughtViewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("기분 점수 (1-5)")) {
                    HStack {
                        Text("1")
                        Slider(value: Binding(
                            get: { Double(moodRating) },
                            set: { moodRating = Int($0) }
                        ), in: 1...5, step: 1)
                        Text("5")
                    }
                    
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= moodRating ? "star.fill" : "star")
                                .foregroundColor(index <= moodRating ? .yellow : .gray)
                        }
                        Spacer()
                        Text("\(moodRating)점")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("새로운 생각")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        if thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showingAlert = true
                        } else {
                            thoughtViewModel.addThought(thoughtText, emotion: selectedEmotion, category: selectedCategory, moodRating: moodRating)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text("생각을 입력해주세요."),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }
}

// MARK: - SimpleMoodView (간단한 일일 체크)
struct SimpleMoodView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var todayMoodRating = 3
    @State private var hasCheckedToday = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.0), location: 0.0),
                        .init(color: Color(red: 0.92, green: 0.95, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.88, green: 0.93, blue: 0.97), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        // 프로페셔널 헤더
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Daily Check")
                                        .font(.system(size: 28, weight: .light, design: .rounded))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Text("일일 감정 모니터링")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                                Spacer()
                            }
                            
                            // 인사이트 카드
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(red: 0.9, green: 0.5, blue: 0.7))
                                            .frame(width: 8, height: 8)
                                        Text("일일 체크 인사이트")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                                    }
                                    
                                    Text("매일 조금씩 체크하는 것만으로도\n큰 변화를 만들 수 있어요")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 오늘의 기분 체크 카드
                        VStack(spacing: 16) {
                            VStack(spacing: 12) {
                                Text("오늘 하루는 어떠셨나요?")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                
                                Text("감정을 선택해보세요")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            // 기분 선택 인터페이스
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Button(action: {
                                            todayMoodRating = rating
                                            checkTodayMood()
                                        }) {
                                            VStack(spacing: 8) {
                                                // 이모지 원
                                                Circle()
                                                    .fill(
                                                        todayMoodRating == rating
                                                        ? LinearGradient(
                                                            gradient: Gradient(colors: moodGradientColors(for: rating)),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                        : LinearGradient(
                                                            gradient: Gradient(colors: [
                                                                Color(red: 0.95, green: 0.95, blue: 0.95),
                                                                Color(red: 0.90, green: 0.90, blue: 0.90)
                                                            ]),
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: 48, height: 48)
                                                    .overlay(
                                                        Text(moodEmoji(for: rating))
                                                            .font(.system(size: 20))
                                                    )
                                                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                                
                                                Text(moodText(for: rating))
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(
                                                        todayMoodRating == rating 
                                                        ? Color(red: 0.2, green: 0.3, blue: 0.4)
                                                        : Color(red: 0.6, green: 0.7, blue: 0.8)
                                                    )
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(width: 60)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                
                                if hasCheckedToday {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5))
                                        Text("오늘의 체크 완료!")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.5))
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 20)
                        
                        // 주간 트렌드 분석
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Weekly Trends")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Text("지난 7일간")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            ProfessionalWeeklyChart()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 20)
                        
                        // 하단 여백 (탭바 고려)
                        Spacer()
                            .frame(height: 120)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                checkIfAlreadyCheckedToday()
            }
        }
    }
    
    private func moodEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😢"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "😊"
        case 5: return "😄"
        default: return "😐"
        }
    }
    
    private func moodText(for rating: Int) -> String {
        switch rating {
        case 1: return "매우 나쁨"
        case 2: return "나쁨"
        case 3: return "보통"
        case 4: return "좋음"
        case 5: return "매우 좋음"
        default: return "보통"
        }
    }
    
    private func moodGradientColors(for rating: Int) -> [Color] {
        switch rating {
        case 1: return [Color(red: 1.0, green: 0.5, blue: 0.5), Color(red: 1.0, green: 0.3, blue: 0.3)]
        case 2: return [Color(red: 1.0, green: 0.7, blue: 0.4), Color(red: 1.0, green: 0.5, blue: 0.3)]
        case 3: return [Color(red: 0.9, green: 0.9, blue: 0.5), Color(red: 0.8, green: 0.8, blue: 0.4)]
        case 4: return [Color(red: 0.5, green: 0.9, blue: 0.6), Color(red: 0.3, green: 0.8, blue: 0.5)]
        case 5: return [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.7, blue: 0.9)]
        default: return [Color.gray, Color.gray]
        }
    }
    
    private func checkTodayMood() {
        thoughtViewModel.addMoodEntry(todayMoodRating, emotions: [], note: nil)
        hasCheckedToday = true
    }
    
    private func checkIfAlreadyCheckedToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        hasCheckedToday = thoughtViewModel.moodEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }
        
        if let todayEntry = thoughtViewModel.moodEntries.first(where: { entry in
            calendar.isDate(entry.date, inSameDayAs: today)
        }) {
            todayMoodRating = todayEntry.rating
        }
    }
}

struct ProfessionalWeeklyChart: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    
    var body: some View {
        let weekData = getWeeklyMoodData()
        
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weekData, id: \.day) { data in
                    VStack(spacing: 8) {
                        // 막대그래프
                        Rectangle()
                            .fill(
                                data.rating > 0 
                                ? LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.5, green: 0.7, blue: 1.0),
                                        Color(red: 0.4, green: 0.6, blue: 0.9)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.95, green: 0.95, blue: 0.95),
                                        Color(red: 0.90, green: 0.90, blue: 0.90)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 32, height: CGFloat(max(data.rating * 12, 4)))
                            .cornerRadius(6)
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        
                        Text(data.day)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                    }
                }
            }
            .frame(height: 80)
        }
    }
    
    private func getWeeklyMoodData() -> [(day: String, rating: Int)] {
        let calendar = Calendar.current
        let today = Date()
        let weekdays = ["월", "화", "수", "목", "금", "토", "일"]
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -6 + dayOffset, to: today) ?? today
            let dayName = weekdays[dayOffset]
            
            let rating = thoughtViewModel.moodEntries.first { entry in
                calendar.isDate(entry.date, inSameDayAs: date)
            }?.rating ?? 0
            
            return (day: dayName, rating: rating)
        }
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= entry.rating ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(index <= entry.rating ? .yellow : .gray)
                    }
                }
                
                Spacer()
                
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(entry.emotions, id: \.self) { emotion in
                        Text(emotion)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
            }
            
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// MARK: - NewMoodView
struct NewMoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var moodRating = 3
    @State private var selectedEmotions: Set<String> = []
    @State private var note = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("기분 점수")) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("매우 나쁨")
                                .font(.caption)
                            Spacer()
                            Text("보통")
                                .font(.caption)
                            Spacer()
                            Text("매우 좋음")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                        
                        Slider(value: Binding(
                            get: { Double(moodRating) },
                            set: { moodRating = Int($0) }
                        ), in: 1...5, step: 1)
                        
                        HStack {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= moodRating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(index <= moodRating ? .yellow : .gray)
                            }
                        }
                    }
                }
                
                Section(header: Text("감정 선택 (복수 선택 가능)")) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(thoughtViewModel.emotions, id: \.self) { emotion in
                            Button(action: {
                                if selectedEmotions.contains(emotion) {
                                    selectedEmotions.remove(emotion)
                                } else {
                                    selectedEmotions.insert(emotion)
                                }
                            }) {
                                Text(emotion)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedEmotions.contains(emotion) ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedEmotions.contains(emotion) ? .white : .primary)
                                    .cornerRadius(16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Section(header: Text("메모 (선택사항)")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("기분 기록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        thoughtViewModel.addMoodEntry(moodRating, emotions: Array(selectedEmotions), note: note.isEmpty ? nil : note)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - AnalyticsView
struct AnalyticsView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.0), location: 0.0),
                        .init(color: Color(red: 0.92, green: 0.95, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.88, green: 0.93, blue: 0.97), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 프로페셔널 헤더
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Analytics")
                                        .font(.system(size: 28, weight: .light, design: .rounded))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Text("데이터 기반 인사이트")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                                Spacer()
                            }
                            
                            // 인사이트 카드
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(red: 0.6, green: 0.8, blue: 1.0))
                                            .frame(width: 8, height: 8)
                                        Text("분석 인사이트")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                                    }
                                    
                                    Text("패턴을 파악하여 더 나은\n마음 관리를 시작해보세요")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // 주요 지표 카드들
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            AdvancedStatCard(
                                title: "총 생각 수",
                                value: "\(thoughtViewModel.thoughts.count)",
                                unit: "Posts",
                                icon: "brain.head.profile",
                                gradientColors: [
                                    Color(red: 0.5, green: 0.7, blue: 1.0),
                                    Color(red: 0.4, green: 0.6, blue: 0.9)
                                ]
                            )
                            
                            AdvancedStatCard(
                                title: "리프레이밍률",
                                value: "\(Int(thoughtViewModel.getReframingRate() * 100))",
                                unit: "Percent",
                                icon: "arrow.triangle.2.circlepath",
                                gradientColors: [
                                    Color(red: 0.3, green: 0.8, blue: 0.5),
                                    Color(red: 0.2, green: 0.7, blue: 0.4)
                                ]
                            )
                            
                            AdvancedStatCard(
                                title: "연속 기록",
                                value: "\(thoughtViewModel.currentStreak)",
                                unit: "Days",
                                icon: "flame.fill",
                                gradientColors: [
                                    Color(red: 1.0, green: 0.6, blue: 0.3),
                                    Color(red: 1.0, green: 0.4, blue: 0.2)
                                ]
                            )
                            
                            AdvancedStatCard(
                                title: "평균 기분",
                                value: String(format: "%.1f", getAverageMood()),
                                unit: "Rating",
                                icon: "heart.fill",
                                gradientColors: [
                                    Color(red: 0.9, green: 0.5, blue: 0.7),
                                    Color(red: 0.8, green: 0.4, blue: 0.6)
                                ]
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // 감정 분포 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Emotion Distribution")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Text("감정별 분석")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            let emotionCounts = getEmotionCounts()
                            VStack(spacing: 12) {
                                ForEach(emotionCounts.sorted(by: { $0.value > $1.value }), id: \.key) { emotion, count in
                                    HStack {
                                        Text(emotion)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        
                                        Spacer()
                                        
                                        Text("\(count)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.6, green: 0.7, blue: 1.0),
                                                        Color(red: 0.5, green: 0.6, blue: 0.9)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: CGFloat(count) / CGFloat(max(thoughtViewModel.thoughts.count, 1)) * 120, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // 카테고리 분포 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Category Analysis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Text("주제별 분석")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                            }
                            
                            let categoryCounts = getCategoryCounts()
                            VStack(spacing: 12) {
                                ForEach(categoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        
                                        Spacer()
                                        
                                        Text("\(count)")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        
                                        Rectangle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.3, green: 0.8, blue: 0.5),
                                                        Color(red: 0.2, green: 0.7, blue: 0.4)
                                                    ]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .frame(width: CGFloat(count) / CGFloat(max(thoughtViewModel.thoughts.count, 1)) * 120, height: 8)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func getAverageMood() -> Double {
        guard !thoughtViewModel.moodEntries.isEmpty else { return 0 }
        let total = thoughtViewModel.moodEntries.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(thoughtViewModel.moodEntries.count)
    }
    
    private func getEmotionCounts() -> [String: Int] {
        Dictionary(grouping: thoughtViewModel.thoughts, by: { $0.emotion })
            .mapValues { $0.count }
    }
    
    private func getCategoryCounts() -> [String: Int] {
        Dictionary(grouping: thoughtViewModel.thoughts, by: { $0.category })
            .mapValues { $0.count }
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var username = "사용자"
    @State private var isDarkMode = false
    @State private var dailyReminder = true
    @State private var streakGoal = 7
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.95, green: 0.97, blue: 1.0), location: 0.0),
                        .init(color: Color(red: 0.92, green: 0.95, blue: 0.98), location: 0.5),
                        .init(color: Color(red: 0.88, green: 0.93, blue: 0.97), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 프로페셔널 헤더
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Settings")
                                        .font(.system(size: 28, weight: .light, design: .rounded))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                    
                                    Text("앱 설정 & 사용자 정보")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                                Spacer()
                            }
                            
                            // 인사이트 카드
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(red: 0.7, green: 0.6, blue: 0.9))
                                            .frame(width: 8, height: 8)
                                        Text("개인화 설정")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.7))
                                    }
                                    
                                    Text("나에게 맞는 설정으로\n더 나은 경험을 만들어보세요")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        .lineSpacing(2)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // 프로필 설정 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Profile")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.9))
                            }
                            
                            HStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.6, green: 0.7, blue: 1.0),
                                                Color(red: 0.5, green: 0.6, blue: 0.9)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 8, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("사용자명")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                    Text("앱에서 사용할 이름")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                }
                                
                                Spacer()
                                
                                Text(username)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // 앱 설정 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("App Settings")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.7, green: 0.6, blue: 0.9))
                            }
                            
                            VStack(spacing: 16) {
                                // 다크모드 토글
                                HStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.3, green: 0.3, blue: 0.4),
                                                    Color(red: 0.2, green: 0.2, blue: 0.3)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Image(systemName: "moon.fill")
                                                .font(.system(size: 8, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("다크 모드")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        Text("어두운 테마 사용")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $isDarkMode)
                                        .labelsHidden()
                                }
                                
                                // 일일 알림 토글
                                HStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 1.0, green: 0.6, blue: 0.3),
                                                    Color(red: 1.0, green: 0.4, blue: 0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 8, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("일일 알림")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        Text("매일 리마인더 받기")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $dailyReminder)
                                        .labelsHidden()
                                }
                                
                                // 연속 목표 스테퍼
                                HStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color(red: 0.3, green: 0.8, blue: 0.5),
                                                    Color(red: 0.2, green: 0.7, blue: 0.4)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            Image(systemName: "target")
                                                .font(.system(size: 8, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("연속 목표")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                        Text("목표 연속 기록일")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    HStack {
                                        Text("\(streakGoal)일")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                        
                                        Stepper("", value: $streakGoal, in: 1...30)
                                            .labelsHidden()
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // 데이터 관리 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Data Management")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Image(systemName: "externaldrive.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.5, green: 0.7, blue: 1.0))
                            }
                            
                            VStack(spacing: 16) {
                                // 데이터 내보내기
                                Button(action: {
                                    // 데이터 내보내기 액션
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 0.5, green: 0.7, blue: 1.0),
                                                        Color(red: 0.4, green: 0.6, blue: 0.9)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Image(systemName: "square.and.arrow.up.fill")
                                                    .font(.system(size: 8, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("데이터 내보내기")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                            Text("모든 데이터를 백업하기")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // 데이터 초기화
                                Button(action: {
                                    // 데이터 초기화 액션
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        Color(red: 1.0, green: 0.4, blue: 0.4),
                                                        Color(red: 1.0, green: 0.3, blue: 0.3)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 8, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("데이터 초기화")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(Color(red: 1.0, green: 0.3, blue: 0.3))
                                            Text("모든 데이터 삭제 (주의)")
                                                .font(.system(size: 12, weight: .regular))
                                                .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color(red: 1.0, green: 0.4, blue: 0.4))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // 앱 정보 카드
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("App Info")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.4))
                                Spacer()
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(red: 0.6, green: 0.7, blue: 0.8))
                            }
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    Text("언어")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                    Spacer()
                                    Text("한국어")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                                
                                HStack {
                                    Image(systemName: "app.badge")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    Text("버전")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                                
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.5, green: 0.6, blue: 0.7))
                                    Text("개발자")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.3, green: 0.4, blue: 0.5))
                                    Spacer()
                                    Text("Re:Frame Team")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(red: 0.4, green: 0.5, blue: 0.6))
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - ThoughtDetailView (Enhanced)
struct ThoughtDetailView: View {
    let thought: Thought
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var isReframing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 원본 생각
                    VStack(alignment: .leading, spacing: 8) {
                        Text("원본 생각")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(thought.content)
                            .font(.body)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    // 메타데이터
                    VStack(alignment: .leading, spacing: 8) {
                        Text("상세 정보")
                            .font(.headline)
                        
                        HStack {
                            ProfessionalEmotionTag(emotion: thought.emotion)
                            ProfessionalCategoryTag(category: thought.category)
                            Spacer()
                            ProfessionalMoodRating(rating: thought.moodRating)
                        }
                    }
                    
                    // 리프레이밍된 생각
                    VStack(alignment: .leading, spacing: 8) {
                        Text("리프레이밍된 생각")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let reframedContent = thought.reframedContent {
                            Text(reframedContent)
                                .font(.body)
                                .padding()
                                .background(Color(.systemBlue).opacity(0.1))
                                .cornerRadius(10)
                        } else {
                            Text("아직 리프레이밍되지 않았습니다.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                    }
                    
                    // 리프레이밍 버튼
                    Button(action: {
                        reframeThought()
                    }) {
                        HStack {
                            if isReframing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("리프레이밍 중...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(thought.reframedContent == nil ? "리프레이밍하기" : "다시 리프레이밍하기")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                    }
                    .disabled(isReframing)
                    
                    // 날짜 정보
                    VStack(alignment: .leading, spacing: 4) {
                        Text("생성일: \(thought.createdAt, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if thought.updatedAt != thought.createdAt {
                            Text("수정일: \(thought.updatedAt, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("생각 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        thoughtViewModel.toggleFavorite(thought)
                    }) {
                        Image(systemName: thought.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(thought.isFavorite ? .red : .gray)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func reframeThought() {
        isReframing = true
        
        Task {
            do {
                let reframedContent = try await thoughtViewModel.reframeThought(thought)
                await MainActor.run {
                    thoughtViewModel.updateThought(thought, reframedContent: reframedContent)
                    isReframing = false
                    
                    // 리프레이밍 완료 후 전면 광고 표시 (1초 지연)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // AdManager의 공유 인스턴스를 통해 전면 광고 표시
                        NotificationCenter.default.post(name: NSNotification.Name("ShowInterstitialAd"), object: nil)
                    }
                }
            } catch {
                await MainActor.run {
                    isReframing = false
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AdManager())
            .environmentObject(ThoughtViewModel())
    }
}

struct ProfessionalMoodRating: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= rating ? Color(red: 1.0, green: 0.7, blue: 0.3) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
