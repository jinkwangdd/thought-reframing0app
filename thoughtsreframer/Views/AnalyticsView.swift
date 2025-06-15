import SwiftUI

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
                            value: String(format: "%.1f", thoughtViewModel.getAverageMood()),
                            icon: "heart.fill",
                            color: .red
                        )
                    }
                    
                    // 감정 분포
                    VStack(alignment: .leading, spacing: 12) {
                        Text("감정 분포")
                            .font(.headline)
                        
                        let emotionCounts = thoughtViewModel.getEmotionCounts()
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
                        
                        let categoryCounts = thoughtViewModel.getCategoryCounts()
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