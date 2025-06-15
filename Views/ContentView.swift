import SwiftUI
import GoogleMobileAds

struct ContentView: View {
    @StateObject private var viewModel = ThoughtViewModel()
    @State private var showingNewThoughtSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(viewModel.thoughts) { thought in
                        ThoughtCardView(thought: thought)
                    }
                    .onDelete { indexSet in
                        indexSet.forEach { index in
                            viewModel.deleteThought(viewModel.thoughts[index])
                        }
                    }
                }
                
                // Banner Ad
                BannerAdView()
                    .frame(height: 50)
            }
            .navigationTitle("생각 리프레이밍")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingNewThoughtSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewThoughtSheet) {
                NewThoughtView(viewModel: viewModel)
            }
        }
    }
}

struct ThoughtCardView: View {
    let thought: Thought
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(thought.content)
                .font(.body)
            
            HStack {
                Text(thought.emotion.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                
                Text(thought.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if let reframedContent = thought.reframedContent {
                Text(reframedContent)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        return AdManager.shared.createBannerView()
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 