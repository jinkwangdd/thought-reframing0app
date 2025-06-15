import SwiftUI

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