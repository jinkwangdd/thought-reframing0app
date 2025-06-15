import Foundation
import SwiftUI

@MainActor
class ThoughtViewModel: ObservableObject {
    @Published var thoughts: [Thought] = []
    @Published var currentStreak: Int = 0
    @Published var isLoading = false
    @Published var error: Error?
    
    private let thoughtService: ThoughtService
    
    init(thoughtService: ThoughtService = ThoughtService()) {
        self.thoughtService = thoughtService
        loadThoughts()
    }
    
    func addThought(_ thought: Thought) {
        thoughts.append(thought)
        saveThoughts()
        updateStreak()
    }
    
    func deleteThought(_ thought: Thought) {
        thoughts.removeAll { $0.id == thought.id }
        saveThoughts()
    }
    
    func updateThought(_ thought: Thought) {
        if let index = thoughts.firstIndex(where: { $0.id == thought.id }) {
            thoughts[index] = thought
            saveThoughts()
        }
    }
    
    private func loadThoughts() {
        isLoading = true
        Task {
            do {
                thoughts = try await thoughtService.loadThoughts()
                updateStreak()
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    private func saveThoughts() {
        Task {
            do {
                try await thoughtService.saveThoughts(thoughts)
            } catch {
                self.error = error
            }
        }
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let hasThoughtForDate = thoughts.contains { thought in
                calendar.isDate(thought.createdAt, inSameDayAs: currentDate)
            }
            
            if hasThoughtForDate {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        currentStreak = streak
    }
} 