import SwiftUI
import Foundation
import ViewModels

struct NewThoughtView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ThoughtViewModel
    
    @State private var content = ""
    @State private var selectedEmotion: Emotion = .neutral
    @State private var selectedCategory: Category = .personal
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("생kslaus아각")) {
                    TextEditor(text: $content)
                        .frame(height: 100)
                }
                
                Section(header: Text("감정")) {
                    Picker("감정 선택", selection: $selectedEmotion) {
                        ForEach(Emotion.allCases, id: \.self) { emotion in
                            Text(emotion.rawValue).tag(emotion)
                        }
                    }
                }
                
                Section(header: Text("카테고리")) {
                    Picker("카테고리 선택", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }
                
                Section(header: Text("태그")) {
                    HStack {
                        TextField("새 태그", text: $newTag)
                        Button("추가") {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                    }
                    
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                    }
                    .onDelete { indexSet in
                        tags.remove(atOffsets: indexSet)
                    }
                }
            }
            .navigationTitle("새로운 생각")
            .navigationBarItems(
                leading: Button("취소") {
                    dismiss()
                },
                trailing: Button("저장") {
                    saveThought()
                }
                .disabled(content.isEmpty)
            )
        }
    }
    
    private func saveThought() {
        let thought = Thought(
            content: content,
            emotion: selectedEmotion,
            category: selectedCategory,
            tags: tags
        )
        
        viewModel.addThought(thought)
        dismiss()
        
        // 전면 광고 표시
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            AdManager.shared.showInterstitial(from: rootViewController)
        }
    }
} 