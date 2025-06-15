import SwiftUI

struct ThoughtDetailView: View {
    let thought: Thought
    @Environment(\.dismiss) private var dismiss
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
                        HStack(spacing: 8) {
                            if isReframing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                                Text("리프레이밍 중...")
                                    .fontWeight(.medium)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title3)
                                Text(thought.reframedContent == nil ? "리프레이밍하기" : "다시 리프레이밍하기")
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
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
                        .cornerRadius(12)
                        .opacity(isReframing ? 0.8 : 1.0)
                    }
                    .disabled(isReframing)
                    
                    // 생성 날짜
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
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

struct ThoughtDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ThoughtDetailView(thought: Thought(content: "예시 생각입니다."))
            .environmentObject(ThoughtViewModel())
    }
} 