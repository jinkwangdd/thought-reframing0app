import SwiftUI

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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 상단 인사말
                        VStack(alignment: .leading, spacing: 8) {
                            Text(getGreeting())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("\(UserDefaults.standard.string(forKey: "username") ?? "사용자")님, 오늘 하루는 어떠셨나요?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        
                        // 기분 체크 섹션
                        if !hasCheckedToday {
                            VStack(spacing: 16) {
                                Text("오늘의 기분은 어떠신가요?")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    ForEach(1...5, id: \.self) { rating in
                                        Button(action: {
                                            todayMoodRating = rating
                                            checkTodayMood()
                                        }) {
                                            VStack(spacing: 8) {
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
                        }
                        
                        // 최근 생각 목록
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("최근 생각")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingNewThought = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if thoughtViewModel.thoughts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    Text("아직 기록된 생각이 없어요")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        showingNewThought = true
                                    }) {
                                        Text("첫 번째 생각 기록하기")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 32)
                            } else {
                                ForEach(thoughtViewModel.thoughts.prefix(3)) { thought in
                                    ThoughtCard(thought: thought)
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
                        
                        // 통계 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            Text("통계")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "연속 기록",
                                    value: "\(thoughtViewModel.currentStreak)일",
                                    icon: "flame.fill",
                                    color: .orange
                                )
                                
                                StatCard(
                                    title: "주요 감정",
                                    value: getTopEmotion(),
                                    icon: "heart.fill",
                                    color: .red
                                )
                            }
                            
                            HStack(spacing: 12) {
                                StatCard(
                                    title: "총 생각",
                                    value: "\(thoughtViewModel.thoughts.count)개",
                                    icon: "brain.head.profile",
                                    color: .blue
                                )
                                
                                StatCard(
                                    title: "완료율",
                                    value: "\(getCompletionRate())%",
                                    icon: "checkmark.circle.fill",
                                    color: .green
                                )
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
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "좋은 아침이에요"
        case 12..<18: return "좋은 오후에요"
        default: return "좋은 저녁이에요"
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
    
    private func getTopEmotion() -> String {
        let emotionCounts = Dictionary(grouping: thoughtViewModel.thoughts, by: { $0.emotion })
            .mapValues { $0.count }
        
        return emotionCounts.max(by: { $0.value < $1.value })?.key ?? "없음"
    }
    
    private func getCompletionRate() -> Int {
        let completedThoughts = thoughtViewModel.thoughts.filter { $0.reframe != nil }.count
        guard !thoughtViewModel.thoughts.isEmpty else { return 0 }
        return Int((Double(completedThoughts) / Double(thoughtViewModel.thoughts.count)) * 100)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
} 