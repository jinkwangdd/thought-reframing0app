import SwiftUI

struct NewThoughtView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var thoughtViewModel: ThoughtViewModel
    @State private var thoughtText = ""
    @State private var selectedEmotion = "중립"
    @State private var selectedCategory = "일반"
    @State private var moodRating = 3
    @State private var showingAlert = false
    @State private var showingReframingOption = false
    @State private var savedThought: Thought?
    
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
                    VStack(spacing: 12) {
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
                                    .foregroundColor(index <= moodRating ? .yellow : .gray)
                            }
                            Spacer()
                            Text("\(moodRating)점")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 부정적 감정일 때 리프레이밍 추천
                if shouldSuggestReframing() {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("💡 리프레이밍 추천")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("부정적인 감정이나 낮은 기분 점수가 감지되었습니다. 저장 후 이 생각을 더 균형잡힌 관점으로 리프레이밍해보는 것은 어떨까요?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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
                        saveThought()
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
            .alert(isPresented: $showingReframingOption) {
                Alert(
                    title: Text("리프레이밍 제안"),
                    message: Text("이 생각을 바로 리프레이밍해보시겠습니까?"),
                    primaryButton: .default(Text("네, 리프레이밍하기")) {
                        if let thought = savedThought {
                            startReframing(thought)
                        }
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("나중에")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func shouldSuggestReframing() -> Bool {
        let negativeEmotions = ["슬픔", "분노", "불안", "두려움", "혐오"]
        return negativeEmotions.contains(selectedEmotion) || moodRating <= 3
    }
    
    private func saveThought() {
        if thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showingAlert = true
            return
        }
        
        thoughtViewModel.addThought(thoughtText, emotion: selectedEmotion, category: selectedCategory, moodRating: moodRating)
        
        // 방금 저장된 생각 찾기
        if let newThought = thoughtViewModel.thoughts.first {
            savedThought = newThought
            
            // 부정적 감정이나 낮은 기분일 때 리프레이밍 제안
            if shouldSuggestReframing() {
                showingReframingOption = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func startReframing(_ thought: Thought) {
        Task {
            do {
                let reframedContent = try await thoughtViewModel.reframeThought(thought)
                await MainActor.run {
                    thoughtViewModel.updateThought(thought, reframedContent: reframedContent)
                }
            } catch {
                print("리프레이밍 실패: \(error)")
            }
        }
    }
}

struct NewThoughtView_Previews: PreviewProvider {
    static var previews: some View {
        NewThoughtView()
            .environmentObject(ThoughtViewModel())
    }
} 