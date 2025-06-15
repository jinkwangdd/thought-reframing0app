//
//  ContentView_backup.swift
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
        // 실제 AI 리프레이밍 로직 (현재는 시뮬레이션)
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기
        
        let reframingTemplates = [
            "이 상황을 다른 관점에서 보면: \(thought.content)에서 배울 수 있는 점이 있을까요?",
            "더 균형잡힌 시각으로 보면: \(thought.content)이 완전히 사실일까요? 다른 가능성은 없을까요?",
            "긍정적 재구성: \(thought.content) 상황에서도 감사할 수 있는 부분이 있다면 무엇일까요?",
            "해결 중심 사고: \(thought.content) 문제를 해결하기 위해 할 수 있는 작은 행동은 무엇일까요?"
        ]
        
        return reframingTemplates.randomElement() ?? "이 생각을 더 건설적인 방향으로 바라볼 수 있습니다."
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

// MARK: - Views
struct ContentView: View {
    @State private var isLoading = true
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
            
            MoodTrackingView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("기분")
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 환영 메시지
                    VStack(alignment: .leading, spacing: 8) {
                        Text("안녕하세요! 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("오늘도 마음을 돌보는 시간을 가져보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 통계 카드들
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "연속 기록",
                            value: "\(thoughtViewModel.currentStreak)일",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "총 생각",
                            value: "\(thoughtViewModel.thoughts.count)개",
                            icon: "brain.head.profile",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "리프레이밍률",
                            value: "\(Int(thoughtViewModel.getReframingRate() * 100))%",
                            icon: "arrow.triangle.2.circlepath",
                            color: .green
                        )
                        
                        StatCard(
                            title: "주요 감정",
                            value: thoughtViewModel.getMostCommonEmotion(),
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    
                    // 빠른 액션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("빠른 시작")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 12) {
                            QuickActionButton(
                                title: "생각 기록",
                                icon: "plus.circle.fill",
                                color: .blue
                            ) {
                                // 새 생각 추가 액션
                            }
                            
                            QuickActionButton(
                                title: "기분 체크",
                                icon: "heart.circle.fill",
                                color: .red
                            ) {
                                // 기분 추가 액션
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Reframe")
        }
    }
}

struct StatCard: View {
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
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
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
            VStack {
                // 검색 및 필터
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "전체", isSelected: selectedEmotion == "전체") {
                                selectedEmotion = "전체"
                            }
                            
                            ForEach(thoughtViewModel.emotions, id: \.self) { emotion in
                                FilterChip(title: emotion, isSelected: selectedEmotion == emotion) {
                                    selectedEmotion = emotion
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                // 생각 목록
                List {
                    ForEach(filteredThoughts) { thought in
                        ThoughtRow(thought: thought)
                            .onTapGesture {
                                selectedThought = thought
                            }
                    }
                    .onDelete(perform: deleteThoughts)
                }
            }
            .navigationTitle("생각 기록")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewThought = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("생각 검색...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ThoughtRow
struct ThoughtRow: View {
    let thought: Thought
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(thought.content)
                    .font(.body)
                    .lineLimit(3)
                
                Spacer()
                
                Button(action: {
                    thoughtViewModel.toggleFavorite(thought)
                }) {
                    Image(systemName: thought.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(thought.isFavorite ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                EmotionTag(emotion: thought.emotion)
                CategoryTag(category: thought.category)
                Spacer()
                MoodRating(rating: thought.moodRating)
            }
            
            if let reframedContent = thought.reframedContent {
                Text(reframedContent)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                    .padding(.leading, 8)
                    .overlay(
                        Rectangle()
                            .frame(width: 2)
                            .foregroundColor(.blue)
                            .padding(.leading, 2),
                        alignment: .leading
                    )
            }
            
            Text(thought.createdAt, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EmotionTag: View {
    let emotion: String
    
    var body: some View {
        Text(emotion)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

struct CategoryTag: View {
    let category: String
    
    var body: some View {
        Text(category)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(8)
    }
}

struct MoodRating: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(index <= rating ? .yellow : .gray)
            }
        }
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

// MARK: - MoodTrackingView
struct MoodTrackingView: View {
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var showingNewMood = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 오늘의 기분 체크
                    VStack(alignment: .leading, spacing: 12) {
                        Text("오늘의 기분은 어떠신가요?")
                            .font(.headline)
                        
                        Button(action: {
                            showingNewMood = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("기분 기록하기")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 기분 기록 목록
                    VStack(alignment: .leading, spacing: 12) {
                        Text("최근 기분 기록")
                            .font(.headline)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(thoughtViewModel.moodEntries.prefix(10)) { entry in
                                MoodEntryRow(entry: entry)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("기분 추적")
            .sheet(isPresented: $showingNewMood) {
                NewMoodView()
            }
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
            ScrollView {
                VStack(spacing: 20) {
                    // 통계 요약
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        AnalyticsCard(
                            title: "총 생각 수",
                            value: "\(thoughtViewModel.thoughts.count)",
                            icon: "brain.head.profile",
                            color: .blue
                        )
                        
                        AnalyticsCard(
                            title: "리프레이밍률",
                            value: "\(Int(thoughtViewModel.getReframingRate() * 100))%",
                            icon: "arrow.triangle.2.circlepath",
                            color: .green
                        )
                        
                        AnalyticsCard(
                            title: "연속 기록",
                            value: "\(thoughtViewModel.currentStreak)일",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        AnalyticsCard(
                            title: "평균 기분",
                            value: String(format: "%.1f", getAverageMood()),
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    
                    // 감정 분포
                    VStack(alignment: .leading, spacing: 12) {
                        Text("감정 분포")
                            .font(.headline)
                        
                        let emotionCounts = getEmotionCounts()
                        ForEach(emotionCounts.sorted(by: { $0.value > $1.value }), id: \.key) { emotion, count in
                            HStack {
                                Text(emotion)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Rectangle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: CGFloat(count) / CGFloat(thoughtViewModel.thoughts.count) * 100, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 카테고리 분포
                    VStack(alignment: .leading, spacing: 12) {
                        Text("카테고리 분포")
                            .font(.headline)
                        
                        let categoryCounts = getCategoryCounts()
                        ForEach(categoryCounts.sorted(by: { $0.value > $1.value }), id: \.key) { category, count in
                            HStack {
                                Text(category)
                                    .font(.body)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(width: CGFloat(count) / CGFloat(thoughtViewModel.thoughts.count) * 100, height: 8)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("분석")
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
            Form {
                Section(header: Text("프로필")) {
                    HStack {
                        Text("사용자명")
                        Spacer()
                        TextField("사용자명", text: $username)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("앱 설정")) {
                    Toggle("다크 모드", isOn: $isDarkMode)
                    Toggle("일일 알림", isOn: $dailyReminder)
                    
                    HStack {
                        Text("연속 목표")
                        Spacer()
                        Stepper("\(streakGoal)일", value: $streakGoal, in: 1...30)
                    }
                }
                
                Section(header: Text("언어")) {
                    Picker("언어 선택", selection: $thoughtViewModel.language) {
                        Text("한국어").tag("ko")
                        Text("English").tag("en")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("데이터")) {
                    Button("데이터 내보내기") {
                        // 데이터 내보내기 기능
                    }
                    
                    Button("데이터 초기화") {
                        // 데이터 초기화 기능
                    }
                    .foregroundColor(.red)
                }
                
                Section(header: Text("정보")) {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("설정")
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
                            EmotionTag(emotion: thought.emotion)
                            CategoryTag(category: thought.category)
                            Spacer()
                            MoodRating(rating: thought.moodRating)
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
