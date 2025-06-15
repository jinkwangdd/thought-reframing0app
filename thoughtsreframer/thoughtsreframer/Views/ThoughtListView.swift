import SwiftUI

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
                        ThoughtRowEnhanced(thought: thought)
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

// 향상된 ThoughtRow
struct ThoughtRowEnhanced: View {
    let thought: Thought
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var isReframing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 생각 내용과 즐겨찾기
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(thought.content)
                        .font(.body)
                        .lineLimit(3)
                    
                    HStack {
                        EmotionTag(emotion: thought.emotion)
                        CategoryTag(category: thought.category)
                        Spacer()
                        MoodRating(rating: thought.moodRating)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    thoughtViewModel.toggleFavorite(thought)
                }) {
                    Image(systemName: thought.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(thought.isFavorite ? .red : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // 리프레이밍된 내용 (있는 경우)
            if let reframedContent = thought.reframedContent {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text("리프레이밍된 생각")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(reframedContent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                        .overlay(
                            Rectangle()
                                .frame(width: 3)
                                .foregroundColor(.blue)
                                .padding(.leading, 2),
                            alignment: .leading
                        )
                }
                .padding(.top, 4)
            }
            
            // 하단: 날짜와 리프레이밍 버튼
            HStack {
                Text(thought.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 리프레이밍 버튼
                Button(action: {
                    reframeThought()
                }) {
                    HStack(spacing: 4) {
                        if isReframing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                        }
                        Text(isReframing ? "리프레이밍 중..." : (thought.reframedContent == nil ? "리프레이밍" : "다시 리프레이밍"))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Group {
                            if isReframing {
                                Color.orange
                            } else if thought.reframedContent == nil {
                                Color.blue
                            } else {
                                Color.green
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .opacity(isReframing ? 0.8 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isReframing)
            }
        }
        .padding(.vertical, 8)
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

struct ThoughtListView_Previews: PreviewProvider {
    static var previews: some View {
        ThoughtListView()
            .environmentObject(ThoughtViewModel())
    }
} 